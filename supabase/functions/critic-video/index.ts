// Supabase Edge Function: critic-video
// Heuristic video quality critic that scores a generation_jobs row

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "*",
};

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
    return new Response(JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: any;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const jobId: string | undefined =
    typeof body?.jobId === "string" && body.jobId.trim().length > 0 ? body.jobId.trim() : undefined;

  if (!jobId) {
    return new Response(JSON.stringify({ error: "Missing jobId" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    const { data: job, error: jobError } = await supabase
      .from("generation_jobs")
      .select("id, type, prompt, model, duration_seconds, reference_media_path, status, result_url, error_message, provider, quality_tier, provider_metadata, video_brief_id")
      .eq("id", jobId)
      .maybeSingle();

    if (jobError) {
      console.error("Error loading generation_job in critic-video", jobError);
      return new Response(JSON.stringify({ error: jobError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!job) {
      return new Response(JSON.stringify({ error: "Job not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (job.type !== "video") {
      return new Response(JSON.stringify({ error: "critic-video only supports type=video" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const providerMetadata = (job.provider_metadata ?? {}) as Record<string, unknown>;

    // Heuristic scoring: purely basée sur les métadonnées (pas de vision pour l'instant)
    let score = 0;
    const details: Record<string, unknown> = {};

    if (job.result_url) {
      score += 0.5;
      details["has_result_url"] = true;
    } else {
      details["has_result_url"] = false;
    }

    if (job.quality_tier === "ultra_realistic") {
      score += 0.2;
      details["quality_tier_bonus"] = 0.2;
    } else if (job.quality_tier === "cinematic") {
      score += 0.1;
      details["quality_tier_bonus"] = 0.1;
    }

    if (job.reference_media_path) {
      score += 0.1;
      details["reference_media_bonus"] = 0.1;
    }

    if (job.video_brief_id) {
      score += 0.1;
      details["video_brief_bonus"] = 0.1;
    }

    if (providerMetadata["face_reference_path"]) {
      score += 0.05;
      details["face_reference_bonus"] = 0.05;
    }

    if (providerMetadata["storyboard"] || providerMetadata["shot_descriptions"]) {
      score += 0.05;
      details["storyboard_bonus"] = 0.05;
    }

    if (score > 1) score = 1;

    const qualityScore = score;

    const criticReportLines: string[] = [];
    criticReportLines.push(`Critic score: ${(qualityScore * 100).toFixed(0)} / 100.`);
    criticReportLines.push(
      "This score is heuristic and based on metadata: presence of a result URL, quality tier, reference media, video brief link and storyboard information.",
    );
    if (!job.result_url) {
      criticReportLines.push("No result_url set on the job; generation may have failed or not completed.");
    }
    if (!job.reference_media_path) {
      criticReportLines.push("No reference media path; consider providing a real photo or video to improve realism.");
    }
    if (!job.video_brief_id) {
      criticReportLines.push("No video_brief_id; consider creating a structured VideoBrief for better control.");
    }

    const criticReport = criticReportLines.join("\n");

    const { error: updateError } = await supabase
      .from("generation_jobs")
      .update({
        quality_score: qualityScore,
        critic_report: criticReport,
        critic_metadata: details,
      })
      .eq("id", jobId);

    if (updateError) {
      console.error("Error updating generation_job with critic fields", updateError);
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ qualityScore, criticReport, criticMetadata: details }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in critic-video", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
