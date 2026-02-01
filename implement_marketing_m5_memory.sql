-- Phase M5 – Mémoire stratégique par post
-- Table post_strategy_outcomes + RPC pour lister les leçons apprises

create table if not exists public.post_strategy_outcomes (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  objective_at_publication text,
  strategic_role text,
  recommendation_id uuid references public.studio_marketing_recommendations(id) on delete set null,
  verdict text not null default 'neutral' check (verdict in ('success','neutral','failure')),
  outcome_metrics jsonb not null default '{}'::jsonb,
  context_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists post_strategy_outcomes_post_id_idx on public.post_strategy_outcomes(post_id);
create index if not exists post_strategy_outcomes_verdict_idx on public.post_strategy_outcomes(verdict);
create index if not exists post_strategy_outcomes_objective_idx on public.post_strategy_outcomes(objective_at_publication);

alter table public.post_strategy_outcomes enable row level security;

DO $$
BEGIN
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'post_strategy_outcomes'
      and policyname = 'post_strategy_outcomes_select_all'
  ) then
    create policy post_strategy_outcomes_select_all
      on public.post_strategy_outcomes for select
      to anon, authenticated
      using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'post_strategy_outcomes'
      and policyname = 'post_strategy_outcomes_manage_all'
  ) then
    create policy post_strategy_outcomes_manage_all
      on public.post_strategy_outcomes for all
      to authenticated
      using (true) with check (true);
  end if;
END$$;

grant select, insert, update, delete on public.post_strategy_outcomes to authenticated;

create trigger set_post_strategy_outcomes_updated_at
  before update on public.post_strategy_outcomes
  for each row
  execute function public.set_updated_at();

create or replace function public.list_post_strategy_lessons(
  p_objective text default null,
  p_role text default null,
  p_verdict text default null,
  p_limit int default 100
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_lessons jsonb;
begin
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', id::text,
      'post_id', post_id::text,
      'objective_at_publication', objective_at_publication,
      'strategic_role', strategic_role,
      'verdict', verdict,
      'outcome_metrics', outcome_metrics,
      'context_notes', context_notes,
      'created_at', created_at
    )
    order by created_at desc
  ), '[]'::jsonb)
  into v_lessons
  from public.post_strategy_outcomes
  where (p_objective is null or objective_at_publication = p_objective)
    and (p_role is null or strategic_role = p_role)
    and (p_verdict is null or verdict = p_verdict)
  limit p_limit;

  return jsonb_build_object(
    'objective', coalesce(p_objective, 'any'),
    'strategic_role', coalesce(p_role, 'any'),
    'verdict', coalesce(p_verdict, 'any'),
    'lessons', v_lessons
  );
end;
$$;

grant execute on function public.list_post_strategy_lessons(text,text,text,int) to anon, authenticated;
