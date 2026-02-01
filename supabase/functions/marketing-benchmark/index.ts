import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type BenchmarkRequest = {
  brandKey?: string;
  channel?: string;
  objective?: string;
  periodDays?: number;
  locale?: string;
  focusActivity?: string;
};

type ExternalSourceRow = {
  id: string;
  name: string;
  domain: string;
  priority: number | null;
  is_official: boolean | null;
  tags: string[] | null;
};

type ExternalDocLinkRow = {
  id: string;
  source_id: string;
  document_id: string;
  url: string | null;
  topic: string | null;
  language: string | null;
  importance_score: number | null;
};

type DocumentRow = {
  id: string;
  title: string | null;
  content: string | null;
  metadata: Record<string, unknown> | null;
};

function toDateOnlyString(d: Date): string {
  return d.toISOString().split("T")[0] ?? "";
}

function buildSnippet(content: string | null | undefined, maxLen = 800): string {
  if (!content) return "";
  let txt = content.replace(/\s+/g, " ").trim();
  if (txt.length > maxLen) {
    txt = txt.slice(0, maxLen) + "...";
  }
  return txt;
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

  let body: BenchmarkRequest;
  try {
    body = await req.json();
  } catch (_) {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const brandKey =
    typeof body?.brandKey === "string" && body.brandKey.trim().length > 0
      ? body.brandKey.trim()
      : "nexium_group";
  const channel =
    typeof body?.channel === "string" && body.channel.trim().length > 0
      ? body.channel.trim()
      : "facebook";
  const objective =
    typeof body?.objective === "string" && body.objective.trim().length > 0
      ? body.objective.trim()
      : null;
  let periodDays =
    typeof body?.periodDays === "number" && Number.isFinite(body.periodDays)
      ? body.periodDays
      : 30;
  if (!Number.isFinite(periodDays)) periodDays = 30;
  if (periodDays < 7) periodDays = 7;
  if (periodDays > 365) periodDays = 365;

  const locale =
    typeof body?.locale === "string" && body.locale.trim().length > 0
      ? body.locale.trim()
      : "fr";

  const now = new Date();
  const startDate = new Date(now.getTime() - periodDays * 24 * 60 * 60 * 1000);
  const periodStart = toDateOnlyString(startDate);
  const periodEnd = toDateOnlyString(now);

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    const { data: settingsData } = await supabase.rpc("get_ai_orchestration_settings");

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

    const [
      objectivesRes,
      patternsRes,
      fbOverviewRes,
      objectiveSummaryRes,
      bestTimeRes,
      bestHashtagsRes,
      brandContextRes,
      sourcesRes,
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
      supabase.rpc("get_facebook_post_performance_overview", { p_days: periodDays }),
      supabase.rpc("get_objective_performance_summary", { p_days: periodDays }),
      supabase.rpc("get_best_facebook_time_for_topic", {
        p_topic: null,
        p_days: periodDays,
        p_limit: 8,
      }),
      supabase.rpc("get_best_hashtags_for_topic", {
        p_topic: null,
        p_limit: 50,
        p_days: periodDays,
      }),
      supabase
        .from("studio_brand_context")
        .select("content")
        .eq("brand_key", brandKey)
        .eq("locale", locale)
        .limit(1),
      supabase
        .from("studio_external_knowledge_sources")
        .select("id, name, domain, priority, is_official, tags")
        .eq("is_active", true)
        .order("priority", { ascending: true }),
    ]);

    const objectives = (objectivesRes.data ?? []) as any[];
    const patterns = (patternsRes.data ?? []) as any[];
    const facebookOverview = (fbOverviewRes.data ?? []) as any[];
    const objectivePerformance = (objectiveSummaryRes.data ?? []) as any[];
    const bestTimeSlots = (bestTimeRes.data ?? []) as any[];
    const bestHashtags = (bestHashtagsRes.data ?? []) as any[];

    const brandContextRow =
      ((brandContextRes.data as any[] | null | undefined) ?? [])[0] as
        | { content?: unknown }
        | undefined;
    const brandContext =
      (brandContextRow?.content as Record<string, unknown> | null | undefined) ?? null;

    const sources = (sourcesRes.data ?? []) as ExternalSourceRow[];

    const officialSources = sources.filter((s) => s.is_official === true);
    const trustedSources = sources.filter(
      (s) => s.is_official !== true && (s.priority ?? 3) <= 2,
    );
    const otherSources = sources.filter((s) => !officialSources.includes(s) && !trustedSources.includes(s));

    async function loadExternalGroup(sourceGroup: ExternalSourceRow[], limitDocs: number) {
      if (sourceGroup.length === 0) {
        return [] as any[];
      }

      const sourceIds = sourceGroup.map((s) => s.id);

      const { data: linkRows, error: linkError } = await supabase
        .from("studio_external_knowledge_docs")
        .select(
          "id, source_id, document_id, url, topic, language, importance_score",
        )
        .in("source_id", sourceIds)
        .order("importance_score", { ascending: false })
        .limit(limitDocs);

      if (linkError) {
        console.error("Error loading external knowledge docs", linkError);
        return [] as any[];
      }

      const links = (linkRows ?? []) as ExternalDocLinkRow[];
      if (links.length === 0) return [] as any[];

      const docIdSet = new Set<string>();
      for (const l of links) {
        if (l.document_id) docIdSet.add(l.document_id);
      }
      const docIds = Array.from(docIdSet.values());
      if (docIds.length === 0) return [] as any[];

      const { data: docsRows, error: docsError } = await supabase
        .from("documents")
        .select("id, title, content, metadata")
        .in("id", docIds);

      if (docsError) {
        console.error("Error loading documents for external knowledge", docsError);
        return [] as any[];
      }

      const docs = (docsRows ?? []) as DocumentRow[];
      const docsById = new Map<string, DocumentRow>();
      for (const d of docs) {
        docsById.set(d.id, d);
      }

      const bySourceId = new Map<string, ExternalSourceRow>();
      for (const s of sourceGroup) {
        bySourceId.set(s.id, s);
      }

      const result: any[] = [];
      for (const l of links) {
        const doc = docsById.get(l.document_id);
        const src = bySourceId.get(l.source_id);
        if (!doc || !src) continue;
        const snippet = buildSnippet(doc.content, 800);
        result.push({
          source_name: src.name,
          domain: src.domain,
          source_priority: src.priority ?? null,
          is_official: src.is_official === true,
          source_tags: src.tags ?? [],
          topic: l.topic,
          url: l.url,
          language: l.language,
          title: doc.title ?? "",
          snippet,
        });
      }

      return result;
    }

    const [officialDocs, trustedDocs, otherDocs] = await Promise.all([
      loadExternalGroup(officialSources, 15),
      loadExternalGroup(trustedSources, 15),
      loadExternalGroup(otherSources, 10),
    ]);

    const internalStats = {
      period_days: periodDays,
      period_start: periodStart,
      period_end: periodEnd,
      facebook_post_performance_overview: facebookOverview,
      objective_performance_summary: objectivePerformance,
      best_time_slots: bestTimeSlots,
      best_hashtags: bestHashtags,
      objectives,
      performance_patterns: patterns,
    };

    const { data: existingRows, error: existingError } = await supabase
      .from("studio_marketing_benchmarks")
      .select(
        "id, brand_key, channel, objective, period_start, period_end",
      )
      .eq("brand_key", brandKey)
      .eq("channel", channel)
      .eq("period_start", periodStart)
      .eq("period_end", periodEnd)
      .limit(1);

    if (existingError) {
      console.error("Error checking existing marketing benchmark", existingError);
    }

    const existing = (existingRows ?? [])[0] as
      | { id: string }
      | undefined;

    let benchmarkId: string | null = existing?.id ?? null;

    const baseRow: Record<string, unknown> = {
      brand_key: brandKey,
      channel,
      objective,
      period_start: periodStart,
      period_end: periodEnd,
      internal_stats: internalStats,
      external_official: officialDocs,
      external_trusted: trustedDocs,
      external_other: otherDocs,
    };

    if (!benchmarkId) {
      const { data: insertedRows, error: insertError } = await supabase
        .from("studio_marketing_benchmarks")
        .insert(baseRow)
        .select("id")
        .limit(1);

      if (insertError) {
        console.error("Error inserting marketing benchmark row", insertError);
      } else {
        const row = (insertedRows ?? [])[0] as { id: string } | undefined;
        benchmarkId = row?.id ?? null;
      }
    } else {
      const { error: updateError } = await supabase
        .from("studio_marketing_benchmarks")
        .update(baseRow)
        .eq("id", benchmarkId);

      if (updateError) {
        console.error("Error updating marketing benchmark row", updateError);
      }
    }

    let finalRecommendations: any = [];

    if (openrouterEnabled) {
      const contextPayload = {
        brand_key: brandKey,
        channel,
        objective,
        locale,
        period_days: periodDays,
        period_start: periodStart,
        period_end: periodEnd,
        internal_stats: internalStats,
        external_official: officialDocs,
        external_trusted: trustedDocs,
        external_other: otherDocs,
        brand_context: brandContext,
        focus_activity: typeof body?.focusActivity === "string" && body.focusActivity.trim().length > 0 ? body.focusActivity.trim() : null,
      };

      const systemPrompt =
        "Tu es un analyste marketing senior du Studio Nexiom AI. " +
        "Tu dois analyser en priorité les statistiques internes Facebook (ce qui marche réellement sur la page Nexiom) " +
        "et seulement ensuite utiliser les recommandations officielles Meta et les articles de plateformes reconnues (Hootsuite, HubSpot, etc.). " +
        "Tu reçois un JSON avec des statistiques internes (internal_stats) et des extraits de sources externes classés en trois groupes : \"external_official\" (sources officielles Meta/Facebook), \"external_trusted\" (Hootsuite, HubSpot, etc.) et \"external_other\" (autres). " +
        "CRITIQUE : Si le champ 'focus_activity' est présent et non nul dans le contexte, il décrit l'activité PRIORITAIRE de la mission marketing en cours (par exemple 'cours d'appui', 'travaux dirigés', 'formation spécifique'). " +
        "Dans ce cas, TOUTE ta stratégie (créneaux, formats, hashtags, angles de contenu, tone, CTA) doit être EXCLUSIVEMENT orientée vers cette activité spécifique. " +
        "Tu NE DOIS PAS proposer de stratégie générique sur le courtage académique ou la plateforme Academia si 'focus_activity' est défini. " +
        "Chaque élément de ta stratégie doit mentionner explicitement cette activité. " +
        "Tu dois produire un objet JSON structuré qui propose une stratégie de publication Facebook adaptée à Nexiom Group pour la période considérée. " +
        "Les statistiques internes et le contexte Nexiom ont toujours la priorité. Les sources externes doivent être utilisées pour compléter ou ajuster, jamais pour contredire frontalement les données internes. " +
        "Réponds STRICTEMENT avec un objet JSON sans texte autour, suivant ce schéma :\n" +
        "{\n" +
        "  \"summary\": \"résumé court de la situation et de la stratégie recommandée\",\n" +
        "  \"posting_time_strategy\": {\n" +
        "    \"best_slots\": [\"description des meilleurs créneaux (jour/heure)\"],\n" +
        "    \"notes\": [\"remarques basées sur les stats internes\"]\n" +
        "  },\n" +
        "  \"format_strategy\": {\n" +
        "    \"recommended_formats\": [\"text|image|video\"],\n" +
        "    \"notes\": [\"explication courte\"]\n" +
        "  },\n" +
        "  \"hashtag_strategy\": {\n" +
        "    \"recommended_hashtags\": [\"#hashtag1\", \"#hashtag2\"],\n" +
        "    \"max_per_post\": 5,\n" +
        "    \"notes\": [\"comment utiliser les hashtags\"]\n" +
        "  },\n" +
        "  \"content_strategy\": {\n" +
        "    \"angles\": [\"angles de contenu recommandés\"],\n" +
        "    \"tone\": \"proposé pour le ton (ex: pédagogique, rassurant)\",\n" +
        "    \"call_to_actions\": [\"CTA recommandés\"]\n" +
        "  },\n" +
        "  \"notes\": [\"liste de remarques ou garde-fous importants\"]\n" +
        "}\n" +
        "Le JSON doit être valide et directement parsable. N'ajoute JAMAIS de texte avant ou après l'objet JSON.";

      const userContent =
        "Voici le contexte JSON (internal_stats + external_official + external_trusted + external_other + brand_context) :\n" +
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
        console.error("OpenRouter error in marketing-benchmark", {
          status: resp.status,
          bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
        });
      } else {
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

        if (replyText) {
          try {
            const trimmed = replyText.trim();
            finalRecommendations = JSON.parse(trimmed);
          } catch (e) {
            console.error("Failed to parse marketing-benchmark JSON", e, replyText);
          }
        }
      }
    }

    if (benchmarkId) {
      const { error: updateFinalError } = await supabase
        .from("studio_marketing_benchmarks")
        .update({ final_recommendations: finalRecommendations })
        .eq("id", benchmarkId);

      if (updateFinalError) {
        console.error("Error updating final_recommendations on marketing benchmark", updateFinalError);
      }
    }

    const responseBody = {
      brand_key: brandKey,
      channel,
      objective,
      period_start: periodStart,
      period_end: periodEnd,
      benchmark_id: benchmarkId,
      internal_stats: internalStats,
      external_official: officialDocs,
      external_trusted: trustedDocs,
      external_other: otherDocs,
      final_recommendations: finalRecommendations,
    };

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in marketing-benchmark", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
