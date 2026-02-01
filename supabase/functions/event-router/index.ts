import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type NormalizeInput = {
  channel: string;
  type: "message" | "comment";
  eventId: string;
  authorId?: string | null;
  authorName?: string | null;
  content?: string | null;
  eventDate?: string | null; // ISO
};

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

  const input: NormalizeInput = {
    channel: String(body?.channel ?? "").toLowerCase(),
    type: (body?.type === "comment" ? "comment" : "message"),
    eventId: String(body?.eventId ?? body?.event_id ?? ""),
    authorId: body?.authorId ?? body?.author_id ?? null,
    authorName: body?.authorName ?? body?.author_name ?? null,
    content: body?.content ?? null,
    eventDate: body?.eventDate ?? null,
  };

  if (!input.channel || !input.eventId) {
    return new Response(JSON.stringify({ error: "Missing channel or eventId" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, { global: { fetch } });

  try {
    let contactId: string | undefined = undefined;

    if (input.authorId) {
      const { data: ch } = await supabase
        .from("contact_channels")
        .select("id, contact_id")
        .eq("channel", input.channel)
        .eq("external_id", input.authorId)
        .maybeSingle();

      if (ch?.contact_id) {
        contactId = ch.contact_id as string;
      } else {
        const { data: contact } = await supabase
          .from("contacts")
          .insert({
            full_name: input.authorName ?? null,
            metadata: {},
          } as any)
          .select("id")
          .single();
        if (contact?.id) {
          contactId = contact.id as string;
          await supabase
            .from("contact_channels")
            .insert({
              contact_id: contactId,
              channel: input.channel,
              external_id: input.authorId,
              display_name: input.authorName ?? null,
              metadata: {},
            } as any);
        }
      }
    }

    let conversationId: string | undefined = undefined;
    if (contactId) {
      const { data: existing } = await supabase
        .from("conversations")
        .select("id")
        .eq("contact_id", contactId)
        .eq("channel", input.channel)
        .eq("status", "open")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (existing?.id) {
        conversationId = existing.id as string;
      } else {
        const { data: created } = await supabase
          .from("conversations")
          .insert({
            contact_id: contactId,
            channel: input.channel,
            status: "open",
            last_message_at: input.eventDate ?? new Date().toISOString(),
          } as any)
          .select("id")
          .single();
        conversationId = created?.id as string | undefined;
      }
    }

    let messageId: string | undefined = undefined;
    if (conversationId) {
      const { data: msg } = await supabase
        .from("messages")
        .insert({
          conversation_id: conversationId,
          contact_id: contactId ?? null,
          channel: input.channel,
          direction: "inbound",
          message_type: "text",
          content_text: input.content ?? null,
          media_url: null,
          provider_message_id: input.eventId,
          sent_at: input.eventDate ?? new Date().toISOString(),
          metadata: {},
        } as any)
        .select("id")
        .single();
      messageId = msg?.id as string | undefined;

      await supabase
        .from("conversations")
        .update({ last_message_at: input.eventDate ?? new Date().toISOString() })
        .eq("id", conversationId);
    }

    return new Response(JSON.stringify({ conversationId: conversationId ?? null, messageId: messageId ?? null }), { status: 200, headers: { "Content-Type": "application/json" } });
  } catch (_) {
    return new Response(JSON.stringify({ error: "Unexpected error" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
