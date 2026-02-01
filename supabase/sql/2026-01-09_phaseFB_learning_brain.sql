-- Phase FB – Orchestration d'apprentissage et historique des analyses
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseFB_learning_brain.sql

-- 1) RPC : enregistrer une exécution d'analyse du cerveau marketing
create or replace function public.record_studio_analysis_run(
  p_source text,
  p_analysis_from timestamptz default null,
  p_analysis_to timestamptz default null,
  p_input_metrics jsonb default '{}'::jsonb,
  p_output_summary jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare
  v_id uuid;
begin
  insert into public.studio_analysis_runs (
    source,
    analysis_from,
    analysis_to,
    input_metrics,
    output_summary
  ) values (
    coalesce(p_source, 'unknown'),
    p_analysis_from,
    p_analysis_to,
    coalesce(p_input_metrics, '{}'::jsonb),
    coalesce(p_output_summary, '{}'::jsonb)
  ) returning id into v_id;

  return v_id;
end;
$$;

grant execute on function public.record_studio_analysis_run(text, timestamptz, timestamptz, jsonb, jsonb) to authenticated, anon;

-- 2) RPC : récupérer les dernières analyses enregistrées
create or replace function public.get_recent_studio_analysis_runs(
  p_limit integer default 10
)
returns table (
  id uuid,
  source text,
  analysis_from timestamptz,
  analysis_to timestamptz,
  input_metrics jsonb,
  output_summary jsonb,
  created_at timestamptz
)
language sql
security definer
set search_path = public as
$$
  select
    ar.id,
    ar.source,
    ar.analysis_from,
    ar.analysis_to,
    ar.input_metrics,
    ar.output_summary,
    ar.created_at
  from public.studio_analysis_runs ar
  order by ar.created_at desc
  limit p_limit;
$$;

grant execute on function public.get_recent_studio_analysis_runs(integer) to authenticated, anon;
