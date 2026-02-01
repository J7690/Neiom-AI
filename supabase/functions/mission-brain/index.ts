// Supabase Edge Function: mission-brain
// Propose des missions marketing (par canal / métrique) via OpenRouter
// et les enregistre dans studio_marketing_missions.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
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
  const openrouterApiKey = Deno.env.get("OPENROUTER_API_KEY");
  const openrouterBaseUrl =
    Deno.env.get("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1/chat/completions";
  const httpReferer = Deno.env.get("OPENROUTER_HTTP_REFERER") ?? "https://nexiom-ai-studio.com";
  const openrouterTitle = Deno.env.get("OPENROUTER_TITLE") ?? "Nexiom AI Studio";
  const defaultChatModel =
    Deno.env.get("NEXIOM_DEFAULT_CHAT_MODEL") ?? "openai/gpt-4o-mini";

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

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
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const requestedObjective: string | undefined =
    typeof body?.objective === "string" && body.objective.trim().length > 0
      ? body.objective.trim()
      : undefined;
  const locale: string =
    typeof body?.locale === "string" && body.locale.trim().length > 0
      ? body.locale.trim()
      : "fr";
  const marketCode: string =
    typeof body?.market === "string" && body.market.trim().length > 0
      ? body.market.trim()
      : "bf_ouagadougou";
  const audienceSegment: string =
    typeof body?.audienceSegment === "string" && body.audienceSegment.trim().length > 0
      ? body.audienceSegment.trim()
      : "students";
  const activityRef: string | undefined =
    typeof body?.activityRef === "string" && body.activityRef.trim().length > 0
      ? body.activityRef.trim()
      : undefined;
  const preferredChannels: string[] | undefined =
    Array.isArray(body?.preferredChannels)
      ? body.preferredChannels.map((c: unknown) => String(c)).filter((c: string) => c.trim().length > 0)
      : undefined;
  let maxMissions: number =
    typeof body?.maxMissions === "number" && Number.isFinite(body.maxMissions)
      ? body.maxMissions
      : 3;
  if (maxMissions < 1) maxMissions = 1;
  if (maxMissions > 20) maxMissions = 20;

  const allowedObjectives = ["notoriety", "engagement", "conversion"] as const;
  const defaultObjective = "engagement" as const;

  const baseObjective =
    requestedObjective && allowedObjectives.includes(requestedObjective as any)
      ? (requestedObjective as (typeof allowedObjectives)[number])
      : defaultObjective;

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    // Gouvernance IA + modèle texte d'analyse
    const { data: settingsData } = await supabase.rpc(
      "get_ai_orchestration_settings",
    );

    let openrouterEnabled = true;
    let analysisModel = defaultChatModel;

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

    if (!openrouterEnabled) {
      return new Response(
        JSON.stringify({
          source: "sql_only_openrouter_disabled",
          missions: [],
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Charger contexte : objectifs, missions existantes, performances Facebook, brand_context
    const [objectivesRes, missionsRes, fbOverviewRes, objectiveSummaryRes, brandContextRes] =
      await Promise.all([
        supabase
          .from("studio_marketing_objectives")
          .select(
            "id, objective, target_value, current_value, unit, horizon, status, target_date, dimension, primary_metric, default_channels, priority",
          )
          .eq("status", "active"),
        supabase
          .from("studio_marketing_missions")
          .select(
            "id, objective_id, channel, metric, activity_ref, target_value, current_baseline, status, start_date, end_date, created_at",
          )
          .order("created_at", { ascending: false })
          .limit(20),
        supabase.rpc("get_facebook_post_performance_overview", { p_days: 30 }),
        supabase.rpc("get_objective_performance_summary", { p_days: 30 }),
        supabase
          .from("studio_brand_context")
          .select("content")
          .eq("brand_key", "nexium_group")
          .eq("locale", locale)
          .limit(1),
      ]);

    const objectives = (objectivesRes.data ?? []) as any[];
    const existingMissions = (missionsRes.data ?? []) as any[];
    const facebookOverview = (fbOverviewRes.data ?? []) as any[];
    const objectivePerformance = (objectiveSummaryRes.data ?? []) as any[];
    const brandContextRow =
      ((brandContextRes.data as any[] | null | undefined) ?? [])[0] as
        | { content?: unknown }
        | undefined;
    const brandContext = (brandContextRow?.content as Record<string, unknown> | null | undefined) ?? null;

    const contextPayload = {
      locale,
      market: marketCode,
      audience_segment: audienceSegment,
      objective: baseObjective,
      activity_ref: activityRef,
      preferred_channels: preferredChannels,
      max_missions: maxMissions,
      objectives,
      existing_missions: existingMissions,
      facebook_performance_overview: facebookOverview,
      objective_performance_summary: objectivePerformance,
      brand_context: brandContext,
      now: new Date().toISOString(),
    };

    const systemPrompt =
      "Tu es 'mission-brain', l'assistant de planification marketing pour Nexium Group et sa plateforme Academia en Afrique de l'Ouest. " +
      "Ta mission est de proposer des missions marketing opérationnelles (par canal et par métrique) pour servir les objectifs marketing de Nexium Group. " +
      "Tu reçois un JSON de contexte contenant : les objectifs marketing structurés, les missions existantes, les performances Facebook agrégées, et le brand_context décrivant Nexium Group, son courtage académique et sa mission prioritaire de notoriété et de communauté. " +
      "Le champ 'objective' contient l'objectif prioritaire (notoriety|engagement|conversion). Le champ 'activity_ref' peut décrire une activité spécifique à promouvoir (ex. cours d'appui en mathématiques pour Terminale) ou être nul. " +
      "Tu dois proposer des missions qui tiennent compte du statut actuel de la page Facebook (performances récentes, croissance, engagement) et, si pertinent, suggérer aussi des missions pour TikTok et Instagram en les alignant sur les mêmes objectifs. " +
      "Chaque mission doit être structurée pour aider à augmenter la visibilité, les abonnés, les vues ou les conversions, en fonction de l'objectif, et doit rester cohérente avec le rôle de Nexium Group comme courtier académique (réductions négociées, facilités de paiement, pas de bourses). " +
      "Tu dois répondre STRICTEMENT sous la forme d'un tableau JSON de missions, sans texte autour. Chaque mission doit respecter le schéma suivant :\n" +
      "[\n" +
      "  {\n" +
      "    \"objective\": \"notoriety|engagement|conversion\",\n" +
      "    \"channel\": \"facebook|tiktok|instagram\",\n" +
      "    \"metric\": \"followers|views|reach|clicks|leads|conversions\",\n" +
      "    \"target_value\": nombre,\n" +
      "    \"current_baseline\": nombre (optionnel),\n" +
      "    \"unit\": \"count\" ou autre unité si pertinent,\n" +
      "    \"status\": \"planned\" (toujours),\n" +
      "    \"activity_ref\": \"texte décrivant l'activité ciblée ou le focus de la mission\"\n" +
      "  }, ...\n" +
      "]\n" +
      "Tu dois générer entre 1 et N missions (N est fourni dans le contexte via max_missions). N'inclus JAMAIS de commentaires en dehors du JSON. Le JSON doit être valide et directement parsable.";

    const userContent =
      "Voici le contexte JSON actuel pour construire tes missions (n'y ajoute rien, ne le modifie pas) :\n" +
      JSON.stringify(contextPayload, null, 2);

    const messages: any[] = [
      { role: "system", content: systemPrompt },
      { role: "user", content: userContent },
    ];

    const openrouterPayload = {
      model: analysisModel,
      messages,
      max_tokens: 2048,
    };

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
      console.error("OpenRouter error in mission-brain", {
        status: resp.status,
        bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
      });

      return new Response(
        JSON.stringify({
          error: "OpenRouter request failed in mission-brain",
          providerStatus: resp.status,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const json = await resp.json();
    const choice = json?.choices?.[0];
    const msg = choice?.message ?? {};

    let replyText: string | undefined =
      typeof msg?.content === "string" ? msg.content : undefined;

    if (!replyText && Array.isArray(msg?.content)) {
      const textPart = msg.content.find((p: any) => p?.type === "text");
      if (textPart && typeof textPart.text === "string") {
        replyText = textPart.text;
      }
    }

    if (!replyText) {
      throw new Error("No text content in OpenRouter response (mission-brain)");
    }

    let parsed: any;
    try {
      const trimmed = replyText.trim();
      parsed = JSON.parse(trimmed);
    } catch (e) {
      console.error("Failed to parse mission-brain JSON", e, replyText);
      return new Response(
        JSON.stringify({ error: "mission-brain JSON parse failed" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    let missions: any[] = [];
    if (Array.isArray(parsed)) {
      missions = parsed;
    } else if (Array.isArray(parsed?.missions)) {
      missions = parsed.missions;
    }

    if (!Array.isArray(missions) || missions.length === 0) {
      return new Response(
        JSON.stringify({ source: "mission_brain", missions: [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const allowedChannels = ["facebook", "tiktok", "instagram"];
    const allowedMetrics = ["followers", "views", "reach", "clicks", "leads", "conversions"];
    const allowedStatuses = ["planned", "active", "paused", "completed", "cancelled"];

    const objectiveMap = new Map<string, string>();
    for (const obj of objectives) {
      const key = typeof obj.objective === "string" ? obj.objective.toLowerCase() : "";
      if (key && typeof obj.id === "string") {
        objectiveMap.set(key, obj.id);
      }
    }

    const rowsToInsert = missions.slice(0, maxMissions).flatMap((m: any) => {
      const rawObjective: string =
        typeof m?.objective === "string" && m.objective.trim().length > 0
          ? m.objective.trim().toLowerCase()
          : baseObjective;
      const objectiveKey = allowedObjectives.includes(rawObjective as any)
        ? rawObjective
        : baseObjective;
      const objectiveId = objectiveMap.get(objectiveKey) ?? null;

      let channel: string =
        typeof m?.channel === "string" && m.channel.trim().length > 0
          ? m.channel.trim().toLowerCase()
          : "facebook";
      if (!allowedChannels.includes(channel)) channel = "facebook";

      let metric: string =
        typeof m?.metric === "string" && m.metric.trim().length > 0
          ? m.metric.trim().toLowerCase()
          : "followers";
      if (!allowedMetrics.includes(metric)) metric = "followers";

      const targetValueRaw = m?.target_value ?? m?.targetValue;
      const targetValueNum = typeof targetValueRaw === "number" ? targetValueRaw : Number(targetValueRaw);
      if (!Number.isFinite(targetValueNum)) {
        return [] as any[];
      }

      const currentBaselineRaw = m?.current_baseline ?? m?.currentBaseline;
      const currentBaselineNum =
        typeof currentBaselineRaw === "number" ? currentBaselineRaw : Number(currentBaselineRaw ?? 0);

      let unit: string =
        typeof m?.unit === "string" && m.unit.trim().length > 0
          ? m.unit.trim()
          : "count";

      let status: string =
        typeof m?.status === "string" && m.status.trim().length > 0
          ? m.status.trim().toLowerCase()
          : "planned";
      if (!allowedStatuses.includes(status)) status = "planned";

      const activityRefFromModel: string | undefined =
        typeof m?.activity_ref === "string" && m.activity_ref.trim().length > 0
          ? m.activity_ref.trim()
          : typeof m?.activityRef === "string" && m.activityRef.trim().length > 0
          ? m.activityRef.trim()
          : undefined;

      const finalActivityRef = activityRefFromModel ?? activityRef ?? null;

      return [
        {
          objective_id: objectiveId,
          channel,
          metric,
          target_value: targetValueNum,
          current_baseline: currentBaselineNum,
          unit,
          status,
          activity_ref: finalActivityRef,
          source: "ai",
        },
      ];
    });

    if (rowsToInsert.length === 0) {
      return new Response(
        JSON.stringify({ source: "mission_brain", missions: [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: inserted, error: insertError } = await supabase
      .from("studio_marketing_missions")
      .insert(rowsToInsert)
      .select();

    if (insertError) {
      console.error("Error inserting marketing missions", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to insert marketing missions" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ source: "mission_brain", missions: inserted ?? [] }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("Unexpected error in mission-brain", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
