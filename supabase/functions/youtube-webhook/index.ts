import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request): Promise<Response> => {
  if (req.method === "GET") {
    const url = new URL(req.url);
    const challenge = url.searchParams.get("hub.challenge");
    if (challenge) return new Response(challenge, { status: 200 });
    return new Response("ok", { status: 200 });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { "Content-Type": "application/json" } });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return new Response(JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }

  const bodyText = await req.text();
  let payload: any;
  try { payload = JSON.parse(bodyText); } catch (_) { payload = { raw: bodyText }; }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, { global: { fetch } });

  try {
    const evt = payload?.id || payload?.event_id || crypto.randomUUID();
    const text = payload?.text || payload?.comment || payload?.message || undefined;
    await supabase.from("webhook_events").upsert({
      channel: "youtube",
      type: text ? "comment" : "message",
      event_id: String(evt),
      author_id: payload?.author_id ?? null,
      author_name: payload?.author_name ?? null,
      content: text ?? null,
      event_date: new Date().toISOString(),
      post_id: payload?.post_id ?? null,
      conversation_id: null,
      raw_payload: payload,
    }, { onConflict: "channel,event_id" as any });
  } catch (_) {}

  return new Response(JSON.stringify({ status: "ok" }), { status: 200, headers: { "Content-Type": "application/json" } });
});
