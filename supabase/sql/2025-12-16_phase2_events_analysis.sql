-- Phase 2 – Normalisation des événements & Analyse messages (NON DESTRUCTIF)

-- 1) Event store unifié pour webhooks multi-réseaux
create table if not exists public.webhook_events (
  id uuid primary key default gen_random_uuid(),
  channel text not null check (channel in ('whatsapp','facebook','instagram','tiktok','youtube')),
  type text not null check (type in ('message','comment')),
  event_id text not null,
  author_id text,
  author_name text,
  content text,
  event_date timestamptz,
  post_id text,
  conversation_id uuid references public.conversations(id) on delete set null,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists webhook_events_channel_event_id_unique
  on public.webhook_events (channel, event_id);

create index if not exists webhook_events_channel_event_date_idx
  on public.webhook_events (channel, event_date);

alter table if exists public.webhook_events enable row level security;
revoke all on table public.webhook_events from anon;
grant select on table public.webhook_events to authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'webhook_events' AND policyname = 'webhook_events_select_authenticated'
  ) THEN
    CREATE POLICY webhook_events_select_authenticated
      ON public.webhook_events
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END$$;

-- 2) Analyse des messages (intent/sentiment/confidence/escalade)
create table if not exists public.message_analysis (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  intent text,
  sentiment text check (sentiment in ('positive','neutral','negative')),
  confidence numeric,
  needs_escalation boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists message_analysis_message_id_unique
  on public.message_analysis (message_id);

create index if not exists message_analysis_created_at_idx
  on public.message_analysis (created_at);

alter table if exists public.message_analysis enable row level security;
revoke all on table public.message_analysis from anon;
grant select on table public.message_analysis to authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'message_analysis' AND policyname = 'message_analysis_select_authenticated'
  ) THEN
    CREATE POLICY message_analysis_select_authenticated
      ON public.message_analysis
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END$$;
