-- Phase M2 – Enrichissement des objectifs marketing et création des missions
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseM2_update_objectives_and_create_missions.sql

-- 1) Enrichir la table studio_marketing_objectives avec des dimensions structurées
alter table public.studio_marketing_objectives
  add column if not exists dimension text
    check (dimension in ('awareness', 'engagement', 'conversion', 'community')),
  add column if not exists primary_metric text
    check (primary_metric in ('followers', 'views', 'reach', 'clicks', 'leads', 'signups', 'conversions')),
  add column if not exists default_channels text[]
    default array['facebook']::text[],
  add column if not exists priority text
    default 'medium'
    check (priority in ('low', 'medium', 'high'));

-- 2) Créer la table des missions marketing opérationnelles
create table if not exists public.studio_marketing_missions (
  id uuid primary key default gen_random_uuid(),
  objective_id uuid references public.studio_marketing_objectives(id) on delete cascade,
  source text not null default 'admin' check (source in ('admin', 'ai')),
  channel text not null,
  metric text not null,
  activity_ref text,
  current_baseline numeric default 0,
  target_value numeric not null,
  unit text default 'count',
  start_date date default current_date,
  end_date date,
  status text not null default 'planned'
    check (status in ('planned', 'active', 'paused', 'completed', 'cancelled')),
  strategy jsonb default '{}'::jsonb,
  created_by text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3) Index pour optimiser les requêtes sur les missions
create index if not exists studio_marketing_missions_objective_idx
  on public.studio_marketing_missions(objective_id);

create index if not exists studio_marketing_missions_status_idx
  on public.studio_marketing_missions(status);

create index if not exists studio_marketing_missions_channel_metric_idx
  on public.studio_marketing_missions(channel, metric);

-- 4) Trigger updated_at pour les missions (réutilise public.set_updated_at())
drop trigger if exists set_studio_marketing_missions_updated_at
  on public.studio_marketing_missions;

create trigger set_studio_marketing_missions_updated_at
  before update on public.studio_marketing_missions
  for each row
  execute function public.set_updated_at();

-- 5) Activer RLS et politiques pour les missions
alter table public.studio_marketing_missions enable row level security;

drop policy if exists "Users can view marketing missions" on public.studio_marketing_missions;
create policy "Users can view marketing missions"
  on public.studio_marketing_missions
  for select
  using (true);

drop policy if exists "Users can manage marketing missions" on public.studio_marketing_missions;
create policy "Users can manage marketing missions"
  on public.studio_marketing_missions
  for all
  using (true);

-- 6) Permissions
grant select, insert, update, delete on public.studio_marketing_missions
  to authenticated, anon;
