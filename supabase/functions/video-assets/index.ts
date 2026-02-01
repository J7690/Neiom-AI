// Supabase Edge Function: video-assets
// CRUD helpers for public.video_assets_library (real video rushes metadata)

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

  const action: string | null =
    typeof body?.action === "string" && body.action.trim().length > 0 ? body.action.trim() : null;

  if (!action) {
    return new Response(JSON.stringify({ error: "Missing action" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    if (action === "create_asset") {
      const storagePath: string | undefined =
        typeof body?.storagePath === "string" && body.storagePath.trim().length > 0
          ? body.storagePath.trim()
          : undefined;
      if (!storagePath) {
        return new Response(JSON.stringify({ error: "Missing storagePath" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const name = typeof body?.name === "string" && body.name.trim().length > 0
        ? body.name.trim()
        : null;
      const description = typeof body?.description === "string" && body.description.trim().length > 0
        ? body.description.trim()
        : null;
      const location = typeof body?.location === "string" && body.location.trim().length > 0
        ? body.location.trim()
        : null;
      const tags = Array.isArray(body?.tags) ? body.tags : [];
      const shotType = typeof body?.shotType === "string" && body.shotType.trim().length > 0
        ? body.shotType.trim()
        : null;
      const durationSeconds = typeof body?.durationSeconds === "number" && Number.isFinite(body.durationSeconds)
        ? body.durationSeconds
        : null;
      const resolutionWidth = typeof body?.resolutionWidth === "number" && Number.isFinite(body.resolutionWidth)
        ? body.resolutionWidth
        : null;
      const resolutionHeight = typeof body?.resolutionHeight === "number" && Number.isFinite(body.resolutionHeight)
        ? body.resolutionHeight
        : null;
      const frameRate = typeof body?.frameRate === "number" && Number.isFinite(body.frameRate)
        ? body.frameRate
        : null;
      const lighting = typeof body?.lighting === "string" && body.lighting.trim().length > 0
        ? body.lighting.trim()
        : null;
      const sourceType = typeof body?.sourceType === "string" && body.sourceType.trim().length > 0
        ? body.sourceType.trim()
        : null;
      const createdBy = typeof body?.createdBy === "string" && body.createdBy.trim().length > 0
        ? body.createdBy.trim()
        : null;

      const insertPayload: Record<string, unknown> = {
        storage_path: storagePath,
        name,
        description,
        location,
        tags,
        shot_type: shotType,
        duration_seconds: durationSeconds,
        resolution_width: resolutionWidth,
        resolution_height: resolutionHeight,
        frame_rate: frameRate,
        lighting,
        source_type: sourceType,
        created_by: createdBy,
      };

      const { data, error } = await supabase
        .from("video_assets_library")
        .insert(insertPayload)
        .select("*")
        .single();

      if (error) {
        console.error("Error inserting video asset", error);
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ asset: data }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "list_assets") {
      const location: string | null =
        typeof body?.location === "string" && body.location.trim().length > 0
          ? body.location.trim()
          : null;
      const shotType: string | null =
        typeof body?.shotType === "string" && body.shotType.trim().length > 0
          ? body.shotType.trim()
          : null;

      let query = supabase
        .from("video_assets_library")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(100);

      if (location) {
        query = query.eq("location", location);
      }
      if (shotType) {
        query = query.eq("shot_type", shotType);
      }

      const { data, error } = await query;

      if (error) {
        console.error("Error listing video assets", error);
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ assets: data ?? [] }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in video-assets", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
