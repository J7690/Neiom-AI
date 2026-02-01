-- Hotfix: add missing updated_at column to message_analysis
alter table if exists public.message_analysis
  add column if not exists updated_at timestamptz not null default now();
