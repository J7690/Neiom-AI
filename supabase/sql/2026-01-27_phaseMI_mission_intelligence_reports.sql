-- Phase 2 – Mission Intelligence Reports
-- Création de la table de rapports d'intelligence par mission
-- et du RPC get_latest_mission_intelligence_report(mission_id uuid).

create table if not exists public.studio_mission_intelligence_reports (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.studio_marketing_missions(id) on delete cascade,
  objective text,
  channel text,
  report jsonb not null,
  created_at timestamptz default now()
);

create index if not exists studio_mission_intel_reports_mission_created_idx
  on public.studio_mission_intelligence_reports(mission_id, created_at desc);

create or replace function public.get_latest_mission_intelligence_report(p_mission_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select report
  from public.studio_mission_intelligence_reports
  where mission_id = p_mission_id
  order by created_at desc
  limit 1;
$$;

-- Restriction d'accès : appel réservé aux contextes service_role / Edge Functions.
revoke all on function public.get_latest_mission_intelligence_report(uuid) from public;
revoke all on function public.get_latest_mission_intelligence_report(uuid) from anon;
revoke all on function public.get_latest_mission_intelligence_report(uuid) from authenticated;
