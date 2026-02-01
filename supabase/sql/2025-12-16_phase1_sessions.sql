-- Phase 1 – Sessions & Canaux (NON DESTRUCTIF)
create table if not exists public.social_channels (
  id uuid primary key default gen_random_uuid(),
  channel_type text not null check (channel_type in ('whatsapp','facebook','instagram','tiktok','youtube')),
  entity text,
  display_name text,
  status text not null default 'active' check (status in ('active','suspended','expired')),
  provider_metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists social_channels_type_status_idx
  on public.social_channels (channel_type, status);

alter table if exists public.social_channels enable row level security;
revoke all on table public.social_channels from anon;
grant select on table public.social_channels to authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'social_channels' AND policyname = 'social_channels_select_authenticated'
  ) THEN
    CREATE POLICY social_channels_select_authenticated
      ON public.social_channels
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END$$;
