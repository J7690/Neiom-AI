-- Phase 5 – Publication & Planification (NON DESTRUCTIF)

create table if not exists public.social_posts (
  id uuid primary key default gen_random_uuid(),
  author_agent text,
  objective text,
  content_text text,
  media_paths text[] default '{}'::text[],
  target_channels text[] not null default '{}'::text[],
  status text not null default 'draft' check (status in ('draft','scheduled','publishing','published','failed')),
  provider_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.social_schedules (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  scheduled_at timestamptz not null,
  timezone text,
  status text not null default 'scheduled' check (status in ('scheduled','running','published','failed','canceled')),
  created_at timestamptz not null default now()
);

create table if not exists public.publish_logs (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  channel text not null check (channel in ('whatsapp','facebook','instagram','tiktok','youtube')),
  attempt_no integer not null default 1,
  status text not null check (status in ('success','error')),
  error_message text,
  provider_response jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists social_schedules_post_id_idx on public.social_schedules (post_id, scheduled_at);
create index if not exists publish_logs_post_channel_idx on public.publish_logs (post_id, channel, created_at);

alter table if exists public.social_posts enable row level security;
alter table if exists public.social_schedules enable row level security;
alter table if exists public.publish_logs enable row level security;

revoke all on table public.social_posts from anon;
revoke all on table public.social_schedules from anon;
revoke all on table public.publish_logs from anon;

grant select on table public.social_posts to authenticated;
grant select on table public.social_schedules to authenticated;
grant select on table public.publish_logs to authenticated;

grant select on table public.social_posts to anon;
grant select on table public.social_schedules to anon;
grant select on table public.publish_logs to anon;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='social_posts' AND policyname='social_posts_select_all'
  ) THEN
    CREATE POLICY social_posts_select_all ON public.social_posts FOR SELECT TO anon, authenticated USING (true);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='social_schedules' AND policyname='social_schedules_select_all'
  ) THEN
    CREATE POLICY social_schedules_select_all ON public.social_schedules FOR SELECT TO anon, authenticated USING (true);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='publish_logs' AND policyname='publish_logs_select_all'
  ) THEN
    CREATE POLICY publish_logs_select_all ON public.publish_logs FOR SELECT TO anon, authenticated USING (true);
  END IF;
END$$;
