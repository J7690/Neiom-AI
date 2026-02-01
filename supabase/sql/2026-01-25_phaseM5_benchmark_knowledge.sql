-- Phase M5 – Benchmark & base de connaissances marketing (NON DESTRUCTIF)
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-25_phaseM5_benchmark_knowledge.sql

-- 1) Sources externes de connaissance marketing (Meta, Hootsuite, HubSpot, instituts, etc.)
create table if not exists public.studio_external_knowledge_sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  domain text not null,
  priority integer not null default 2 check (priority >= 1 and priority <= 5),
  is_official boolean not null default false,
  tags text[] not null default '{}'::text[],
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists studio_external_knowledge_sources_domain_idx
  on public.studio_external_knowledge_sources(domain);

create index if not exists studio_external_knowledge_sources_priority_idx
  on public.studio_external_knowledge_sources(priority);

create index if not exists studio_external_knowledge_sources_is_active_idx
  on public.studio_external_knowledge_sources(is_active);


-- 2) Liaison entre documents internes (public.documents) et sources externes
--    Cette table permet de tracer quels documents proviennent de quelles sources/domaines
--    et sous quel angle marketing ils ont été ingérés.
create table if not exists public.studio_external_knowledge_docs (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references public.studio_external_knowledge_sources(id) on delete cascade,
  document_id uuid not null,
  url text,
  topic text,
  language text,
  importance_score numeric,
  created_at timestamptz not null default now()
);

create index if not exists studio_external_knowledge_docs_source_id_idx
  on public.studio_external_knowledge_docs(source_id);

create index if not exists studio_external_knowledge_docs_document_id_idx
  on public.studio_external_knowledge_docs(document_id);

create index if not exists studio_external_knowledge_docs_topic_idx
  on public.studio_external_knowledge_docs(topic);


-- 3) Cache de benchmarks marketing (mélange stats internes + patterns externes)
create table if not exists public.studio_marketing_benchmarks (
  id uuid primary key default gen_random_uuid(),
  brand_key text not null,
  channel text not null,
  objective text,
  period_start date not null,
  period_end date not null,
  internal_stats jsonb not null default '{}'::jsonb,
  external_official jsonb not null default '[]'::jsonb,
  external_trusted jsonb not null default '[]'::jsonb,
  external_other jsonb not null default '[]'::jsonb,
  final_recommendations jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists studio_marketing_benchmarks_brand_channel_period_idx
  on public.studio_marketing_benchmarks(brand_key, channel, period_start, period_end);


-- 4) RLS & permissions de base (alignées sur les autres tables studio_*)
alter table public.studio_external_knowledge_sources enable row level security;
alter table public.studio_external_knowledge_docs enable row level security;
alter table public.studio_marketing_benchmarks enable row level security;

create policy "Users can view external knowledge sources" on public.studio_external_knowledge_sources
  for select using (true);

create policy "Users can manage external knowledge sources" on public.studio_external_knowledge_sources
  for all using (true);

create policy "Users can view external knowledge docs" on public.studio_external_knowledge_docs
  for select using (true);

create policy "Users can manage external knowledge docs" on public.studio_external_knowledge_docs
  for all using (true);

create policy "Users can view marketing benchmarks" on public.studio_marketing_benchmarks
  for select using (true);

create policy "Users can manage marketing benchmarks" on public.studio_marketing_benchmarks
  for all using (true);

grant select, insert, update, delete on public.studio_external_knowledge_sources to authenticated, anon;
grant select, insert, update, delete on public.studio_external_knowledge_docs to authenticated, anon;
grant select, insert, update, delete on public.studio_marketing_benchmarks to authenticated, anon;
