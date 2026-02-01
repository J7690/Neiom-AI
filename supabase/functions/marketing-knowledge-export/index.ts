import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type ExportRequest = {
  brandKey?: string;
  channel?: string;
  objective?: string;
  periodDays?: number;
  locale?: string;
};

function toDateOnlyString(d: Date): string {
  return d.toISOString().split("T")[0] ?? "";
}

function buildMarkdownExport(args: {
  brandKey: string;
  channel: string;
  objective: string | null;
  locale: string;
  benchmark: any | null;
}): string {
  const { brandKey, channel, objective, locale, benchmark } = args;
  const lines: string[] = [];

  const periodStart = typeof benchmark?.period_start === "string"
    ? benchmark.period_start
    : null;
  const periodEnd = typeof benchmark?.period_end === "string" ? benchmark.period_end : null;

  lines.push(`# Export marketing Nexiom – ${channel.toUpperCase()}`);
  lines.push("");
  lines.push(`- Marque : ${brandKey}`);
  lines.push(`- Objectif principal : ${objective ?? "non spécifié"}`);
  lines.push(`- Locale : ${locale}`);
  if (periodStart && periodEnd) {
    lines.push(`- Période : du ${periodStart} au ${periodEnd}`);
  }
  lines.push("");

  const internalStats = benchmark?.internal_stats ?? null;
  if (internalStats) {
    lines.push("## Statistiques internes Facebook");
    const overview = Array.isArray(internalStats.facebook_post_performance_overview)
      ? internalStats.facebook_post_performance_overview
      : [];
    const objectives = Array.isArray(internalStats.objective_performance_summary)
      ? internalStats.objective_performance_summary
      : [];

    if (overview.length > 0) {
      lines.push("");
      lines.push("### Synthèse performance des posts (aperçu)");
      const first = overview[0];
      const totalPosts = first?.total_posts ?? first?.count ?? null;
      const avgReach = first?.avg_reach ?? null;
      const avgEngagementRate = first?.avg_engagement_rate ?? null;
      if (totalPosts != null) {
        lines.push(`- Nombre de posts pris en compte : ${totalPosts}`);
      }
      if (avgReach != null) {
        lines.push(`- Reach moyen : ${avgReach}`);
      }
      if (avgEngagementRate != null) {
        lines.push(`- Taux d'engagement moyen : ${avgEngagementRate}`);
      }
    }

    if (objectives.length > 0) {
      lines.push("");
      lines.push("### Synthèse par objectif");
      for (let i = 0; i < objectives.length && i < 5; i++) {
        const row = objectives[i];
        const obj = row?.objective ?? row?.objective_key ?? "objectif";
        const progress = row?.progress_percentage ?? row?.progress ?? null;
        const line = progress != null
          ? `- ${obj} : progression ${progress}%`
          : `- ${obj}`;
        lines.push(line);
      }
    }
  }

  const official = Array.isArray(benchmark?.external_official)
    ? benchmark.external_official
    : [];
  const trusted = Array.isArray(benchmark?.external_trusted)
    ? benchmark.external_trusted
    : [];
  const other = Array.isArray(benchmark?.external_other) ? benchmark.external_other : [];

  function pushSources(title: string, items: any[], maxCount: number) {
    if (!items || items.length === 0) return;
    lines.push("");
    lines.push(title);
    for (let i = 0; i < items.length && i < maxCount; i++) {
      const it = items[i];
      const sourceName = it?.source_name ?? "Source";
      const domain = it?.domain ?? "";
      const topic = it?.topic ?? "";
      const url = it?.url ?? "";
      const snippet = it?.snippet ?? "";
      const meta: string[] = [];
      if (topic) meta.push(`topic=${topic}`);
      if (domain) meta.push(domain);
      const metaStr = meta.length > 0 ? ` (${meta.join(" – ")})` : "";
      if (url) {
        lines.push(`- ${sourceName}${metaStr} : ${url}`);
      } else {
        lines.push(`- ${sourceName}${metaStr}`);
      }
      if (snippet) {
        lines.push(`  > ${snippet.substring(0, 220)}${snippet.length > 220 ? "..." : ""}`);
      }
    }
  }

  pushSources("## Sources officielles Meta / Facebook", official, 8);
  pushSources("## Sources de référence (Hootsuite, HubSpot, etc.)", trusted, 8);
  pushSources("## Autres sources externes", other, 6);

  const recs = benchmark?.final_recommendations ?? null;
  if (recs && typeof recs === "object") {
    lines.push("");
    lines.push("## Synthèse de la stratégie recommandée");
    const summary = recs.summary ?? recs.overview ?? null;
    if (summary) {
      lines.push("");
      lines.push(`**Résumé** : ${summary}`);
    }

    const posting = recs.posting_time_strategy ?? null;
    if (posting) {
      const bestSlots = Array.isArray(posting.best_slots) ? posting.best_slots : [];
      if (bestSlots.length > 0) {
        lines.push("");
        lines.push("### Stratégie de timing");
        for (const s of bestSlots) {
          lines.push(`- ${s}`);
        }
      }
    }

    const formats = recs.format_strategy ?? null;
    if (formats) {
      const fmts = Array.isArray(formats.recommended_formats)
        ? formats.recommended_formats
        : [];
      if (fmts.length > 0) {
        lines.push("");
        lines.push("### Formats recommandés");
        for (const f of fmts) {
          lines.push(`- ${f}`);
        }
      }
    }

    const hashtags = recs.hashtag_strategy ?? null;
    if (hashtags) {
      const list = Array.isArray(hashtags.recommended_hashtags)
        ? hashtags.recommended_hashtags
        : [];
      if (list.length > 0) {
        lines.push("");
        lines.push("### Hashtags recommandés");
        const maxPerPost = hashtags.max_per_post ?? null;
        if (maxPerPost != null) {
          lines.push(`(max. ${maxPerPost} hashtags par post)`);
        }
        const sample = list.slice(0, 20).join(", ");
        lines.push(sample);
      }
    }

    const content = recs.content_strategy ?? null;
    if (content) {
      const angles = Array.isArray(content.angles) ? content.angles : [];
      const tone = content.tone ?? null;
      const ctas = Array.isArray(content.call_to_actions) ? content.call_to_actions : [];
      if (angles.length > 0 || tone || ctas.length > 0) {
        lines.push("");
        lines.push("### Contenu et ton");
        if (angles.length > 0) {
          lines.push("- Angles clés :");
          for (const a of angles) {
            lines.push(`  - ${a}`);
          }
        }
        if (tone) {
          lines.push(`- Ton recommandé : ${tone}`);
        }
        if (ctas.length > 0) {
          lines.push("- Appels à l'action suggérés :");
          for (const c of ctas) {
            lines.push(`  - ${c}`);
          }
        }
      }
    }
  }

  return lines.join("\n");
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

  let body: ExportRequest;
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
    let benchmark: any = null;
    try {
      const supabaseUrlObj = new URL(supabaseUrl);
      const functionsOrigin = supabaseUrlObj.origin.replace(
        ".supabase.co",
        ".functions.supabase.co",
      );
      const benchmarkUrl = `${functionsOrigin}/marketing-benchmark`;

      const benchmarkPayload = {
        brandKey,
        channel,
        objective,
        periodDays,
        locale,
      };

      const benchmarkResp = await fetch(benchmarkUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: supabaseServiceRoleKey,
          Authorization: `Bearer ${supabaseServiceRoleKey}`,
        },
        body: JSON.stringify(benchmarkPayload),
      });

      if (benchmarkResp.ok) {
        benchmark = await benchmarkResp.json();
      } else {
        const text = await benchmarkResp.text();
        console.error("marketing-benchmark call failed in marketing-knowledge-export", {
          status: benchmarkResp.status,
          bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
        });
      }
    } catch (e) {
      console.error("Unexpected error calling marketing-benchmark in marketing-knowledge-export", e);
    }

    let brandContext: any = null;
    try {
      const { data: brandContextRes, error: brandContextError } = await supabase
        .from("studio_brand_context")
        .select("content")
        .eq("brand_key", brandKey)
        .eq("locale", locale)
        .limit(1);

      if (brandContextError) {
        console.error("studio_brand_context error in marketing-knowledge-export", brandContextError);
      } else if (Array.isArray(brandContextRes) && brandContextRes.length > 0) {
        const row = brandContextRes[0] as { content?: unknown };
        if (row && row.content && typeof row.content === "object") {
          brandContext = row.content;
        }
      }
    } catch (e) {
      console.error("Unexpected error loading brand_context in marketing-knowledge-export", e);
    }

    const markdown = buildMarkdownExport({
      brandKey,
      channel,
      objective,
      locale,
      benchmark,
    });

    const responseBody = {
      brand_key: brandKey,
      channel,
      objective,
      locale,
      period_start: periodStart,
      period_end: periodEnd,
      brand_context: brandContext,
      benchmark,
      markdown,
    };

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in marketing-knowledge-export", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
