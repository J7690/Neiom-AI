-- Phase FB – Mémoire et cerveau marketing Nexium Group
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseFB_memory_brain.sql

-- 0) Fonction utilitaire updated_at (sécurisation)
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 1) Table de contexte opérationnel du Studio (mémoire de niveau 2)
create table if not exists public.studio_memory_context (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  period_start timestamptz,
  period_end timestamptz,
  payload jsonb not null default '{}'::jsonb,
  is_active boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Trigger updated_at pour le contexte
drop trigger if exists set_studio_memory_context_updated_at on public.studio_memory_context;
create trigger set_studio_memory_context_updated_at
  before update on public.studio_memory_context
  for each row
  execute function public.set_updated_at();

-- Un seul contexte actif à la fois
create unique index if not exists studio_memory_context_active_idx
  on public.studio_memory_context(is_active)
  where is_active;

-- 2) Table de connaissance Facebook (mémoire de niveau 3)
create table if not exists public.studio_facebook_knowledge (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  objective text check (objective in ('visibility','notoriety','conversion','global')),
  payload jsonb not null,
  source text not null default 'system',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Trigger updated_at pour la connaissance Facebook
drop trigger if exists set_studio_facebook_knowledge_updated_at on public.studio_facebook_knowledge;
create trigger set_studio_facebook_knowledge_updated_at
  before update on public.studio_facebook_knowledge
  for each row
  execute function public.set_updated_at();

create index if not exists studio_facebook_knowledge_category_idx
  on public.studio_facebook_knowledge(category);

create index if not exists studio_facebook_knowledge_objective_idx
  on public.studio_facebook_knowledge(objective);

-- 3) Table d'historique des analyses du cerveau marketing (mémoire de niveau 4, méta)
create table if not exists public.studio_analysis_runs (
  id uuid primary key default gen_random_uuid(),
  source text not null,
  analysis_from timestamptz,
  analysis_to timestamptz,
  input_metrics jsonb not null default '{}'::jsonb,
  output_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz default now()
);

create index if not exists studio_analysis_runs_created_idx
  on public.studio_analysis_runs(created_at desc);

-- 4) RLS & permissions
alter table public.studio_memory_context enable row level security;
alter table public.studio_facebook_knowledge enable row level security;
alter table public.studio_analysis_runs enable row level security;

-- Contexte
drop policy if exists "Users can view studio memory context" on public.studio_memory_context;
create policy "Users can view studio memory context"
  on public.studio_memory_context
  for select
  using (true);

drop policy if exists "Users can manage studio memory context" on public.studio_memory_context;
create policy "Users can manage studio memory context"
  on public.studio_memory_context
  for all
  using (true);

-- Connaissance Facebook
drop policy if exists "Users can view facebook knowledge" on public.studio_facebook_knowledge;
create policy "Users can view facebook knowledge"
  on public.studio_facebook_knowledge
  for select
  using (true);

drop policy if exists "Users can manage facebook knowledge" on public.studio_facebook_knowledge;
create policy "Users can manage facebook knowledge"
  on public.studio_facebook_knowledge
  for all
  using (true);

-- Analyses
drop policy if exists "Users can view analysis runs" on public.studio_analysis_runs;
create policy "Users can view analysis runs"
  on public.studio_analysis_runs
  for select
  using (true);

drop policy if exists "Users can manage analysis runs" on public.studio_analysis_runs;
create policy "Users can manage analysis runs"
  on public.studio_analysis_runs
  for all
  using (true);

grant select, insert, update, delete on public.studio_memory_context to authenticated, anon;
grant select, insert, update, delete on public.studio_facebook_knowledge to authenticated, anon;
grant select, insert, update, delete on public.studio_analysis_runs to authenticated, anon;

-- 5) RPC : définir le contexte actif
create or replace function public.set_active_studio_context(
  p_context_id uuid
)
returns void
language plpgsql
security definer
set search_path = public as
$$
begin
  update public.studio_memory_context
  set is_active = false
  where is_active = true;

  update public.studio_memory_context
  set is_active = true
  where id = p_context_id;
end;
$$;

grant execute on function public.set_active_studio_context(uuid) to authenticated, anon;

-- 6) RPC : récupérer la mémoire consolidée du Studio
create or replace function public.get_studio_memory(
  p_brand_key text default 'nexium_group',
  p_locale text default 'fr',
  p_insights_limit integer default 5
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_brand jsonb;
  v_context jsonb;
  v_knowledge jsonb;
  v_insights jsonb;
begin
  -- Mémoire coeur : identité Nexium depuis studio_brand_context
  select sbc.content
  into v_brand
  from public.studio_brand_context sbc
  where sbc.brand_key = p_brand_key
    and sbc.locale = p_locale
  order by sbc.updated_at desc
  limit 1;

  -- Mémoire contexte : contexte actif du Studio
  select to_jsonb(c)
  into v_context
  from public.studio_memory_context c
  where c.is_active = true
  order by c.updated_at desc
  limit 1;

  -- Connaissance Facebook (règles algorithmiques / bonnes pratiques)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', k.id,
        'category', k.category,
        'objective', k.objective,
        'payload', k.payload,
        'source', k.source
      )
    ),
    '[]'::jsonb
  )
  into v_knowledge
  from public.studio_facebook_knowledge k;

  -- Insights d'apprentissage (studio_learning_insights existant)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', li.id,
        'insight_type', li.insight_type,
        'insight_title', li.insight_title,
        'insight_description', li.insight_description,
        'confidence_score', li.confidence_score,
        'impact_score', li.impact_score,
        'data_source', li.data_source,
        'time_period', li.time_period,
        'actionable_recommendation', li.actionable_recommendation,
        'implemented', li.implemented,
        'created_at', li.created_at
      )
    ),
    '[]'::jsonb
  )
  into v_insights
  from (
    select *
    from public.studio_learning_insights
    order by confidence_score desc nulls last,
             impact_score desc nulls last,
             created_at desc
    limit p_insights_limit
  ) li;

  return jsonb_build_object(
    'brand_core', coalesce(v_brand, '{}'::jsonb),
    'context', coalesce(v_context, '{}'::jsonb),
    'facebook_knowledge', coalesce(v_knowledge, '[]'::jsonb),
    'learning_insights', coalesce(v_insights, '[]'::jsonb)
  );
end;
$$;

grant execute on function public.get_studio_memory(text, text, integer) to authenticated, anon;
