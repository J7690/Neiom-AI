import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { "Content-Type": "application/json" } });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return new Response(JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }

  let body: any;
  try { body = await req.json(); } catch (_) { body = {}; }
  const postId = typeof body?.postId === "string" ? body.postId : undefined;
  if (!postId) {
    return new Response(JSON.stringify({ error: "Missing postId" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, { global: { fetch } });

  const { data: post, error: postErr } = await supabase
    .from("social_posts")
    .select("id, content_text, media_paths, target_channels, status")
    .eq("id", postId)
    .single();
  if (postErr || !post) {
    return new Response(JSON.stringify({ error: "Post not found" }), { status: 404, headers: { "Content-Type": "application/json" } });
  }

  try {
    await supabase.from("social_posts").update({ status: "publishing" }).eq("id", postId);

    const channels: string[] = Array.isArray(post.target_channels) ? post.target_channels : [];

    for (const ch of channels) {
      await supabase.from("publish_logs").insert({
        post_id: postId,
        channel: ch,
        status: "error",
        error_message: "Provider tokens not configured",
        provider_response: {},
      } as any);
    }

    await supabase.from("social_posts").update({ status: "failed" }).eq("id", postId);
  } catch (_) {}

  return new Response(JSON.stringify({ status: "ok" }), { status: 200, headers: { "Content-Type": "application/json" } });
});
