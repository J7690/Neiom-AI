-- Phase 6 – Analytics (NON DESTRUCTIF)

create table if not exists public.social_metrics (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references public.social_posts(id) on delete set null,
  channel text not null check (channel in ('whatsapp','facebook','instagram','tiktok','youtube')),
  impressions bigint,
  views bigint,
  likes bigint,
  comments bigint,
  shares bigint,
  engagement_rate numeric,
  fetched_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists social_metrics_post_channel_idx on public.social_metrics (post_id, channel, fetched_at desc);

alter table if exists public.social_metrics enable row level security;
revoke all on table public.social_metrics from anon;

grant select on table public.social_metrics to authenticated;

grant select on table public.social_metrics to anon;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='social_metrics' AND policyname='social_metrics_select_all'
  ) THEN
    CREATE POLICY social_metrics_select_all ON public.social_metrics FOR SELECT TO anon, authenticated USING (true);
  END IF;
END$$;
