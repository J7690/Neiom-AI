import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type OrchestratorRequest = {
  missionId?: string;
  objective?: string;
  channel?: string;
  periodDays?: number;
  locale?: string;
  contextId?: string;
  refreshKnowledge?: boolean;
};

function toDateOnlyString(d: Date): string {
  return d.toISOString().split("T")[0] ?? "";
}

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
    return new Response(
      JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  let body: OrchestratorRequest;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const missionId =
    typeof body?.missionId === "string" && body.missionId.trim().length > 0
      ? body.missionId.trim()
      : null;

  const locale =
    typeof body?.locale === "string" && body.locale.trim().length > 0
      ? body.locale.trim()
      : "fr";

  const refreshKnowledge = body?.refreshKnowledge === true;

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    // 1) Optionnel : fixer le contexte actif si contextId fourni
    const contextId =
      typeof body?.contextId === "string" && body.contextId.trim().length > 0
        ? body.contextId.trim()
        : null;
    if (contextId) {
      try {
        await supabase.rpc("set_active_studio_context", { p_context_id: contextId });
      } catch (e) {
        console.error("set_active_studio_context failed in mission-intelligence-orchestrator", e);
      }
    }

    // 2) Charger éventuellement la mission pour compléter les paramètres
    let mission: any = null;
    let missionTopic: string | null = null;
    if (missionId) {
      try {
        const { data, error } = await supabase
          .from("studio_marketing_missions")
          .select(
            "id, objective_id, source, channel, metric, activity_ref, current_baseline, target_value, unit, status, start_date, end_date",
          )
          .eq("id", missionId)
          .limit(1)
          .single();

        if (error) {
          console.error("Error loading mission in mission-intelligence-orchestrator", error);
        } else {
          mission = data ?? null;
          if (
            mission &&
            typeof mission.activity_ref === "string" &&
            mission.activity_ref.trim().length > 0
          ) {
            missionTopic = mission.activity_ref.trim();
          }
        }
      } catch (e) {
        console.error("Unexpected error loading mission in mission-intelligence-orchestrator", e);
      }
    }

    // 3) Résoudre l'objectif (notoriety|engagement|conversion)
    const allowedObjectives = ["notoriety", "engagement", "conversion"] as const;

    let objective: string | null =
      typeof body?.objective === "string" && body.objective.trim().length > 0
        ? body.objective.trim()
        : null;

    // Si pas d'objectif explicite, tenter de le déduire depuis studio_marketing_objectives
    if (!objective && mission?.objective_id) {
      try {
        const { data: objData, error: objError } = await supabase
          .from("studio_marketing_objectives")
          .select("objective")
          .eq("id", mission.objective_id)
          .limit(1)
          .single();
        if (objError) {
          console.error("Error loading objective for mission in orchestrator", objError);
        } else if (objData && typeof objData.objective === "string") {
          objective = objData.objective;
        }
      } catch (e) {
        console.error("Unexpected error loading objective in orchestrator", e);
      }
    }

    if (!objective || !allowedObjectives.includes(objective as any)) {
      objective = "engagement";
    }

    // 4) Résoudre le canal
    let channel: string =
      typeof body?.channel === "string" && body.channel.trim().length > 0
        ? body.channel.trim()
        : mission?.channel && typeof mission.channel === "string"
        ? mission.channel
        : "facebook";

    // 5) Période
    let periodDays =
      typeof body?.periodDays === "number" && Number.isFinite(body.periodDays)
        ? body.periodDays
        : 30;
    if (!Number.isFinite(periodDays)) periodDays = 30;
    if (periodDays < 7) periodDays = 7;
    if (periodDays > 365) periodDays = 365;

    const now = new Date();
    const startDate = new Date(now.getTime() - periodDays * 24 * 60 * 60 * 1000);
    const periodStart = toDateOnlyString(startDate);
    const periodEnd = toDateOnlyString(now);

    const functionsOrigin = new URL(supabaseUrl).origin.replace(
      ".supabase.co",
      ".functions.supabase.co",
    );

    // 6) Optionnel : rafraîchir la base de connaissances marketing
    let knowledgeIngestResult: any = null;
    if (refreshKnowledge) {
      try {
        const ingestUrl = `${functionsOrigin}/marketing-knowledge-ingest`;
        const ingestPayload: Record<string, unknown> = {
          useDefaultSources: true,
          useDefaultWebSearch: true,
        };
        if (missionTopic) {
          ingestPayload["webSearchTopics"] = [missionTopic];
        }
        const ingestResp = await fetch(ingestUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            apikey: supabaseServiceRoleKey,
            Authorization: `Bearer ${supabaseServiceRoleKey}`,
          },
          body: JSON.stringify(ingestPayload),
        });
        if (ingestResp.ok) {
          knowledgeIngestResult = await ingestResp.json();
        } else {
          const text = await ingestResp.text();
          console.error("marketing-knowledge-ingest failed in orchestrator", {
            status: ingestResp.status,
            bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
          });
        }
      } catch (e) {
        console.error("Unexpected error calling marketing-knowledge-ingest in orchestrator", e);
      }
    }

    // 7) Benchmark interne/externe (M5)
    let benchmark: any = null;
    try {
      const benchmarkUrl = `${functionsOrigin}/marketing-benchmark`;
      const benchmarkPayload = {
        brandKey: "nexium_group",
        channel,
        objective,
        periodDays,
        locale,
        focusActivity: mission?.activity_ref ?? null,
      };
      const benchResp = await fetch(benchmarkUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: supabaseServiceRoleKey,
          Authorization: `Bearer ${supabaseServiceRoleKey}`,
        },
        body: JSON.stringify(benchmarkPayload),
      });
      if (benchResp.ok) {
        benchmark = await benchResp.json();
      } else {
        const text = await benchResp.text();
        console.error("marketing-benchmark failed in orchestrator", {
          status: benchResp.status,
          bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
        });
      }
    } catch (e) {
      console.error("Unexpected error calling marketing-benchmark in orchestrator", e);
    }

    // 8) Diagnostic intelligence marketing (assistant)
    let assistantReport: any = null;
    try {
      const assistantUrl = `${functionsOrigin}/studio-marketing-assistant`;
      const assistantPayload: Record<string, unknown> = {
        objective,
        period: "last_30_days",
        locale,
        market: "bf_ouagadougou",
        audienceSegment: "students",
      };
      if (missionTopic) {
        assistantPayload["focusActivity"] = missionTopic;
      }
      const assistantResp = await fetch(assistantUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: supabaseServiceRoleKey,
          Authorization: `Bearer ${supabaseServiceRoleKey}`,
        },
        body: JSON.stringify(assistantPayload),
      });
      if (assistantResp.ok) {
        assistantReport = await assistantResp.json();
      } else {
        const text = await assistantResp.text();
        console.error("studio-marketing-assistant failed in orchestrator", {
          status: assistantResp.status,
          bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
        });
      }
    } catch (e) {
      console.error("Unexpected error calling studio-marketing-assistant in orchestrator", e);
    }

    // 9) Recommandations opérationnelles (marketing-brain)
    let brainResult: any = null;
    let generatedRecommendationsCount = 0;
    try {
      const brainUrl = `${functionsOrigin}/marketing-brain`;
      const brainPayload = {
        objective,
        count: 5,
        channel,
        locale,
        market: "bf_ouagadougou",
        audienceSegment: "students",
        missionId: missionId ?? undefined,
      };
      const brainResp = await fetch(brainUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: supabaseServiceRoleKey,
          Authorization: `Bearer ${supabaseServiceRoleKey}`,
        },
        body: JSON.stringify(brainPayload),
      });
      if (brainResp.ok) {
        brainResult = await brainResp.json();
        const recs = (brainResult?.recommendations ?? []) as any[];
        if (Array.isArray(recs)) {
          generatedRecommendationsCount = recs.length;
        }
      } else {
        const text = await brainResp.text();
        console.error("marketing-brain failed in orchestrator", {
          status: brainResp.status,
          bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
        });
      }
    } catch (e) {
      console.error("Unexpected error calling marketing-brain in orchestrator", e);
    }

    // 10) Charger l'état des objectifs pour résumer le contexte
    let objectiveState: any = null;
    let learningInsights: any[] = [];
    try {
      const { data: stateData, error: stateError } = await supabase.rpc(
        "get_marketing_objective_state",
      );
      if (stateError) {
        console.error("get_marketing_objective_state error in orchestrator", stateError);
      } else if (stateData) {
        objectiveState = stateData;
      }
    } catch (e) {
      console.error("Unexpected error calling get_marketing_objective_state in orchestrator", e);
    }

    try {
      const { data: memoryData, error: memoryError } = await supabase.rpc(
        "get_studio_memory",
        { p_brand_key: "nexium_group", p_locale: locale, p_insights_limit: 5 },
      );
      if (memoryError) {
        console.error("get_studio_memory error in orchestrator", memoryError);
      } else if (
        memoryData &&
        Array.isArray((memoryData as any).learning_insights)
      ) {
        learningInsights = (memoryData as any).learning_insights;
      }
    } catch (e) {
      console.error("Unexpected error calling get_studio_memory in orchestrator", e);
    }

    let missionIntelligenceReport: Record<string, unknown> | null = null;
    let reportPersisted = false;

    // 11) Enregistrer un run global dans l'historique des analyses et construire le rapport
    try {
      const inputMetrics: Record<string, unknown> = {
        objective,
        channel,
        locale,
        period_days: periodDays,
        period_start: periodStart,
        period_end: periodEnd,
        mission_id: missionId,
        context_id: contextId,
      };
      let assistantDiagnosticSummary: string | null = null;
      let benchmarkSummary: string | null = null;
      let benchmarkId: string | null = null;
      let externalCounts: { official: number; trusted: number; other: number } | null = null;

      try {
        if (assistantReport && typeof assistantReport === "object") {
          const diag = (assistantReport as any).diagnostic;
          if (
            diag &&
            typeof diag.summary === "string" &&
            diag.summary.trim().length > 0
          ) {
            assistantDiagnosticSummary = diag.summary.trim();
          }
        }
      } catch (extractError) {
        console.error(
          "Error extracting assistant diagnostic summary in orchestrator",
          extractError,
        );
      }

      try {
        if (benchmark && typeof benchmark === "object") {
          const anyBenchmark = benchmark as any;
          const rawId = anyBenchmark.benchmark_id;
          if (typeof rawId === "string" && rawId.trim().length > 0) {
            benchmarkId = rawId.trim();
          }

          const fr = anyBenchmark.final_recommendations;
          if (
            fr &&
            typeof fr === "object" &&
            typeof (fr as any).summary === "string" &&
            (fr as any).summary.trim().length > 0
          ) {
            benchmarkSummary = (fr as any).summary.trim();
          }

          const officialArr = Array.isArray(anyBenchmark.external_official)
            ? anyBenchmark.external_official
            : [];
          const trustedArr = Array.isArray(anyBenchmark.external_trusted)
            ? anyBenchmark.external_trusted
            : [];
          const otherArr = Array.isArray(anyBenchmark.external_other)
            ? anyBenchmark.external_other
            : [];

          externalCounts = {
            official: officialArr.length,
            trusted: trustedArr.length,
            other: otherArr.length,
          };
        }
      } catch (extractBenchmarkError) {
        console.error(
          "Error extracting benchmark metadata in orchestrator",
          extractBenchmarkError,
        );
      }

      // Préparer les structures d'analyse, même si benchmark/assistant sont partiels ou absents.
      const internalAnalysis: Record<string, unknown> = {
        top_formats: [] as any[],
        best_times: [] as any[],
        top_hashtags: [] as any[],
        performance_patterns: [] as any[],
      };

      const externalAnalysis: Record<string, unknown> = {
        sources: {
          official: [] as any[],
          trusted: [] as any[],
          other: [] as any[],
        },
        best_practices: [] as any[],
        trending_hashtags: [] as any[],
      };

      const gapAnalysis: any[] = [];
      if (assistantDiagnosticSummary) {
        gapAnalysis.push({
          type: "assistant_diagnostic",
          summary: assistantDiagnosticSummary,
        });
      }
      if (benchmarkSummary) {
        gapAnalysis.push({
          type: "benchmark_summary",
          summary: benchmarkSummary,
        });
      }

      const contextAlignment: Record<string, unknown> = {
        objective_state: objectiveState ?? null,
        mission: mission ?? null,
        period: {
          start: periodStart,
          end: periodEnd,
          days: periodDays,
        },
      };

      const insightsForRecommendationEngine: {
        recommended_formats: string[];
        recommended_angles: string[];
        recommended_hashtags: string[];
        recommended_cta: string[];
        recommended_times: string[];
      } = {
        recommended_formats: [],
        recommended_angles: [],
        recommended_hashtags: [],
        recommended_cta: [],
        recommended_times: [],
      };

      try {
        if (benchmark && typeof benchmark === "object") {
          const anyBenchmark = benchmark as any;
          const internalStats = anyBenchmark.internal_stats ?? {};

          const patternsArr: any[] = Array.isArray(internalStats.performance_patterns)
            ? internalStats.performance_patterns
            : [];
          (internalAnalysis.performance_patterns as any[]) = patternsArr;
          (internalAnalysis.top_formats as any[]) = patternsArr.filter(
            (p: any) => p && p.pattern_type === "format",
          );

          const bestTimeSlots: any[] = Array.isArray(internalStats.best_time_slots)
            ? internalStats.best_time_slots
            : [];
          (internalAnalysis.best_times as any[]) = bestTimeSlots;

          const bestHashtags: any[] = Array.isArray(internalStats.best_hashtags)
            ? internalStats.best_hashtags
            : [];
          (internalAnalysis.top_hashtags as any[]) = bestHashtags;

          const officialDocs: any[] = Array.isArray(anyBenchmark.external_official)
            ? anyBenchmark.external_official
            : [];
          const trustedDocs: any[] = Array.isArray(anyBenchmark.external_trusted)
            ? anyBenchmark.external_trusted
            : [];
          const otherDocs: any[] = Array.isArray(anyBenchmark.external_other)
            ? anyBenchmark.external_other
            : [];

          (externalAnalysis.sources as any).official = officialDocs;
          (externalAnalysis.sources as any).trusted = trustedDocs;
          (externalAnalysis.sources as any).other = otherDocs;

          const finalRecRaw = anyBenchmark.final_recommendations;
          let finalRec: any = null;
          if (Array.isArray(finalRecRaw) && finalRecRaw.length > 0) {
            finalRec = finalRecRaw[0];
          } else if (finalRecRaw && typeof finalRecRaw === "object") {
            finalRec = finalRecRaw;
          }

          if (finalRec && typeof finalRec === "object") {
            const formatStrategy = (finalRec as any).format_strategy;
            if (
              formatStrategy &&
              Array.isArray((formatStrategy as any).recommended_formats)
            ) {
              insightsForRecommendationEngine.recommended_formats = (
                formatStrategy as any
              ).recommended_formats.filter((x: any) => typeof x === "string");
            }

            const hashtagStrategy = (finalRec as any).hashtag_strategy;
            if (
              hashtagStrategy &&
              Array.isArray((hashtagStrategy as any).recommended_hashtags)
            ) {
              insightsForRecommendationEngine.recommended_hashtags = (
                hashtagStrategy as any
              ).recommended_hashtags.filter((x: any) => typeof x === "string");
            }

            const contentStrategy = (finalRec as any).content_strategy;
            if (contentStrategy) {
              if (Array.isArray((contentStrategy as any).angles)) {
                insightsForRecommendationEngine.recommended_angles = (
                  contentStrategy as any
                ).angles.filter((x: any) => typeof x === "string");
              }
              if (Array.isArray((contentStrategy as any).call_to_actions)) {
                insightsForRecommendationEngine.recommended_cta = (
                  contentStrategy as any
                ).call_to_actions.filter((x: any) => typeof x === "string");
              }
            }

            const postingTimeStrategy = (finalRec as any).posting_time_strategy;
            if (
              postingTimeStrategy &&
              Array.isArray((postingTimeStrategy as any).best_slots)
            ) {
              insightsForRecommendationEngine.recommended_times = (
                postingTimeStrategy as any
              ).best_slots.filter((x: any) => typeof x === "string");
            }
          }
        }
      } catch (buildReportError) {
        console.error(
          "Error enriching mission intelligence report from benchmark in mission-intelligence-orchestrator",
          buildReportError,
        );
      }

      if (missionId) {
        missionIntelligenceReport = {
          mission_id: missionId,
          objective,
          channel,
          internal_analysis: internalAnalysis,
          external_analysis: externalAnalysis,
          gap_analysis: gapAnalysis,
          context_alignment: contextAlignment,
          insights_for_recommendation_engine: insightsForRecommendationEngine,
          learning_insights: learningInsights,
        };
        console.log(
          "mission-intelligence-orchestrator: built mission intelligence report for mission",
          { missionId },
        );
      }

      if (missionId && missionIntelligenceReport) {
        try {
          const { error: reportInsertError } = await supabase
            .from("studio_mission_intelligence_reports")
            .insert({
              mission_id: missionId,
              objective,
              channel,
              report: missionIntelligenceReport,
            });
          if (reportInsertError) {
            console.error(
              "Error inserting mission intelligence report in mission-intelligence-orchestrator",
              { missionId, error: reportInsertError },
            );
          } else {
            reportPersisted = true;
            console.log(
              "mission-intelligence-orchestrator: mission intelligence report persisted",
              { missionId },
            );
          }
        } catch (insertReportError) {
          console.error(
            "Unexpected error inserting mission intelligence report in mission-intelligence-orchestrator",
            { missionId, error: insertReportError },
          );
        }
      }

      if (missionId && !reportPersisted) {
        console.error(
          "mission-intelligence-orchestrator: mission has no persisted intelligence report after orchestration",
          { missionId },
        );
        throw new Error("mission_intelligence_report_not_persisted");
      }

      const outputSummary: Record<string, unknown> = {
        source: "mission_intelligence_orchestrator",
        generated_recommendations: generatedRecommendationsCount,
        knowledge_refreshed: refreshKnowledge,
        has_benchmark: benchmark != null,
      };
      if (benchmarkId) {
        (outputSummary as any).benchmark_id = benchmarkId;
      }
      if (benchmarkSummary) {
        (outputSummary as any).benchmark_summary = benchmarkSummary;
      }
      if (assistantDiagnosticSummary) {
        (outputSummary as any).assistant_diagnostic_summary =
          assistantDiagnosticSummary;
      }
      if (externalCounts) {
        (outputSummary as any).external_sources_counts = externalCounts;
      }

      await supabase.rpc("record_studio_analysis_run", {
        p_source: "mission_intelligence_orchestrator",
        p_analysis_from: null,
        p_analysis_to: null,
        p_input_metrics: inputMetrics,
        p_output_summary: outputSummary,
      });
    } catch (e) {
      console.error("record_studio_analysis_run failed in orchestrator", {
        error: e,
        missionId,
      });
    }

    const responseBody = {
      source: "mission_intelligence_orchestrator",
      mission: mission,
      objective,
      channel,
      locale,
      period_start: periodStart,
      period_end: periodEnd,
      objective_state: objectiveState,
      knowledge_ingest: knowledgeIngestResult,
      benchmark,
      assistant_report: assistantReport,
      brain_result: brainResult,
      mission_intelligence_report: missionIntelligenceReport,
      mission_intelligence_report_persisted: reportPersisted,
    };

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in mission-intelligence-orchestrator", {
      error: e,
      missionId,
    });
    return new Response(
      JSON.stringify({
        error: "Unexpected error in mission-intelligence-orchestrator",
        details: e instanceof Error ? e.message : String(e),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
