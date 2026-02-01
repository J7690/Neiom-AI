import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type SourceConfig = {
  name: string;
  domain: string;
  priority: number;
  isOfficial: boolean;
  tags: string[];
  locale: string;
  topic: string;
  urls: string[];
};

type WebSearchQueryConfig = {
  label: string;
  provider: string;
  query: string;
  topic: string;
  locale: string;
  domain: string;
  priority: number;
  isOfficial: boolean;
  tags: string[];
  maxResults: number;
};

const DEFAULT_SOURCES: SourceConfig[] = [
  {
    name: "Meta for Business – News Feed basics",
    domain: "facebook.com",
    priority: 1,
    isOfficial: true,
    tags: ["meta", "facebook", "algorithm", "news_feed"],
    locale: "en",
    topic: "algorithm_basics",
    urls: [
      "https://www.facebook.com/business/help/1565517716828074",
    ],
  },
  {
    name: "Meta for Business – Get more engagement",
    domain: "facebook.com",
    priority: 1,
    isOfficial: true,
    tags: ["meta", "facebook", "engagement", "best_practices"],
    locale: "en",
    topic: "engagement_best_practices",
    urls: [
      "https://www.facebook.com/business/help/735720159834389",
    ],
  },
  {
    name: "Hootsuite – Best time to post on Facebook",
    domain: "hootsuite.com",
    priority: 2,
    isOfficial: false,
    tags: ["hootsuite", "facebook", "timing", "scheduling"],
    locale: "en",
    topic: "posting_time",
    urls: [
      "https://blog.hootsuite.com/best-time-to-post-on-facebook/",
    ],
  },
  {
    name: "HubSpot – Facebook marketing strategy",
    domain: "hubspot.com",
    priority: 2,
    isOfficial: false,
    tags: ["hubspot", "facebook", "strategy"],
    locale: "en",
    topic: "strategy",
    urls: [
      "https://blog.hubspot.com/marketing/facebook-marketing",
    ],
  },
];

const DEFAULT_WEB_SEARCH_QUERIES: WebSearchQueryConfig[] = [
  {
    label: "Meta for Business \u2013 News Feed / Algorithme",
    provider: "serpapi",
    query:
      "\"Facebook News Feed\" algorithm best practices site:facebook.com/business OR site:facebook.com/help",
    topic: "algorithm_basics",
    locale: "en",
    domain: "facebook.com",
    priority: 1,
    isOfficial: true,
    tags: ["meta", "facebook", "algorithm", "news_feed", "official"],
    maxResults: 5,
  },
  {
    label: "Meta for Business \u2013 Engagement",
    provider: "serpapi",
    query:
      "facebook page engagement tips site:facebook.com/business OR site:facebook.com/help",
    topic: "engagement_best_practices",
    locale: "en",
    domain: "facebook.com",
    priority: 1,
    isOfficial: true,
    tags: ["meta", "facebook", "engagement", "best_practices", "official"],
    maxResults: 5,
  },
  {
    label: "Hootsuite \u2013 Best time to post on Facebook",
    provider: "serpapi",
    query:
      "\"best time to post on facebook\" site:hootsuite.com OR site:blog.hootsuite.com",
    topic: "posting_time",
    locale: "en",
    domain: "hootsuite.com",
    priority: 2,
    isOfficial: false,
    tags: ["hootsuite", "facebook", "timing", "scheduling", "benchmark"],
    maxResults: 5,
  },
  {
    label: "Hootsuite – Best time to post on Facebook (Africa/West Africa)",
    provider: "serpapi",
    query:
      "\"best time to post on facebook\" (Africa OR \"West Africa\") site:hootsuite.com OR site:blog.hootsuite.com",
    topic: "posting_time_africa",
    locale: "en",
    domain: "hootsuite.com",
    priority: 2,
    isOfficial: false,
    tags: [
      "hootsuite",
      "facebook",
      "timing",
      "scheduling",
      "benchmark",
      "africa",
      "west_africa",
    ],
    maxResults: 5,
  },
  {
    label: "HubSpot \u2013 Facebook marketing strategy",
    provider: "serpapi",
    query:
      "\"facebook marketing\" strategy site:hubspot.com OR site:blog.hubspot.com",
    topic: "strategy",
    locale: "en",
    domain: "hubspot.com",
    priority: 2,
    isOfficial: false,
    tags: ["hubspot", "facebook", "strategy", "benchmark"],
    maxResults: 5,
  },
];

function extractTitleAndText(html: string, fallbackTitle: string) {
  const titleMatch = html.match(/<title[^>]*>([^<]*)<\/title>/i);
  const title = titleMatch && titleMatch[1] ? titleMatch[1].trim() : fallbackTitle;

  let text = html.replace(/<script[\s\S]*?<\/script>/gi, " ");
  text = text.replace(/<style[\s\S]*?<\/style>/gi, " ");
  text = text.replace(/<!--([\s\S]*?)-->/g, " ");
  text = text.replace(/<[^>]+>/g, " ");
  text = text.replace(/\s+/g, " ").trim();

  if (text.length > 60000) {
    text = text.slice(0, 60000);
  }

  return { title, text };
}

async function runDefaultWebSearchQueries(
  endpoint: string,
  apiKey: string,
): Promise<SourceConfig[]> {
  const collectedSources: SourceConfig[] = [];

  for (const cfg of DEFAULT_WEB_SEARCH_QUERIES) {
    // Le provider est pour l'instant uniquement "serpapi". Si un autre provider
    // est configuré plus tard, cette fonction pourra être dupliquée/adaptée.
    if (cfg.provider !== "serpapi") continue;

    try {
      const params = new URLSearchParams({
        engine: "google",
        q: cfg.query,
        num: String(cfg.maxResults ?? 5),
        api_key: apiKey,
        hl: cfg.locale ?? "en",
      });

      const resp = await fetch(`${endpoint}?${params.toString()}`);
      if (!resp.ok) {
        const text = await resp.text();
        console.error("Web search request failed", {
          label: cfg.label,
          status: resp.status,
          bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
        });
        continue;
      }

      const json: any = await resp.json();
      const results: any[] = Array.isArray(json?.organic_results)
        ? json.organic_results
        : [];

      const urls: string[] = [];
      const seen = new Set<string>();

      for (const r of results) {
        const link = typeof r?.link === "string" ? r.link.trim() : "";
        if (!link) continue;

        try {
          const u = new URL(link);
          if (!u.hostname.includes(cfg.domain)) {
            // On reste strict sur le domaine pour respecter la hiérarchie de sources.
            continue;
          }
        } catch (_) {
          continue;
        }

        const lower = link.toLowerCase();
        if (seen.has(lower)) continue;
        seen.add(lower);
        urls.push(link);
      }

      if (urls.length === 0) {
        continue;
      }

      collectedSources.push({
        name: cfg.label,
        domain: cfg.domain,
        priority: cfg.priority,
        isOfficial: cfg.isOfficial,
        tags: cfg.tags,
        locale: cfg.locale,
        topic: cfg.topic,
        urls,
      });
    } catch (e) {
      console.error("Error during default web search query", { label: cfg.label, error: e });
    }
  }

  return collectedSources;
}

async function runTopicWebSearchQueries(
  topics: string[],
  endpoint: string,
  apiKey: string,
): Promise<SourceConfig[]> {
  const collected: SourceConfig[] = [];

  for (const raw of topics) {
    if (typeof raw !== "string") continue;
    const topic = raw.trim();
    if (!topic) continue;

    const configs: WebSearchQueryConfig[] = [
      {
        label: `Facebook marketing – ${topic} (Hootsuite/HubSpot)`,
        provider: "serpapi",
        query:
          `"facebook marketing" "${topic}" site:hootsuite.com OR site:blog.hootsuite.com OR site:hubspot.com OR site:blog.hubspot.com`,
        topic,
        locale: "fr",
        domain: "hootsuite.com",
        priority: 2,
        isOfficial: false,
        tags: [
          "topic",
          topic,
          "facebook",
          "strategy",
          "benchmark",
        ],
        maxResults: 5,
      },
      {
        label: `Exemples de posts Facebook – ${topic}`,
        provider: "serpapi",
        query:
          `"${topic}" "facebook" "post" site:facebook.com OR site:facebook.com/business`,
        topic,
        locale: "fr",
        domain: "facebook.com",
        priority: 3,
        isOfficial: false,
        tags: [
          "topic",
          topic,
          "facebook",
          "examples",
        ],
        maxResults: 5,
      },
    ];

    for (const cfg of configs) {
      if (cfg.provider !== "serpapi") continue;

      try {
        const params = new URLSearchParams({
          engine: "google",
          q: cfg.query,
          num: String(cfg.maxResults ?? 5),
          api_key: apiKey,
          hl: cfg.locale ?? "fr",
        });

        const resp = await fetch(`${endpoint}?${params.toString()}`);
        if (!resp.ok) {
          const text = await resp.text();
          console.error("Topic web search request failed", {
            label: cfg.label,
            status: resp.status,
            bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
          });
          continue;
        }

        const json: any = await resp.json();
        const results: any[] = Array.isArray(json?.organic_results)
          ? json.organic_results
          : [];

        const urls: string[] = [];
        const seen = new Set<string>();

        for (const r of results) {
          const link = typeof r?.link === "string" ? r.link.trim() : "";
          if (!link) continue;

          try {
            const u = new URL(link);
            if (!u.hostname.includes(cfg.domain)) {
              continue;
            }
          } catch (_) {
            continue;
          }

          const lower = link.toLowerCase();
          if (seen.has(lower)) continue;
          seen.add(lower);
          urls.push(link);
        }

        if (urls.length === 0) {
          continue;
        }

        collected.push({
          name: cfg.label,
          domain: cfg.domain,
          priority: cfg.priority,
          isOfficial: cfg.isOfficial,
          tags: cfg.tags,
          locale: cfg.locale,
          topic: cfg.topic,
          urls,
        });
      } catch (e) {
        console.error("Error during topic web search query", { label: cfg.label, error: e });
      }
    }
  }

  return collected;
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
  const webSearchProvider = Deno.env.get("NEXIOM_WEB_SEARCH_PROVIDER") ?? null;
  const webSearchEndpoint =
    Deno.env.get("NEXIOM_WEB_SEARCH_ENDPOINT") ?? "https://serpapi.com/search";
  const webSearchApiKey = Deno.env.get("NEXIOM_WEB_SEARCH_API_KEY") ?? null;

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return new Response(
      JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }),
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

  const useDefaults: boolean = body?.useDefaultSources !== false;
  const useDefaultWebSearch: boolean = body?.useDefaultWebSearch === true;

  const extraSourcesRaw: any[] = Array.isArray(body?.sources) ? body.sources : [];

  const extraSources: SourceConfig[] = extraSourcesRaw
    .map((s) => {
      if (!s) return null;
      const domain = typeof s.domain === "string" ? s.domain.trim() : "";
      const name = typeof s.name === "string" ? s.name.trim() : domain;
      const urls = Array.isArray(s.urls)
        ? s.urls
          .map((u: any) => (typeof u === "string" ? u.trim() : ""))
          .filter((u: string) => u.length > 0)
        : [];
      if (!domain || urls.length === 0) return null;
      const priority = typeof s.priority === "number" && Number.isFinite(s.priority)
        ? s.priority
        : 3;
      const isOfficial = typeof s.isOfficial === "boolean" ? s.isOfficial : false;
      const tags = Array.isArray(s.tags)
        ? s.tags
          .map((t: any) => (typeof t === "string" ? t.trim() : ""))
          .filter((t: string) => t.length > 0)
        : [];
      const locale = typeof s.locale === "string" && s.locale.trim().length > 0
        ? s.locale.trim()
        : "en";
      const topic = typeof s.topic === "string" && s.topic.trim().length > 0
        ? s.topic.trim()
        : "general";
      return { name, domain, priority, isOfficial, tags, locale, topic, urls } as SourceConfig;
    })
    .filter((s): s is SourceConfig => s !== null);

  const sourcesToIngest: SourceConfig[] = [];
  if (useDefaults) {
    sourcesToIngest.push(...DEFAULT_SOURCES);
  }
  if (extraSources.length > 0) {
    sourcesToIngest.push(...extraSources);
  }

  if (
    useDefaultWebSearch &&
    webSearchProvider === "serpapi" &&
    webSearchApiKey &&
    webSearchEndpoint
  ) {
    try {
      const webSources = await runDefaultWebSearchQueries(webSearchEndpoint, webSearchApiKey);
      if (webSources.length > 0) {
        sourcesToIngest.push(...webSources);
      }
    } catch (e) {
      console.error("Error while running default web search ingestion", e);
    }
  }

  const topicListRaw: any[] = Array.isArray(body?.webSearchTopics)
    ? body.webSearchTopics
    : [];
  const topicList: string[] = topicListRaw
    .map((t) => (typeof t === "string" ? t.trim() : ""))
    .filter((t) => t.length > 0);

  if (
    useDefaultWebSearch &&
    webSearchProvider === "serpapi" &&
    webSearchApiKey &&
    webSearchEndpoint &&
    topicList.length > 0
  ) {
    try {
      const topicSources = await runTopicWebSearchQueries(
        topicList,
        webSearchEndpoint,
        webSearchApiKey,
      );
      if (topicSources.length > 0) {
        sourcesToIngest.push(...topicSources);
      }
    } catch (e) {
      console.error("Error while running topic web search ingestion", e);
    }
  }

  if (sourcesToIngest.length === 0) {
    return new Response(
      JSON.stringify({ error: "No sources provided and useDefaultSources=false" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  const uniqueSourcesKey = (s: SourceConfig) => `${s.domain}::${s.name}`;
  const byKey = new Map<string, SourceConfig>();
  for (const s of sourcesToIngest) {
    const key = uniqueSourcesKey(s);
    if (!byKey.has(key)) {
      byKey.set(key, { ...s });
    } else {
      const existing = byKey.get(key)!;
      const mergedUrls = [...existing.urls, ...s.urls];
      const urlSet = new Set<string>();
      existing.urls = mergedUrls.filter((u) => {
        const lu = u.toLowerCase();
        if (urlSet.has(lu)) return false;
        urlSet.add(lu);
        return true;
      });
      existing.tags = Array.from(new Set([...(existing.tags ?? []), ...(s.tags ?? [])]));
      existing.priority = Math.min(existing.priority, s.priority);
      existing.isOfficial = existing.isOfficial || s.isOfficial;
    }
  }

  const finalSources = Array.from(byKey.values()).filter((s) => s.urls.length > 0);

  if (finalSources.length === 0) {
    return new Response(
      JSON.stringify({ error: "No URLs to ingest after normalization" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const results: any[] = [];
  let totalDocs = 0;
  let totalErrors = 0;

  for (const src of finalSources) {
    let sourceId: string | null = null;

    try {
      const { data: existingRows, error: selectError } = await supabase
        .from("studio_external_knowledge_sources")
        .select("id, priority, is_official, tags")
        .eq("domain", src.domain)
        .eq("name", src.name)
        .limit(1);

      if (selectError) {
        console.error("Error selecting external knowledge source", src, selectError);
      }

      const existing = (existingRows ?? [])[0] as
        | { id: string; priority?: number | null; is_official?: boolean | null; tags?: string[] | null }
        | undefined;

      if (existing) {
        sourceId = existing.id;
        const newTags = Array.from(new Set([...(existing.tags ?? []), ...(src.tags ?? [])]));
        const { error: updateError } = await supabase
          .from("studio_external_knowledge_sources")
          .update({
            priority: Math.min(existing.priority ?? src.priority, src.priority),
            is_official: existing.is_official ?? src.isOfficial,
            tags: newTags,
            is_active: true,
          })
          .eq("id", existing.id);
        if (updateError) {
          console.error("Error updating external knowledge source", src, updateError);
        }
      } else {
        const { data: insertedRows, error: insertError } = await supabase
          .from("studio_external_knowledge_sources")
          .insert({
            name: src.name,
            domain: src.domain,
            priority: src.priority,
            is_official: src.isOfficial,
            tags: src.tags,
            is_active: true,
          })
          .select("id")
          .limit(1);

        if (insertError) {
          console.error("Error inserting external knowledge source", src, insertError);
        } else {
          const row = (insertedRows ?? [])[0] as { id: string } | undefined;
          sourceId = row?.id ?? null;
        }
      }
    } catch (e) {
      console.error("Unexpected error handling source row", src, e);
    }

    const perSource = {
      name: src.name,
      domain: src.domain,
      topic: src.topic,
      locale: src.locale,
      urls: src.urls,
      insertedDocuments: 0,
      failedUrls: 0,
    };

    if (!sourceId) {
      totalErrors += src.urls.length;
      perSource.failedUrls = src.urls.length;
      results.push(perSource);
      continue;
    }

    for (const url of src.urls) {
      try {
        const resp = await fetch(url, { method: "GET" });
        if (!resp.ok) {
          console.error("Failed to fetch external URL", { url, status: resp.status });
          perSource.failedUrls += 1;
          totalErrors += 1;
          continue;
        }
        const html = await resp.text();
        const { title, text } = extractTitleAndText(html, url);

        if (!text || text.length === 0) {
          console.warn("Empty text after HTML extraction", { url });
          perSource.failedUrls += 1;
          totalErrors += 1;
          continue;
        }

        const { data: docId, error: ingestError } = await supabase.rpc("ingest_document", {
          p_source: src.name,
          p_title: title,
          p_locale: src.locale,
          p_content: text,
          p_metadata: {
            url,
            domain: src.domain,
            topic: src.topic,
            tags: src.tags,
            priority: src.priority,
            is_official: src.isOfficial,
          },
        });

        if ( ingestError || !docId) {
          console.error("Error ingesting document into knowledge base", {
            url,
            error: ingestError,
          });
          perSource.failedUrls += 1;
          totalErrors += 1;
          continue;
        }

        const { error: linkError } = await supabase
          .from("studio_external_knowledge_docs")
          .insert({
            source_id: sourceId,
            document_id: docId as string,
            url,
            topic: src.topic,
            language: src.locale,
            importance_score: src.priority,
          });

        if (linkError) {
          console.error("Error inserting external knowledge doc link", {
            url,
            error: linkError,
          });
          perSource.failedUrls += 1;
          totalErrors += 1;
          continue;
        }

        perSource.insertedDocuments += 1;
        totalDocs += 1;
      } catch (e) {
        console.error("Unexpected error ingesting external URL", { url, error: e });
        perSource.failedUrls += 1;
        totalErrors += 1;
      }
    }

    results.push(perSource);
  }

  const responseBody = {
    success: true,
    total_inserted_documents: totalDocs,
    total_errors: totalErrors,
    sources: results,
  };

  return new Response(JSON.stringify(responseBody), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
