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

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, { global: { fetch } });

  try {
    const { data: posts } = await supabase
      .from("social_posts")
      .select("id, target_channels")
      .neq("status", "draft")
      .limit(50);

    const now = new Date().toISOString();
    for (const p of (posts ?? [])) {
      const channels: string[] = Array.isArray(p.target_channels) ? p.target_channels : [];
      for (const ch of channels) {
        await supabase.from("social_metrics").insert({
          post_id: p.id,
          channel: ch,
          impressions: null,
          views: null,
          likes: null,
          comments: null,
          shares: null,
          engagement_rate: null,
          fetched_at: now,
        } as any);
      }
    }
  } catch (_) {}

  return new Response(JSON.stringify({ status: "ok" }), { status: 200, headers: { "Content-Type": "application/json" } });
});
