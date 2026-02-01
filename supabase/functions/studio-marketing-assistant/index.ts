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
  const period: string =
    typeof body?.period === "string" && body.period.trim().length > 0
      ? body.period.trim()
      : "last_30_days";
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
  const focusActivity: string | null =
    typeof body?.focusActivity === "string" && body.focusActivity.trim().length > 0
      ? body.focusActivity.trim()
      : null;

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
    // Gouvernance IA + modèle texte pour l'assistant marketing
    let assistantModel = defaultChatModel;
    try {
      const { data: settingsData } = await supabase.rpc("get_ai_orchestration_settings");
      if (settingsData) {
        const anySettings = settingsData as any;
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
      console.error(
        "get_ai_orchestration_settings error in studio-marketing-assistant",
        settingsError,
      );
    }

    const { data: studioMemoryData, error: studioMemoryError } = await supabase.rpc(
      "get_studio_memory",
      { p_brand_key: "nexium_group", p_locale: locale, p_insights_limit: 5 },
    );
    if (studioMemoryError) {
      console.error("get_studio_memory error in studio-marketing-assistant", studioMemoryError);
    }
    const studioMemory = studioMemoryData ?? null;

    // Appeler l'Edge Function marketing-benchmark pour obtenir un benchmark
    // interne/externe structuré sur la période récente (lecture seule).
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
          channel: "facebook",
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
          console.error("marketing-benchmark call failed in studio-marketing-assistant", {
            status: benchmarkResp.status,
            bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
          });
        }
      }
    } catch (benchmarkError) {
      console.error(
        "Unexpected error calling marketing-benchmark in studio-marketing-assistant",
        benchmarkError,
      );
    }

    const [
      objectivesRes,
      patternsRes,
      fbOverviewRes,
      objectiveSummaryRes,
      recentRunsRes,
      brandContextRes,
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
      supabase.rpc("get_recent_studio_analysis_runs", { p_limit: 10 }),
      supabase
        .from("studio_brand_context")
        .select("content")
        .eq("brand_key", "nexium_group")
        .eq("locale", locale)
        .limit(1),
    ]);

    const objectives = (objectivesRes.data ?? []) as any[];
    const patterns = (patternsRes.data ?? []) as any[];
    const facebookOverview = (fbOverviewRes.data ?? []) as any[];
    const objectivePerformance = (objectiveSummaryRes.data ?? []) as any[];
    const recentRuns = (recentRunsRes.data ?? []) as any[];
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
      period,
      objectives,
      performance_patterns: patterns,
      facebook_performance_overview: facebookOverview,
      objective_performance_summary: objectivePerformance,
      recent_analysis_runs: recentRuns,
      brand_context: brandContext,
      studio_memory: studioMemory,
      marketing_benchmark: marketingBenchmark,
      focus_activity: focusActivity,
      now: new Date().toISOString(),
    };

    const systemPrompt =
      "Tu es l'assistant marketing stratégique du Studio Nexiom AI. " +
      "Tu parles comme un conseiller humain. Tu expliques simplement. Tu fais des recommandations concrètes. " +
      "Tu ne décides jamais à la place de l'humain et tu respectes strictement la réalité de Nexiom Group (courtier académique, pas de bourses, mais des réductions et facilités négociées). " +
      "Tu reçois un JSON de contexte contenant les objectifs marketing, les performances Facebook récentes, la mémoire du Studio et le brand_context. " +
      "Tu dois produire un diagnostic et des recommandations pour la page Facebook de Nexiom en Afrique de l'Ouest, en français. " +
      "Réponds STRICTEMENT sous la forme d'un objet JSON, sans texte autour, suivant ce schéma :\n" +
      "{\n" +
      "  \"diagnostic\": {\n" +
      "    \"summary\": \"phrase courte qui résume la situation actuelle\",\n" +
      "    \"what_works\": [\"éléments qui marchent bien\"],\n" +
      "    \"what_tires\": [\"éléments qui fatiguent l'audience ou l'algorithme\"],\n" +
      "    \"what_is_missing\": [\"angles, formats ou messages manquants\"]\n" +
      "  },\n" +
      "  \"recommendations\": [\n" +
      "    {\n" +
      "      \"title\": \"titre court de l'action recommandée\",\n" +
      "      \"objective\": \"notoriety|engagement|conversion\",\n" +
      "      \"priority\": \"high|medium|low\",\n" +
      "      \"explanation\": \"explication simple, liée aux données réelles\",\n" +
      "      \"actions\": [\"liste de 2 à 5 actions concrètes à réaliser\"]\n" +
      "    }\n" +
      "  ]\n" +
      "}\n" +
      "Si le champ 'focus_activity' est présent dans le contexte, ton diagnostic et tes recommandations doivent se concentrer en priorité sur cette activité précise (par exemple la promotion d'un cours d'appui ou d'une formation donnée) et traduire ce focus en actions concrètes. " +
      "Tu dois générer exactement 3 recommandations dans le tableau recommendations. " +
      "Le JSON doit être valide et directement parsable. N'ajoute JAMAIS de texte avant ou après l'objet JSON.";

    const userContent =
      "Voici le contexte JSON actuel pour construire ton diagnostic et tes recommandations (n'y ajoute rien, ne le modifie pas) :\n" +
      JSON.stringify(contextPayload, null, 2);

    const messages: any[] = [
      { role: "system", content: systemPrompt },
      { role: "user", content: userContent },
    ];

    const openrouterPayload = {
      model: assistantModel,
      messages,
      max_tokens: 2048,
    };

    const resp = await fetch(openrouterBaseUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openrouterApiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": httpReferer,
        "X-Title": openrouterTitle,
      },
      body: JSON.stringify(openrouterPayload),
    });

    if (!resp.ok) {
      const text = await resp.text();
      console.error("OpenRouter error in studio-marketing-assistant", {
        status: resp.status,
        bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
      });

      return new Response(
        JSON.stringify({
          error: "OpenRouter request failed in studio-marketing-assistant",
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
      throw new Error("No text content in OpenRouter response (studio-marketing-assistant)");
    }

    let assistantReport: any;
    try {
      const trimmed = replyText.trim();
      assistantReport = JSON.parse(trimmed);
    } catch (e) {
      console.error("Failed to parse studio-marketing-assistant JSON", e, replyText);
      return new Response(
        JSON.stringify({ error: "studio-marketing-assistant JSON parse failed" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    try {
      const inputMetrics = {
        objective: baseObjective,
        period,
        locale,
        market: marketCode,
        audience_segment: audienceSegment,
        objectives,
        performance_patterns: patterns,
        facebook_performance_overview: facebookOverview,
        objective_performance_summary: objectivePerformance,
      };
      const outputSummary: Record<string, unknown> = {
        source: "marketing_assistant",
      };
      if (assistantReport?.diagnostic?.summary) {
        outputSummary["diagnostic_summary"] = assistantReport.diagnostic.summary;
      }
      if (Array.isArray(assistantReport?.recommendations)) {
        outputSummary["recommendations_count"] = assistantReport.recommendations.length;
      }
      if (studioMemory) {
        outputSummary["studio_memory"] = studioMemory;
      }

      await supabase.rpc("record_studio_analysis_run", {
        p_source: "marketing_assistant",
        p_analysis_from: null,
        p_analysis_to: null,
        p_input_metrics: inputMetrics,
        p_output_summary: outputSummary,
      });
    } catch (logError) {
      console.error("record_studio_analysis_run failed in studio-marketing-assistant", logError);
    }

    const responseBody = {
      source: "marketing_assistant",
      objective: baseObjective,
      locale,
      market: marketCode,
      audience_segment: audienceSegment,
      diagnostic: assistantReport?.diagnostic ?? null,
      recommendations: Array.isArray(assistantReport?.recommendations)
        ? assistantReport.recommendations
        : [],
    };

    return new Response(
      JSON.stringify(responseBody),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("Unexpected error in studio-marketing-assistant", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
