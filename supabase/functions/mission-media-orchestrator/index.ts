import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type MediaOrchestratorRequest = {
  missionId?: string;
  channel?: string;
  mediaType?: "image" | "video" | "auto";
  limit?: number;
};

type ContentJobRow = {
  id: string;
  mission_id: string | null;
  status: string;
  channels: string[] | null;
  phase: string | null;
  metadata: Record<string, any> | null;
};

function buildMediaPromptFromJob(job: ContentJobRow, index: number): string {
  const meta = (job.metadata ?? {}) as any;
  const title: string =
    typeof meta.title === "string" && meta.title.trim().length > 0
      ? meta.title.trim()
      : "post marketing";
  const description: string =
    typeof meta.description === "string" && meta.description.trim().length > 0
      ? meta.description.trim()
      : "";
  const phase: string =
    typeof job.phase === "string" && job.phase.trim().length > 0
      ? job.phase.trim()
      : "nurture";

  const tone: string =
    typeof meta.tone === "string" && meta.tone.trim().length > 0
      ? meta.tone.trim()
      : "professionnel, pédagogique et rassurant";

  const audience: string =
    typeof meta.audience === "string" && meta.audience.trim().length > 0
      ? meta.audience.trim()
      : "étudiants et parents d'élèves";

  const topic: string =
    typeof meta.topic === "string" && meta.topic.trim().length > 0
      ? meta.topic.trim()
      : "offres de formation et accompagnement académique";

  const objective: string =
    typeof meta.objective === "string" && meta.objective.trim().length > 0
      ? meta.objective.trim()
      : "engagement";

  const base = `Crée une image carrée pour un post de mission marketing (${index + 1}).\n` +
    `Phase du tunnel: ${phase}.\n` +
    `Thématique principale: ${topic}.\n` +
    `Public cible: ${audience}.\n` +
    `Objectif: ${objective}.\n` +
    `Ton: ${tone}.`;

  if (description) {
    return (
      base +
      `\n\nDétail du post: ${description}.\n` +
      `L'image doit être claire, lisible sur mobile, sans texte trop long, et cohérente avec la charte Nexiom.`
    );
  }

  return (
    base +
    `\n\nL'image doit être claire, lisible sur mobile et cohérente avec la charte Nexiom.`
  );
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const functionsOrigin = new URL(supabaseUrl).origin.replace(
    ".supabase.co",
    ".functions.supabase.co",
  );

  let body: MediaOrchestratorRequest;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const missionId =
    typeof body?.missionId === "string" && body.missionId.trim().length > 0
      ? body.missionId.trim()
      : null;

  if (!missionId) {
    return new Response(JSON.stringify({ error: "missionId is required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const channel =
    typeof body?.channel === "string" && body.channel.trim().length > 0
      ? body.channel.trim().toLowerCase()
      : "facebook";

  const mediaType: "image" | "video" | "auto" =
    body?.mediaType === "image" || body?.mediaType === "video" || body?.mediaType === "auto"
      ? body.mediaType
      : "image";

  let limit: number =
    typeof body?.limit === "number" && Number.isFinite(body.limit)
      ? body.limit
      : 10;
  if (limit < 1) limit = 1;
  if (limit > 50) limit = 50;

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    // 1) Charger les content_jobs planifiés pour la mission, sans médias générés
    const { data: jobsData, error: jobsError } = await supabase
      .from("content_jobs")
      .select("id, mission_id, status, channels, phase, metadata")
      .eq("mission_id", missionId)
      .in("status", ["approved", "scheduled"])
      .limit(limit);

    if (jobsError) {
      console.error("mission-media-orchestrator: error loading content_jobs", jobsError);
      return new Response(
        JSON.stringify({ error: "Failed to load content_jobs", details: jobsError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const jobs = (jobsData ?? []) as ContentJobRow[];
    if (jobs.length === 0) {
      return new Response(
        JSON.stringify({
          missionId,
          channel,
          mediaType,
          totalCandidates: 0,
          generated: 0,
          results: [],
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const results: any[] = [];
    let generatedCount = 0;

    for (let i = 0; i < jobs.length; i++) {
      const job = jobs[i];
      const meta = (job.metadata ?? {}) as any;
      const mg = (meta.media_generation ?? {}) as any;
      const status: string = (mg.status ?? "none").toString();

      if (status === "ready") {
        results.push({
          content_job_id: job.id,
          skipped: true,
          reason: "media_already_ready",
        });
        continue;
      }

      const prompt = buildMediaPromptFromJob(job, i);

      const target: "image" | "video" =
        mediaType === "auto"
          ? "image" // pour l'instant : on privilégie l'image en auto
          : mediaType;

      let generationResponse: Response;
      if (target === "video") {
        generationResponse = await fetch(`${functionsOrigin}/generate-video`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            apikey: supabaseServiceRoleKey,
            Authorization: `Bearer ${supabaseServiceRoleKey}`,
          },
          body: JSON.stringify({ prompt, useBrandLogo: true }),
        });
      } else {
        generationResponse = await fetch(`${functionsOrigin}/generate-image`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            apikey: supabaseServiceRoleKey,
            Authorization: `Bearer ${supabaseServiceRoleKey}`,
          },
          body: JSON.stringify({ prompt, useBrandLogo: true }),
        });
      }

      if (!generationResponse.ok) {
        let errorText: string | undefined;
        try {
          errorText = await generationResponse.text();
        } catch (_) {
          errorText = undefined;
        }

        console.error("mission-media-orchestrator: generation failed", {
          jobId: job.id,
          status: generationResponse.status,
          errorText,
        });

        const newMeta = {
          ...meta,
          media_generation: {
            ...(mg ?? {}),
            status: "error",
            last_error: errorText ?? `HTTP ${generationResponse.status}`,
            last_run_at: new Date().toISOString(),
          },
        };

        await supabase
          .from("content_jobs")
          .update({ metadata: newMeta })
          .eq("id", job.id);

        results.push({
          content_job_id: job.id,
          success: false,
          error: errorText ?? `HTTP ${generationResponse.status}`,
        });
        continue;
      }

      let payload: any = null;
      try {
        payload = await generationResponse.json();
      } catch (e) {
        console.error("mission-media-orchestrator: failed to parse generation JSON", e);
      }

      const resultUrl: string | null =
        typeof payload?.resultUrl === "string" && payload.resultUrl.trim().length > 0
          ? payload.resultUrl.trim()
          : typeof payload?.publicUrl === "string" && payload.publicUrl.trim().length > 0
          ? payload.publicUrl.trim()
          : null;

      if (!resultUrl) {
        const newMeta = {
          ...meta,
          media_generation: {
            ...(mg ?? {}),
            status: "error",
            last_error: "no_result_url_from_generation",
            last_run_at: new Date().toISOString(),
          },
        };

        await supabase
          .from("content_jobs")
          .update({ metadata: newMeta })
          .eq("id", job.id);

        results.push({
          content_job_id: job.id,
          success: false,
          error: "no_result_url_from_generation",
        });
        continue;
      }

      const asset = {
        type: target,
        channel,
        url: resultUrl,
      };

      const existingAssets: any[] = Array.isArray(mg.assets) ? mg.assets : [];
      const newAssets = [...existingAssets, asset];

      const newMeta = {
        ...meta,
        media_generation: {
          ...(mg ?? {}),
          status: "ready",
          assets: newAssets,
          last_run_at: new Date().toISOString(),
        },
      };

      const { error: updateError } = await supabase
        .from("content_jobs")
        .update({ metadata: newMeta })
        .eq("id", job.id);

      if (updateError) {
        console.error("mission-media-orchestrator: failed to update content_job metadata", {
          jobId: job.id,
          error: updateError,
        });

        results.push({
          content_job_id: job.id,
          success: false,
          error: updateError.message ?? "metadata_update_failed",
        });
        continue;
      }

      generatedCount += 1;
      results.push({
        content_job_id: job.id,
        success: true,
        asset,
      });
    }

    const responseBody = {
      missionId,
      channel,
      mediaType,
      totalCandidates: jobs.length,
      generated: generatedCount,
      results,
    };

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in mission-media-orchestrator", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
