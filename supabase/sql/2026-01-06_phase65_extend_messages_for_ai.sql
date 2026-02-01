-- Phase 1 – Étendre messages avec colonnes IA et créer table ai_alerts
-- Objectif : tracer les actions IA et les trous de knowledge

-- 1. Étendre la table messages
alter table public.messages
  add column answered_by_ai boolean default false,
  add column needs_human boolean default false,
  add column ai_skipped boolean default false,
  add column knowledge_hit_ids uuid[];

-- 2. Créer la table ai_alerts pour tracer les alertes IA
create table public.ai_alerts (
  id uuid primary key default gen_random_uuid(),
  type text not null,
  message_id uuid references public.messages(id),
  content_job_id uuid references public.content_jobs(id),
  created_at timestamptz default now(),
  handled_at timestamptz,
  handled_by text
);

-- 3. Grants pour les rôles Supabase
grant all on public.ai_alerts to anon, authenticated;
grant usage, select on public.ai_alerts to service_role;

-- 4. Index pour optimiser les requêtes
create index idx_ai_alerts_type on public.ai_alerts(type);
create index idx_ai_alerts_created_at on public.ai_alerts(created_at);
create index idx_ai_alerts_message_id on public.ai_alerts(message_id);
create index idx_ai_alerts_content_job_id on public.ai_alerts(content_job_id);

-- 5. Index sur les nouvelles colonnes de messages
create index idx_messages_answered_by_ai on public.messages(answered_by_ai);
create index idx_messages_needs_human on public.messages(needs_human);
create index idx_messages_ai_skipped on public.messages(ai_skipped);
create index idx_messages_knowledge_hit_ids on public.messages using gin(knowledge_hit_ids);
