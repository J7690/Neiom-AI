// Edge Function: fb-schedules-runner
// Rôle: exécuter périodiquement run_facebook_schedules_once()
// pour publier les posts Facebook planifiés dont l'heure est passée.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { facebookPublishService } from "../facebook/services/facebook.publish.ts";
import { FACEBOOK_POST_TYPES } from "../facebook/config/facebook.ts";

serve(async () => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars");
    return new Response(
      JSON.stringify({ success: false, error: "Missing Supabase service configuration" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(supabaseUrl, serviceKey, { global: { fetch } });

  try {
    // 1) Récupérer le prochain job Facebook planifié arrivé à échéance
    const { data: jobs, error: jobError } = await supabase.rpc(
      "get_next_facebook_schedule_job",
    );

    if (jobError) {
      console.error("get_next_facebook_schedule_job error", jobError);
      return new Response(
        JSON.stringify({ success: false, error: jobError.message ?? "RPC error" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const job = (jobs as any[] | null)?.[0];
    if (!job) {
      // Aucun job à traiter pour l'instant
      return new Response(
        JSON.stringify({ success: true, processed: 0 }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    console.log("fb-schedules-runner: processing job", job);

    // Charger le content_job pour accéder aux métadonnées (dont media_generation)
    const { data: contentJob, error: contentJobError } = await supabase
      .from("content_jobs")
      .select("id, metadata")
      .eq("id", job.content_job_id)
      .maybeSingle();

    if (contentJobError) {
      console.error("Error loading content_job in fb-schedules-runner", contentJobError);
    }

    let overrideType: string | null = null;
    let overrideImageUrl: string | undefined;
    let overrideVideoUrl: string | undefined;

    try {
      const meta = (contentJob?.metadata ?? {}) as any;
      const mg = (meta.media_generation ?? {}) as any;
      const mgStatus = (mg.status ?? "none").toString();

      if (mgStatus === "ready" && Array.isArray(mg.assets) && mg.assets.length > 0) {
        // Chercher un asset compatible Facebook (par type et canal)
        const chosen = (mg.assets as any[]).find((a) => {
          const t = (a?.type ?? "").toString().toLowerCase();
          const ch = (a?.channel ?? "").toString().toLowerCase();
          return (t === "image" || t === "video") && (ch === "" || ch === "facebook");
        }) ?? (mg.assets as any[])[0];

        if (chosen && typeof chosen.url === "string" && chosen.url.trim().length > 0) {
          const t = (chosen.type ?? "").toString().toLowerCase();
          if (t === "image") {
            overrideType = FACEBOOK_POST_TYPES.IMAGE;
            overrideImageUrl = chosen.url.trim();
          } else if (t === "video") {
            overrideType = FACEBOOK_POST_TYPES.VIDEO;
            overrideVideoUrl = chosen.url.trim();
          }
        }
      }
    } catch (e) {
      console.error(
        "Error while extracting media_generation from content_job metadata in fb-schedules-runner",
        e,
      );
    }

    // 2) Charger le prepared_post associé
    const { data: prepared, error: preparedError } = await supabase
      .from("studio_facebook_prepared_posts")
      .select("id, final_message, media_url, media_type, hashtags")
      .eq("id", job.prepared_post_id)
      .maybeSingle();

    if (preparedError || !prepared) {
      console.error("Error loading prepared_post", preparedError);
      // Marquer le job comme archivé/failed pour éviter les boucles
      await supabase
        .from("content_jobs")
        .update({ status: "archived", updated_at: new Date().toISOString() })
        .eq("id", job.content_job_id);

      return new Response(
        JSON.stringify({ success: false, processed: 0, error: "prepared_post not found" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // 3) Construire le message final avec hashtags + signature Nexiom
    let finalMessage: string = (prepared.final_message ?? "").toString();
    const hashtags: string[] = Array.isArray(prepared.hashtags)
      ? (prepared.hashtags as string[])
      : [];

    if (hashtags.length > 0) {
      const tags = hashtags
        .map((h) => (h ?? "").toString().trim())
        .filter((h) => h.length > 0)
        .map((h) => (h.startsWith("#") ? h : `#${h}`));

      if (tags.length > 0) {
        const tagsStr = tags.join(" ");
        finalMessage = (finalMessage && finalMessage.length > 0)
          ? `${finalMessage} ${tagsStr}`
          : tagsStr;
      }
    }

    finalMessage = finalMessage.trim();
    finalMessage = `${finalMessage}\n\nPost réalisé par le studio Nexiom AI, développé par Nexiom Group.`;

    // 4) Déterminer le type de post et les URLs média
    let type = FACEBOOK_POST_TYPES.TEXT;
    let imageUrl: string | undefined;
    let videoUrl: string | undefined;

    const mediaType = (prepared.media_type ?? "text").toString().toLowerCase();
    const mediaUrl: string | null = prepared.media_url ?? null;

    // Priorité aux médias générés et stockés dans content_jobs.metadata.media_generation
    if (overrideType === FACEBOOK_POST_TYPES.IMAGE && overrideImageUrl) {
      type = FACEBOOK_POST_TYPES.IMAGE;
      imageUrl = overrideImageUrl;
    } else if (overrideType === FACEBOOK_POST_TYPES.VIDEO && overrideVideoUrl) {
      type = FACEBOOK_POST_TYPES.VIDEO;
      videoUrl = overrideVideoUrl;
    } else if (mediaType === FACEBOOK_POST_TYPES.IMAGE && mediaUrl) {
      // Fallback: média issu du prepared_post
      type = FACEBOOK_POST_TYPES.IMAGE;
      imageUrl = mediaUrl;
    } else if (mediaType === FACEBOOK_POST_TYPES.VIDEO && mediaUrl) {
      type = FACEBOOK_POST_TYPES.VIDEO;
      videoUrl = mediaUrl;
    }

    // 5) Publier via le même service que la publication directe (Edge Facebook)
    const publishResult = await facebookPublishService.publish({
      type,
      message: finalMessage,
      imageUrl,
      videoUrl,
      published: true,
    });

    if (publishResult.status !== "published" || !publishResult.postId) {
      console.error("Facebook publish failed for scheduled job", publishResult);

      await supabase
        .from("content_jobs")
        .update({ status: "archived", updated_at: new Date().toISOString() })
        .eq("id", job.content_job_id);

      return new Response(
        JSON.stringify({ success: false, processed: 0, error: publishResult.error ?? "publish failed" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // 6) Enregistrer la publication dans le pipeline SQL (prepared_post, reco, social_posts, outcomes)
    const { error: recordError } = await supabase.rpc(
      "record_facebook_publication_for_prepared_post",
      {
        p_prepared_post_id: job.prepared_post_id,
        p_facebook_post_id: publishResult.postId,
        p_facebook_url: publishResult.url ?? "",
      },
    );

    if (recordError) {
      console.error("record_facebook_publication_for_prepared_post error", recordError);
    }

    // 7) Marquer le content_job (et éventuellement le schedule) comme publié
    await supabase
      .from("content_jobs")
      .update({ status: "published", updated_at: new Date().toISOString() })
      .eq("id", job.content_job_id);

    if (job.schedule_id) {
      await supabase
        .from("social_schedules")
        .update({ status: "published" })
        .eq("id", job.schedule_id);
    }

    return new Response(
      JSON.stringify({ success: true, processed: 1 }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("Unexpected error in fb-schedules-runner", e);
    return new Response(
      JSON.stringify({ success: false, error: "Unexpected error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
