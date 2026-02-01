-- Video briefs for orchestrated video generation

create table if not exists public.video_briefs (
  id uuid primary key default gen_random_uuid(),
  name text,
  description text,
  business_context jsonb,
  localization_context jsonb,
  visual_context jsonb,
  characters_context jsonb,
  camera_style jsonb,
  lighting_style jsonb,
  quality_profile jsonb,
  constraints jsonb,
  raw_prompt text,
  created_at timestamptz not null default now(),
  created_by uuid
);

grant select, insert, update, delete on table public.video_briefs to anon, authenticated;

alter table if exists public.generation_jobs
  add column if not exists video_brief_id uuid references public.video_briefs(id) on delete set null;

create index if not exists generation_jobs_video_brief_id_idx
  on public.generation_jobs (video_brief_id, created_at desc);
