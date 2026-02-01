import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function pickIntent(text: string): string {
  const t = text.toLowerCase();
  if (/(admission|inscription)/.test(t)) return "admission_inscription";
  if (/(tarif|prix|frais|paiement)/.test(t)) return "tarifs_paiement";
  if (/(orientation|formation|programme|filière|parcours)/.test(t)) return "orientation_academique";
  if (/(plainte|réclamation|remboursement|mécontent|insatisfait)/.test(t)) return "reclamation";
  if (/(spam|pub)/.test(t)) return "spam";
  return "demande_information";
}

function pickSentiment(text: string): "positive" | "neutral" | "negative" {
  const t = text.toLowerCase();
  if (/(merci|super|parfait|génial|satisfait)/.test(t)) return "positive";
  if (/(pas content|mécontent|insatisfait|nul|horrible|scandale)/.test(t)) return "negative";
  return "neutral";
}

serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { "Content-Type": "application/json" } });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openrouterApiKey = Deno.env.get("OPENROUTER_API_KEY");
  const openrouterBaseUrl = Deno.env.get("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1/chat/completions";
  const httpReferer = Deno.env.get("OPENROUTER_HTTP_REFERER") ?? "https://nexiom-ai-studio.com";
  const openrouterTitle = Deno.env.get("OPENROUTER_TITLE") ?? "Nexiom AI Studio";
  const defaultChatModel = Deno.env.get("NEXIOM_DEFAULT_CHAT_MODEL") ?? "openai/gpt-4o-mini";

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return new Response(JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }

  let body: any;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  const messageId = typeof body?.messageId === "string" ? body.messageId : undefined;
  const overrideText = typeof body?.text === "string" ? body.text : undefined;

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, { global: { fetch } });

  // Orchestration IA : modèle d'analyse + flag d'activation OpenRouter
  let analysisModel = defaultChatModel;
  let openrouterEnabled = true;
  if (openrouterApiKey) {
    try {
      const { data: settingsData } = await supabase.rpc("get_ai_orchestration_settings");
      if (settingsData) {
        const anySettings = settingsData as any;
        if (typeof anySettings.openrouter_enabled === "boolean") {
          openrouterEnabled = anySettings.openrouter_enabled as boolean;
        }
        const configuredModel =
          typeof anySettings.text_model_analysis === "string" &&
          anySettings.text_model_analysis.trim().length > 0
            ? (anySettings.text_model_analysis as string).trim()
            : null;
        if (configuredModel) {
          analysisModel = configuredModel;
        }
      }
    } catch (settingsError) {
      console.error("get_ai_orchestration_settings error in analyze-message", settingsError);
    }
  }

  let text: string | undefined = overrideText;
  if (!text && messageId) {
    const { data: msg, error: msgErr } = await supabase
      .from("messages")
      .select("id, content_text")
      .eq("id", messageId)
      .maybeSingle();
    if (msgErr) {
      return new Response(JSON.stringify({ error: "Failed to load message" }), { status: 500, headers: { "Content-Type": "application/json" } });
    }
    text = msg?.content_text ?? undefined;
  }

  if (!text || text.trim().length === 0) {
    return new Response(JSON.stringify({ error: "Missing text" }), { status: 400, headers: { "Content-Type": "application/json" } });
  }

  let intent = pickIntent(text);
  let sentiment = pickSentiment(text);
  let confidence = 0.6;
  let needs_escalation = sentiment === "negative";

  if (openrouterApiKey && openrouterEnabled) {
    try {
      const system = "Tu analyses un message d'un prospect pour Academia/Nexiom. Réponds en JSON strict: {intent, sentiment, confidence, needs_escalation}. Intent parmi: demande_information, admission_inscription, orientation_academique, tarifs_paiement, reclamation, spam. Sentiment: positive|neutral|negative. Confidence: 0..1. needs_escalation: true/false.";
      const payload = { model: analysisModel, messages: [{ role: "system", content: system }, { role: "user", content: text }] };
      const resp = await fetch(openrouterBaseUrl, { method: "POST", headers: { "Authorization": `Bearer ${openrouterApiKey}`, "Content-Type": "application/json", "HTTP-Referer": httpReferer, "X-Title": openrouterTitle }, body: JSON.stringify(payload) });
      if (resp.ok) {
        const json = await resp.json();
        const msg = json?.choices?.[0]?.message;
        let content = typeof msg?.content === "string" ? msg.content : undefined;
        if (!content && Array.isArray(msg?.content)) {
          const txt = msg.content.find((p: any) => p?.type === "text");
          content = txt?.text;
        }
        if (content) {
          try {
            const parsed = JSON.parse(content);
            if (typeof parsed?.intent === "string") intent = parsed.intent;
            if (parsed?.sentiment === "positive" || parsed?.sentiment === "neutral" || parsed?.sentiment === "negative") sentiment = parsed.sentiment;
            if (typeof parsed?.confidence === "number") confidence = parsed.confidence;
            if (typeof parsed?.needs_escalation === "boolean") needs_escalation = parsed.needs_escalation;
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  let analysisId: string | undefined = undefined;
  if (messageId) {
    const { data: existing } = await supabase
      .from("message_analysis")
      .select("id")
      .eq("message_id", messageId)
      .maybeSingle();

    if (existing?.id) {
      const { data } = await supabase
        .from("message_analysis")
        .update({ intent, sentiment, confidence, needs_escalation, metadata: {} })
        .eq("id", existing.id)
        .select("id")
        .single();
      analysisId = data?.id;
    } else {
      const { data } = await supabase
        .from("message_analysis")
        .insert({ message_id: messageId, intent, sentiment, confidence, needs_escalation, metadata: {} } as any)
        .select("id")
        .single();
      analysisId = data?.id;
    }
  }

  try {
    if (messageId) {
      const { data: msgRow } = await supabase
        .from("messages")
        .select("id, conversation_id, contact_id, channel")
        .eq("id", messageId)
        .single();

      const conversationId: string | undefined = msgRow?.conversation_id ?? undefined;
      const contactId: string | undefined = msgRow?.contact_id ?? undefined;
      const channel: string | undefined = msgRow?.channel ?? undefined;

      if (contactId) {
        const nowIso = new Date().toISOString();
        const srcChannel = ["whatsapp","facebook","instagram","tiktok","youtube"].includes((channel ?? "").toLowerCase())
          ? (channel as string)
          : "other";

        const { data: existingLead } = await supabase
          .from("leads")
          .select("id, first_contact_at")
          .eq("contact_id", contactId)
          .eq("source_channel", srcChannel)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle();

        if (existingLead?.id) {
          await supabase
            .from("leads")
            .update({
              status: "contacted",
              last_contact_at: nowIso,
            })
            .eq("id", existingLead.id);
        } else {
          await supabase
            .from("leads")
            .insert({
              contact_id: contactId,
              source_channel: srcChannel,
              status: "new",
              first_contact_at: nowIso,
              last_contact_at: nowIso,
            } as any);
        }
      }

      if (needs_escalation && conversationId) {
        const { data: conv } = await supabase
          .from("conversations")
          .select("metadata")
          .eq("id", conversationId)
          .single();
        const currentMeta = (conv?.metadata && typeof conv.metadata === "object") ? conv.metadata : {};
        const newMeta = { ...currentMeta, needs_escalation: true } as Record<string, unknown>;
        await supabase
          .from("conversations")
          .update({ metadata: newMeta })
          .eq("id", conversationId);
      }
    }
  } catch (_) {}

  return new Response(JSON.stringify({ messageId: messageId ?? null, intent, sentiment, confidence, needs_escalation, analysisId: analysisId ?? null }), { status: 200, headers: { "Content-Type": "application/json" } });
});
