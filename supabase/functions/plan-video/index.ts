// Supabase Edge Function: plan-video
// Creates a structured video brief row in public.video_briefs to orchestrate video generation

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

  const name: string | null =
    typeof body?.name === "string" && body.name.trim().length > 0 ? body.name.trim() : null;
  const description: string | null =
    typeof body?.description === "string" && body.description.trim().length > 0
      ? body.description.trim()
      : null;
  const rawPrompt: string | null =
    typeof body?.rawPrompt === "string" && body.rawPrompt.trim().length > 0
      ? body.rawPrompt.trim()
      : null;
  const createdBy: string | null =
    typeof body?.createdBy === "string" && body.createdBy.trim().length > 0
      ? body.createdBy.trim()
      : null;

  const normalizeJsonField = (value: unknown): any | null => {
    if (value && typeof value === "object") {
      return value;
    }
    return null;
  };

  const businessContext = normalizeJsonField(body?.businessContext);
  const localizationContext = normalizeJsonField(body?.localizationContext);
  const visualContext = normalizeJsonField(body?.visualContext);
  const charactersContext = normalizeJsonField(body?.charactersContext);
  const cameraStyle = normalizeJsonField(body?.cameraStyle);
  const lightingStyle = normalizeJsonField(body?.lightingStyle);
  const qualityProfile = normalizeJsonField(body?.qualityProfile);
  const constraints = normalizeJsonField(body?.constraints);

  if (!rawPrompt && !visualContext && !businessContext && !localizationContext) {
    return new Response(JSON.stringify({ error: "Missing minimum brief content" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    const insertPayload: Record<string, unknown> = {
      name,
      description,
      business_context: businessContext,
      localization_context: localizationContext,
      visual_context: visualContext,
      characters_context: charactersContext,
      camera_style: cameraStyle,
      lighting_style: lightingStyle,
      quality_profile: qualityProfile,
      constraints,
      raw_prompt: rawPrompt,
      created_by: createdBy,
    };

    const { data, error } = await supabase
      .from("video_briefs")
      .insert(insertPayload)
      .select("*")
      .single();

    if (error) {
      console.error("Error inserting video_brief", error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ brief: data }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in plan-video", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
