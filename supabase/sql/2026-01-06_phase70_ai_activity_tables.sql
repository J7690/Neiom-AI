-- Phase 6 – Créer tables ai_activity_* et RPCs de reporting (partie 1)
-- Objectif : tables d'agrégats pour le reporting 2h/24h/7j

-- Table pour l'activité IA sur 2 heures
create table public.ai_activity_2h (
  bucket timestamptz primary key,
  messages_received int default 0,
  messages_answered_by_ai int default 0,
  messages_ai_skipped int default 0,
  messages_needs_human int default 0,
  alerts_created int default 0,
  created_at timestamptz default now()
);

-- Table pour l'activité IA quotidienne
create table public.ai_activity_daily (
  bucket date primary key,
  messages_received int default 0,
  messages_answered_by_ai int default 0,
  messages_ai_skipped int default 0,
  messages_needs_human int default 0,
  alerts_created int default 0,
  created_at timestamptz default now()
);

-- Table pour l'activité IA hebdomadaire
create table public.ai_activity_weekly (
  bucket date primary key,
  messages_received int default 0,
  messages_answered_by_ai int default 0,
  messages_ai_skipped int default 0,
  messages_needs_human int default 0,
  alerts_created int default 0,
  created_at timestamptz default now()
);

-- Grants pour les rôles Supabase
grant all on public.ai_activity_2h to anon, authenticated;
grant all on public.ai_activity_daily to anon, authenticated;
grant all on public.ai_activity_weekly to anon, authenticated;

-- Index pour optimiser les requêtes
create index idx_ai_activity_2h_created_at on public.ai_activity_2h(created_at);
create index idx_ai_activity_daily_created_at on public.ai_activity_daily(created_at);
create index idx_ai_activity_weekly_created_at on public.ai_activity_weekly(created_at);

-- Index sur les buckets pour les requêtes temporelles
create index idx_ai_activity_2h_bucket on public.ai_activity_2h(bucket);
create index idx_ai_activity_daily_bucket on public.ai_activity_daily(bucket);
create index idx_ai_activity_weekly_bucket on public.ai_activity_weekly(bucket);
