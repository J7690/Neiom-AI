// Supabase Edge Function: visual-documents
// CRUD for visual_projects, visual_documents and visual_document_versions

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

  const action: string | null = typeof body?.action === "string" && body.action.trim().length > 0
    ? body.action.trim()
    : null;

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
    if (action === "create_project") {
      const name: string | undefined =
        typeof body?.name === "string" && body.name.trim().length > 0 ? body.name.trim() : undefined;
      if (!name) {
        return new Response(JSON.stringify({ error: "Missing project name" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const ownerId = typeof body?.ownerId === "string" && body.ownerId.trim().length > 0
        ? body.ownerId.trim()
        : null;
      const tags = Array.isArray(body?.tags) ? body.tags : [];

      const { data, error } = await supabase
        .from("visual_projects")
        .insert({ name, owner_id: ownerId, tags })
        .select("*")
        .single();

      if (error) {
        console.error("Error inserting visual_project", error);
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ project: data }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "list_projects") {
      const { data, error } = await supabase
        .from("visual_projects")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) {
        console.error("Error listing visual_projects", error);
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ projects: data ?? [] }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "list_documents") {
      const projectId: string | null =
        typeof body?.projectId === "string" && body.projectId.trim().length > 0
          ? body.projectId.trim()
          : null;

      let query = supabase
        .from("visual_documents")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(50);

      if (projectId) {
        query = query.eq("project_id", projectId);
      }

      const { data, error } = await query;

      if (error) {
        console.error("Error listing visual_documents", error);
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ documents: data ?? [] }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "create_document") {
      const projectId: string | undefined =
        typeof body?.projectId === "string" && body.projectId.trim().length > 0
          ? body.projectId.trim()
          : undefined;
      if (!projectId) {
        return new Response(JSON.stringify({ error: "Missing projectId" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const title = typeof body?.title === "string" ? body.title : null;
      const width = typeof body?.width === "number" && Number.isFinite(body.width) ? body.width : null;
      const height = typeof body?.height === "number" && Number.isFinite(body.height) ? body.height : null;
      const dpi = typeof body?.dpi === "number" && Number.isFinite(body.dpi) ? body.dpi : null;
      const backgroundColor = typeof body?.backgroundColor === "string" ? body.backgroundColor : null;

      const { data: doc, error } = await supabase
        .from("visual_documents")
        .insert({
          project_id: projectId,
          title,
          width,
          height,
          dpi,
          background_color: backgroundColor,
        })
        .select("*")
        .single();

      if (error) {
        console.error("Error inserting visual_document", error);
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ document: doc }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "get_document") {
      const documentId: string | undefined =
        typeof body?.documentId === "string" && body.documentId.trim().length > 0
          ? body.documentId.trim()
          : undefined;
      if (!documentId) {
        return new Response(JSON.stringify({ error: "Missing documentId" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: document, error: docError } = await supabase
        .from("visual_documents")
        .select("*")
        .eq("id", documentId)
        .single();

      if (docError) {
        console.error("Error loading visual_document", docError);
        return new Response(JSON.stringify({ error: docError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: versions, error: verError } = await supabase
        .from("visual_document_versions")
        .select("*")
        .eq("document_id", documentId)
        .order("version_index", { ascending: false })
        .limit(1);

      if (verError) {
        console.error("Error loading visual_document_versions", verError);
        return new Response(JSON.stringify({ error: verError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const currentVersion = Array.isArray(versions) && versions.length > 0 ? versions[0] : null;

      return new Response(JSON.stringify({ document, version: currentVersion }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "save_version") {
      const documentId: string | undefined =
        typeof body?.documentId === "string" && body.documentId.trim().length > 0
          ? body.documentId.trim()
          : undefined;
      if (!documentId) {
        return new Response(JSON.stringify({ error: "Missing documentId" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const canvasState = body?.canvasState && typeof body.canvasState === "object"
        ? body.canvasState
        : {};
      const thumbnailAssetId = typeof body?.thumbnailAssetId === "string" &&
          body.thumbnailAssetId.trim().length > 0
        ? body.thumbnailAssetId.trim()
        : null;

      const { data: maxVersionRow, error: maxError } = await supabase
        .from("visual_document_versions")
        .select("version_index")
        .eq("document_id", documentId)
        .order("version_index", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (maxError && maxError.code !== "PGRST116") {
        console.error("Error reading max version_index", maxError);
        return new Response(JSON.stringify({ error: maxError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const nextIndex =
        (maxVersionRow && typeof maxVersionRow.version_index === "number"
          ? maxVersionRow.version_index
          : 0) + 1;

      // Mark all existing versions as not current
      const { error: clearError } = await supabase
        .from("visual_document_versions")
        .update({ is_current: false })
        .eq("document_id", documentId);

      if (clearError) {
        console.error("Error clearing current flags", clearError);
        return new Response(JSON.stringify({ error: clearError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const insertPayload: Record<string, unknown> = {
        document_id: documentId,
        version_index: nextIndex,
        is_current: true,
        canvas_state: canvasState,
      };
      if (thumbnailAssetId) {
        insertPayload.thumbnail_asset_id = thumbnailAssetId;
      }

      const { data: version, error: insertError } = await supabase
        .from("visual_document_versions")
        .insert(insertPayload)
        .select("*")
        .single();

      if (insertError) {
        console.error("Error inserting visual_document_version", insertError);
        return new Response(JSON.stringify({ error: insertError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ version }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "list_versions") {
      const documentId: string | undefined =
        typeof body?.documentId === "string" && body.documentId.trim().length > 0
          ? body.documentId.trim()
          : undefined;
      if (!documentId) {
        return new Response(JSON.stringify({ error: "Missing documentId" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data, error } = await supabase
        .from("visual_document_versions")
        .select("*")
        .eq("document_id", documentId)
        .order("version_index", { ascending: false });

      if (error) {
        console.error("Error listing visual_document_versions", error);
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ versions: data ?? [] }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "restore_version") {
      const versionId: string | undefined =
        typeof body?.versionId === "string" && body.versionId.trim().length > 0
          ? body.versionId.trim()
          : undefined;
      if (!versionId) {
        return new Response(JSON.stringify({ error: "Missing versionId" }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: versionRow, error: fetchError } = await supabase
        .from("visual_document_versions")
        .select("id, document_id")
        .eq("id", versionId)
        .single();

      if (fetchError || !versionRow) {
        console.error("Error loading visual_document_version", fetchError);
        return new Response(JSON.stringify({ error: fetchError?.message ?? "Version not found" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const documentId = versionRow.document_id as string;

      const { error: clearError } = await supabase
        .from("visual_document_versions")
        .update({ is_current: false })
        .eq("document_id", documentId);

      if (clearError) {
        console.error("Error clearing current flags before restore", clearError);
        return new Response(JSON.stringify({ error: clearError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: updatedVersion, error: updateError } = await supabase
        .from("visual_document_versions")
        .update({ is_current: true })
        .eq("id", versionId)
        .select("*")
        .single();

      if (updateError) {
        console.error("Error setting version as current", updateError);
        return new Response(JSON.stringify({ error: updateError.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({ version: updatedVersion }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in visual-documents", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
