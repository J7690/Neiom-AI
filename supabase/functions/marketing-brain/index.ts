// Supabase Edge Function: marketing-brain
// Génère des recommandations marketing via OpenRouter et les persiste
// dans studio_marketing_recommendations, en s'appuyant sur le contexte réel
// (objectifs marketing, patterns de performance, etc.).

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

  const authHeader = req.headers.get("authorization") ?? "";
  const isServiceRoleCaller =
    !!supabaseServiceRoleKey && authHeader === `Bearer ${supabaseServiceRoleKey}`;

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
  const requestedCount: number | undefined =
    typeof body?.count === "number" && Number.isFinite(body.count)
      ? body.count
      : undefined;
  const locale: string =
    typeof body?.locale === "string" && body.locale.trim().length > 0
      ? body.locale.trim()
      : "fr";
  const channel: string =
    typeof body?.channel === "string" && body.channel.trim().length > 0
      ? body.channel.trim()
      : "facebook";
  const marketCode: string =
    typeof body?.market === "string" && body.market.trim().length > 0
      ? body.market.trim()
      : "bf_ouagadougou";
  const audienceSegment: string =
    typeof body?.audienceSegment === "string" && body.audienceSegment.trim().length > 0
      ? body.audienceSegment.trim()
      : "students";
  const missionId: string | undefined =
    typeof body?.missionId === "string" && body.missionId.trim().length > 0
      ? body.missionId.trim()
      : undefined;

  const allowedObjectives = ["notoriety", "engagement", "conversion"] as const;
  const defaultObjective = "engagement" as const;

  const baseObjective =
    requestedObjective && allowedObjectives.includes(requestedObjective as any)
      ? (requestedObjective as (typeof allowedObjectives)[number])
      : defaultObjective;

  let count = requestedCount ?? 5;
  if (!Number.isFinite(count)) count = 5;
  if (count < 1) count = 1;
  if (count > 20) count = 20;

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    // Lire éventuellement la configuration de gouvernance IA + modèle texte d'analyse
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
      // Bascule complète sur la RPC SQL historique sans appel OpenRouter
      const { data: fallbackData, error: fallbackError } = await supabase.rpc(
        "generate_marketing_recommendation",
        { p_objective: baseObjective, p_count: count },
      );

      if (fallbackError) {
        console.error(
          "marketing-brain disabled (openrouter_enabled = false) and fallback RPC failed",
          fallbackError,
        );
        return new Response(
          JSON.stringify({
            error:
              "OpenRouter désactivé dans ai_orchestration_settings et generate_marketing_recommendation a échoué.",
          }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({
          source: "sql_only_openrouter_disabled",
          recommendations: fallbackData ?? [],
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: studioMemoryData, error: studioMemoryError } = await supabase.rpc(
      "get_studio_memory",
      { p_brand_key: "nexium_group", p_locale: locale, p_insights_limit: 5 },
    );
    if (studioMemoryError) {
      console.error("get_studio_memory error in marketing-brain", studioMemoryError);
    }
    const studioMemory = studioMemoryData ?? null;

    // Appeler l'Edge Function marketing-benchmark pour obtenir un benchmark
    // interne/externe structuré sur la période récente (lecture seule, sans impact
    // sur le pipeline de publication)
    let marketingBenchmark: any = null;
    try {
      if (supabaseUrl && supabaseServiceRoleKey) {
        const supabaseUrlObj = new URL(supabaseUrl);
        const functionsOrigin = supabaseUrlObj.origin.replace(
          ".supabase.co",
          ".functions.supabase.co",
        );
        const benchmarkUrl = `${functionsOrigin}/marketing-benchmark`;

        const benchmarkPayload = {
          brandKey: "nexium_group",
          channel,
          objective: baseObjective,
          periodDays: 30,
          locale,
        };

        const benchmarkResp = await fetch(benchmarkUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "apikey": supabaseServiceRoleKey,
            "Authorization": `Bearer ${supabaseServiceRoleKey}`,
          },
          body: JSON.stringify(benchmarkPayload),
        });

        if (benchmarkResp.ok) {
          marketingBenchmark = await benchmarkResp.json();
        } else {
          const text = await benchmarkResp.text();
          console.error("marketing-benchmark call failed in marketing-brain", {
            status: benchmarkResp.status,
            bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
          });
        }
      }
    } catch (benchmarkError) {
      console.error("Unexpected error calling marketing-benchmark in marketing-brain", benchmarkError);
    }

    // Charger le contexte marketing, le contexte de marque, les performances Facebook réelles
    // et les hashtags tendance de la page depuis la base
    const [
      objectivesRes,
      patternsRes,
      fbOverviewRes,
      objectiveSummaryRes,
      brandContextRes,
      trendingHashtagsRes,
    ] = await Promise.all([
        supabase
          .from("studio_marketing_objectives")
          .select(
            "id, objective, target_value, current_value, unit, horizon, status, target_date",
          )
          .eq("status", "active"),
        supabase
          .from("studio_performance_patterns")
          .select(
            "pattern_type, pattern_name, description, confidence_score, performance_impact, sample_size",
          )
          .eq("is_active", true),
        supabase.rpc("get_facebook_post_performance_overview", { p_days: 30 }),
        supabase.rpc("get_objective_performance_summary", { p_days: 30 }),
        supabase
          .from("studio_brand_context")
          .select("content")
          .eq("brand_key", "nexium_group")
          .eq("locale", locale)
          .limit(1),
        supabase.rpc("get_best_hashtags_for_topic", { p_topic: null, p_limit: 50, p_days: 90 }),
      ]);

    const objectives = (objectivesRes.data ?? []) as any[];
    const patterns = (patternsRes.data ?? []) as any[];
    const facebookOverview = (fbOverviewRes.data ?? []) as any[];
    const objectivePerformance = (objectiveSummaryRes.data ?? []) as any[];
    const brandContextRow =
      ((brandContextRes.data as any[] | null | undefined) ?? [])[0] as
        | { content?: unknown }
        | undefined;
    const brandContext = (brandContextRow?.content as Record<string, unknown> | null | undefined) ?? null;

  const trendingHashtagsData = (trendingHashtagsRes.data ?? []) as
    | { hashtag?: string; score?: number; posts_count?: number }[]
    | any[];

  let missionIntelligenceReport: any = null;
  let reportRecommendedHashtags: string[] = [];

  if (missionId) {
    try {
      const { data: reportData, error: reportError } = await supabase.rpc(
        "get_latest_mission_intelligence_report",
        { p_mission_id: missionId },
      );
      if (reportError) {
        console.error(
          "get_latest_mission_intelligence_report error in marketing-brain",
          reportError,
        );
      } else if (reportData) {
        missionIntelligenceReport = reportData;
        try {
          const insights = (reportData as any).insights_for_recommendation_engine;
          if (
            insights &&
            Array.isArray((insights as any).recommended_hashtags)
          ) {
            reportRecommendedHashtags = (
              insights as any
            ).recommended_hashtags.filter(
              (h: any) => typeof h === "string" && h.trim().length > 0,
            );
          }
        } catch (extractError) {
          console.error(
            "Error extracting recommended hashtags from mission intelligence report in marketing-brain",
            extractError,
          );
        }
      }
    } catch (e) {
      console.error(
        "Unexpected error calling get_latest_mission_intelligence_report in marketing-brain",
        e,
      );
    }
  }

  if (missionId && !missionIntelligenceReport && !isServiceRoleCaller) {
    return new Response(
      JSON.stringify({
        error: "No mission intelligence report found for mission.",
        code: "MISSION_INTELLIGENCE_REPORT_REQUIRED",
      }),
      {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const contextPayload = {
    locale,
    channel,
    market: marketCode,
    audience_segment: audienceSegment,
    objective: baseObjective,
    objectives,
    performance_patterns: patterns,
    facebook_performance_overview: facebookOverview,
    objective_performance_summary: objectivePerformance,
    facebook_trending_hashtags: trendingHashtagsData,
    brand_context: brandContext,
    studio_memory: studioMemory,
    marketing_benchmark: marketingBenchmark,
    mission_id: missionId,
    mission_intelligence_report: missionIntelligenceReport,
    now: new Date().toISOString(),
    expected_recommendations: count,
  };

  const systemPrompt = `
Tu es l'assistant marketing décisionnel de Nexiom AI Studio. Tu dois produire des recommandations marketing prêtes à l'emploi pour Facebook, en français, en respectant strictement le format JSON demandé.
Le résultat attendu est un tableau JSON de recommandations. Chaque recommandation doit respecter la structure suivante (les valeurs sont des exemples) :

[
  {
    "objective": "notoriety|engagement|conversion",
    "recommendation_summary": "résumé court de la recommandation",
    "reasoning": "explication de la recommandation",
    "proposed_format": "text|image|video",
    "proposed_message": "texte complet du post Facebook en français",
    "proposed_media_prompt": "prompt texte détaillé pour générer un visuel ou une vidéo cohérente, en précisant systématiquement que la scène se déroule en Afrique de l'Ouest (Burkina Faso), que les personnes représentées sont africaines/noires, que l'environnement est un bureau ou un lieu d'apprentissage modeste réaliste pour ce contexte, et que tous les textes visibles sur l'image sont en français uniquement",
    "confidence_level": "low|medium|high",
    "hashtags": ["#hashtag1", "#hashtag2", "#..."]
  }
]

Le JSON de contexte fourni contient notamment un champ 'mission_id' et, le cas échéant, un objet 'mission_intelligence_report' avec les analyses internes, externes, les hashtags recommandés et les angles de contenu pour une mission marketing précise.
La mission en cours est décrite dans 'mission_intelligence_report.context_alignment.mission' (par exemple des travaux dirigés, des cours d'appui, un type de programme précis, etc.). Tu dois lire attentivement ce bloc et considérer que ton objectif premier est de promouvoir cette mission précise, pas la plateforme en général ni les formations de façon abstraite.

Pour CHAQUE recommandation :
- le champ "recommendation_summary" doit mentionner explicitement l'activité de la mission (par exemple les travaux dirigés / cours d'appui concernés) ;
- le champ "proposed_message" doit décrire concrètement cette activité (ce que sont les TD / cours d'appui, comment ils se déroulent, à qui ils s'adressent, quels bénéfices concrets pour les étudiants, etc.) en réutilisant les angles et éléments fournis dans 'mission_intelligence_report' (notamment 'insights_for_recommendation_engine' et 'context_alignment.mission').
Ne propose jamais de recommandations qui n'ont aucun lien direct avec cette mission ou qui restent générales sur la plateforme.

Pour chaque recommandation qui implique un visuel (image ou vidéo), tu VEILLERAS à ce que le champ 'proposed_media_prompt' décrive explicitement un contexte visuel africain francophone centré sur le Burkina Faso ou l'Afrique de l'Ouest, avec des personnes noires (jamais de visages typés caucasiens ou asiatiques), dans des bureaux ou environnements modestes réalistes pour ce contexte, et en demandant que tous les textes visibles sur le visuel soient UNIQUEMENT en français (aucun mot en anglais).
Tu NE DOIS JAMAIS utiliser les mots "bourse" ou "bourses" ni dans "proposed_message" ni dans la description du texte affiché sur les visuels. Parle uniquement de réductions, d'avantages, de facilités ou de conditions spéciales négociées sur les frais de formation.
Tu dois générer exactement ${count} recommandations (N est fourni dans le contexte).
N'inclus JAMAIS de commentaires en dehors du JSON. Le JSON doit être valide et directement parsable.
`;

  const userContent =
    "Voici le contexte JSON actuel pour construire tes recommandations (n'y ajoute rien, ne le modifie pas) :\n" +
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
      console.error("OpenRouter error in marketing-brain", {
        status: resp.status,
        bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
      });

      // Fallback : appeler la RPC SQL historique
      const { data: fallbackData, error: fallbackError } = await supabase.rpc(
        "generate_marketing_recommendation",
        { p_objective: baseObjective, p_count: count },
      );

      if (fallbackError) {
        console.error("Fallback generate_marketing_recommendation failed", fallbackError);
        return new Response(
          JSON.stringify({
            error: "OpenRouter request failed and fallback RPC failed",
            providerStatus: resp.status,
            providerBody: text,
          }),
          { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({
          source: "sql_fallback",
          recommendations: fallbackData ?? [],
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
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
      console.error("No text content in OpenRouter response in marketing-brain", {
        model: analysisModel,
        rawResponse: json,
      });

      // Fallback: RPC SQL historique si le provider ne renvoie aucun texte exploitable
      const { data: fallbackData, error: fallbackError } = await supabase.rpc(
        "generate_marketing_recommendation",
        { p_objective: baseObjective, p_count: count },
      );

      if (fallbackError) {
        console.error(
          "Fallback generate_marketing_recommendation failed after empty OpenRouter response",
          fallbackError,
        );
        return new Response(
          JSON.stringify({
            error:
              "No text content in OpenRouter response and fallback RPC failed in marketing-brain",
          }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({ source: "sql_fallback", recommendations: fallbackData ?? [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    let parsed: any;
    try {
      const trimmed = replyText.trim();
      parsed = JSON.parse(trimmed);
    } catch (e) {
      console.error("Failed to parse marketing-brain JSON", e, replyText);

      // Fallback: RPC SQL historique
      const { data: fallbackData, error: fallbackError } = await supabase.rpc(
        "generate_marketing_recommendation",
        { p_objective: baseObjective, p_count: count },
      );

      if (fallbackError) {
        console.error("Fallback generate_marketing_recommendation failed", fallbackError);
        return new Response(
          JSON.stringify({ error: "marketing-brain JSON parse failed and fallback RPC failed" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({ source: "sql_fallback", recommendations: fallbackData ?? [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    let recs: any[] = [];
    if (Array.isArray(parsed)) {
      recs = parsed;
    } else if (Array.isArray(parsed?.recommendations)) {
      recs = parsed.recommendations;
    }

    if (!Array.isArray(recs) || recs.length === 0) {
      // Pas de recommandations IA : fallback SQL
      const { data: fallbackData, error: fallbackError } = await supabase.rpc(
        "generate_marketing_recommendation",
        { p_objective: baseObjective, p_count: count },
      );

      if (fallbackError) {
        console.error("Fallback generate_marketing_recommendation failed", fallbackError);
        return new Response(
          JSON.stringify({ error: "No AI recommendations and fallback RPC failed" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({ source: "sql_fallback", recommendations: fallbackData ?? [] }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const allowedFormats = ["text", "image", "video"] as const;
    const allowedConfidence = ["low", "medium", "high"] as const;

    const rowsToInsert = recs.slice(0, count).map((r: any) => {
      const rawObjective: string =
        typeof r?.objective === "string" && r.objective.trim().length > 0
          ? r.objective.trim().toLowerCase()
          : baseObjective;
      const objective = allowedObjectives.includes(rawObjective as any)
        ? rawObjective
        : baseObjective;

      const rawFormat: string =
        typeof r?.proposed_format === "string" && r.proposed_format.trim().length > 0
          ? r.proposed_format.trim().toLowerCase()
          : "";

      let proposed_format: string;
      if (allowedFormats.includes(rawFormat as any)) {
        proposed_format = rawFormat;
      } else {
        // Heuristique simple : notoriety -> video, engagement -> image, sinon text
        if (objective === "notoriety") proposed_format = "video";
        else if (objective === "engagement") proposed_format = "image";
        else proposed_format = "text";
      }

      const rawConf: string =
        typeof r?.confidence_level === "string" && r.confidence_level.trim().length > 0
          ? r.confidence_level.trim().toLowerCase()
          : "";
      const confidence_level = allowedConfidence.includes(rawConf as any)
        ? rawConf
        : "medium";

      const recommendation_summary: string =
        typeof r?.recommendation_summary === "string" &&
        r.recommendation_summary.trim().length > 0
          ? r.recommendation_summary.trim()
          : "Action marketing recommande pour objectif " + objective;

      const reasoning: string | null =
        typeof r?.reasoning === "string" && r.reasoning.trim().length > 0
          ? r.reasoning.trim()
          : null;

      const proposed_message: string | null =
        typeof r?.proposed_message === "string" && r.proposed_message.trim().length > 0
          ? r.proposed_message.trim()
          : null;

      const proposed_media_prompt: string | null =
        typeof r?.proposed_media_prompt === "string" &&
        r.proposed_media_prompt.trim().length > 0
          ? r.proposed_media_prompt.trim()
          : null;

      const rawMarket: string =
        typeof r?.market === "string" && r.market.trim().length > 0
          ? r.market.trim()
          : marketCode;

      const rawAudience: string =
        typeof r?.audience_segment === "string" &&
        r.audience_segment.trim().length > 0
          ? r.audience_segment.trim()
          : audienceSegment;

      let hashtags: string[] | null = null;

      if (reportRecommendedHashtags.length > 0) {
        const seenFromReport = new Set<string>();
        hashtags = reportRecommendedHashtags
          .map((h) => (typeof h === "string" ? h.trim() : ""))
          .filter((h) => h.length > 0)
          .map((h) => (h.startsWith("#") ? h : `#${h}`))
          .filter((h) => {
            const lower = h.toLowerCase();
            if (seenFromReport.has(lower)) return false;
            seenFromReport.add(lower);
            return true;
          })
          .slice(0, 10);
      } else {
        if (Array.isArray(r?.hashtags)) {
          hashtags = (r.hashtags as any[])
            .map((h) => (typeof h === "string" ? h.trim() : ""))
            .filter((h: string) => h.length > 0);
        } else if (typeof r?.hashtags === "string") {
          const raw = r.hashtags as string;
          hashtags = raw
            .split(/[\s,]+/)
            .map((h) => h.trim())
            .filter((h) => h.length > 0)
            .map((h) => (h.startsWith("#") ? h : `#${h}`));
        }

        if (!hashtags || hashtags.length === 0) {
          const trendingRaw: string[] = trendingHashtagsData
            .map((item: any) =>
              typeof item?.hashtag === "string" ? item.hashtag.trim() : "",
            )
            .filter((h: string) => h.length > 0);

          let fallback = trendingRaw;
          if (fallback.length === 0) {
            fallback = [
              "#NexiomGroup",
              "#NexiomAIStudio",
              "#Academia",
              "#Etudiants",
              "#AfriqueDeLOuest",
            ];
          }

          const seenFallback = new Set<string>();
          hashtags = fallback
            .map((h) => (h.startsWith("#") ? h : `#${h}`))
            .filter((h) => {
              const lower = h.toLowerCase();
              if (seenFallback.has(lower)) return false;
              seenFallback.add(lower);
              return true;
            })
            .slice(0, 10);
        } else {
          if (hashtags && hashtags.length > 0) {
            const seen = new Set<string>();
            hashtags = hashtags
              .map((h) => (h.startsWith("#") ? h : `#${h}`))
              .filter((h) => {
                const lower = h.toLowerCase();
                if (seen.has(lower)) return false;
                seen.add(lower);
                return true;
              })
              .slice(0, 10);
          } else {
            hashtags = null;
          }
        }
      }

      return {
        objective,
        recommendation_summary,
        reasoning,
        proposed_format,
        proposed_message,
        proposed_media_prompt,
        confidence_level,
        hashtags,
        status: "pending",
        locale,
        market: rawMarket,
        audience_segment: rawAudience,
        mission_id: missionId ?? null,
      };
    });

    const { data: inserted, error: insertError } = await supabase
      .from("studio_marketing_recommendations")
      .insert(rowsToInsert)
      .select(
        "id, objective, recommendation_summary, reasoning, proposed_format, proposed_message, confidence_level, status, locale, market, audience_segment, created_at",
      );

    if (insertError) {
      console.error("Error inserting marketing recommendations", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to insert marketing recommendations" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    try {
      const inputMetrics = {
        objective: baseObjective,
        count,
        locale,
        channel,
        market: marketCode,
        audience_segment: audienceSegment,
        objectives,
        performance_patterns: patterns,
        facebook_performance_overview: facebookOverview,
        objective_performance_summary: objectivePerformance,
      };
      const outputSummary: Record<string, unknown> = {
        source: "marketing_brain",
        recommendations_count: (inserted ?? []).length,
      };
      if (studioMemory) {
        outputSummary["studio_memory"] = studioMemory;
      }

      await supabase.rpc("record_studio_analysis_run", {
        p_source: "marketing_brain",
        p_analysis_from: null,
        p_analysis_to: null,
        p_input_metrics: inputMetrics,
        p_output_summary: outputSummary,
      });
    } catch (logError) {
      console.error("record_studio_analysis_run failed", logError);
    }

    return new Response(
      JSON.stringify({ source: "marketing_brain", recommendations: inserted ?? [] }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("Unexpected error in marketing-brain", {
      error: e,
      missionId,
      objective: baseObjective,
      channel,
      locale,
    });
    return new Response(
      JSON.stringify({
        error: "Unexpected error in marketing-brain",
        details: e instanceof Error ? e.message : String(e),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
