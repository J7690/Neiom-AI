// Supabase Edge Function: ai-reply
// Provides a text reply via OpenRouter with a locked system prompt enforcing Nexiom's golden rule

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

  const openrouterApiKey = Deno.env.get("OPENROUTER_API_KEY");
  const openrouterBaseUrl =
    Deno.env.get("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1/chat/completions";
  const httpReferer = Deno.env.get("OPENROUTER_HTTP_REFERER") ?? "https://nexiom-ai-studio.com";
  const openrouterTitle = Deno.env.get("OPENROUTER_TITLE") ?? "Nexiom AI Studio";
  const defaultChatModel =
    Deno.env.get("NEXIOM_DEFAULT_CHAT_MODEL") ?? "openai/gpt-4o-mini";
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!openrouterApiKey) {
    return new Response(
      JSON.stringify({ error: "Missing OPENROUTER_API_KEY" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  let body: any;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const userMessage: string | undefined = typeof body?.prompt === "string"
    ? body.prompt
    : undefined;
  const brandRules: unknown[] = Array.isArray(body?.brandRules) ? body.brandRules : [];
  const knowledgeHits: unknown[] = Array.isArray(body?.knowledgeHits) ? body.knowledgeHits : [];
  const locale: string | undefined = typeof body?.locale === "string" ? body.locale : undefined;
  const channel: string | undefined = typeof body?.channel === "string"
    ? body.channel
    : undefined;

  if (!userMessage || userMessage.trim().length === 0) {
    return new Response(JSON.stringify({ error: "Missing prompt" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Orchestration IA : modèle assistant + flag d'activation OpenRouter
  let assistantModel = defaultChatModel;
  let openrouterEnabled = true;
  if (supabaseUrl && supabaseServiceRoleKey) {
    try {
      const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
        global: { fetch },
      });
      const { data: settingsData } = await supabase.rpc("get_ai_orchestration_settings");
      if (settingsData) {
        const anySettings = settingsData as any;
        if (typeof anySettings.openrouter_enabled === "boolean") {
          openrouterEnabled = anySettings.openrouter_enabled as boolean;
        }
        const configuredModel =
          typeof anySettings.text_model_assistant === "string" &&
          anySettings.text_model_assistant.trim().length > 0
            ? (anySettings.text_model_assistant as string).trim()
            : null;
        if (configuredModel) {
          assistantModel = configuredModel;
        }
      }
    } catch (settingsError) {
      console.error("get_ai_orchestration_settings error in ai-reply", settingsError);
    }
  }

  if (!openrouterEnabled) {
    return new Response(
      JSON.stringify({ error: "OpenRouter disabled in ai_orchestration_settings" }),
      { status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // Locked system prompt implementing the golden rule
  const systemPrompt =
    "Tu es l'assistant IA officiel de Nexiom/Academia. " +
    "TU DOIS STRICTEMENT RESPECTER LA RÈGLE D'OR SUIVANTE : " +
    "NE JAMAIS RÉPONDRE EN INVENTANT DES INFORMATIONS. " +
    "Tu reçois en entrée: (1) un message utilisateur, (2) des règles de marque, (3) une liste de `knowledge_hits` validés par la base de connaissances. " +
    "TU N'AS LE DROIT DE FORMULER UNE RÉPONSE QUE SI LES `knowledge_hits` FOURNISSENT CLAIREMENT LA RÉPONSE. " +
    "Si les `knowledge_hits` sont vides, peu fiables ou hors sujet, tu dois répondre UNIQUEMENT par le jeton exact `__NEEDS_HUMAN__` sans rien ajouter. " +
    "Sinon, tu rédiges une réponse courte, claire et bienveillante en français pour l'utilisateur final, en respectant les règles de marque, et en t'appuyant UNIQUEMENT sur les `knowledge_hits` fournis. " +
    "Tu n'expliques jamais ta politique interne, tu ne mentionnes pas les `knowledge_hits` ni les identifiants, tu ne parles pas de Nexiom AI en tant que système. " +
    "Ta sortie doit être UNIQUEMENT le texte à envoyer à l'utilisateur final (ou le jeton `__NEEDS_HUMAN__`).";

  const contextPayload = {
    locale,
    channel,
    brand_rules: brandRules,
    knowledge_hits: knowledgeHits,
    user_message: userMessage,
  };

  const messages: any[] = [
    { role: "system", content: systemPrompt },
    {
      role: "user",
      content:
        "Voici le contexte JSON pour construire ta réponse en respectant la règle d'or :\n" +
        JSON.stringify(contextPayload, null, 2),
    },
  ];

  const openrouterPayload = {
    model: assistantModel,
    messages,
    max_tokens: 512,
  };

  try {
    const resp = await fetch(openrouterBaseUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openrouterApiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": httpReferer,
        "X-Title": openrouterTitle,
      },
      body: JSON.stringify(openrouterPayload),
    });

    if (!resp.ok) {
      const text = await resp.text();
      return new Response(
        JSON.stringify({
          error: "OpenRouter request failed",
          providerStatus: resp.status,
          providerBody: text,
          modelUsed: assistantModel,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const json = await resp.json();
    const choice = json?.choices?.[0];
    const msg = choice?.message ?? {};
    let replyText: string | undefined = typeof msg?.content === "string" ? msg.content : undefined;

    if (!replyText && Array.isArray(msg?.content)) {
      const textPart = msg.content.find((p: any) => p?.type === "text");
      if (textPart && typeof textPart.text === "string") {
        replyText = textPart.text;
      }
    }

    if (!replyText) {
      return new Response(
        JSON.stringify({ error: "No text content in OpenRouter response" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        replyText,
        model: json?.model ?? defaultChatModel,
        usage: json?.usage ?? null,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    console.error("Unexpected error in ai-reply", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
