-- Video segments for orchestrated video generation

create table if not exists public.video_segments (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.generation_jobs(id) on delete cascade,
  segment_index integer not null,
  segment_type text not null check (segment_type in ('real_asset','ai_segment')),
  asset_id uuid references public.video_assets_library(id) on delete set null,
  segment_job_id uuid references public.generation_jobs(id) on delete set null,
  start_offset_seconds integer,
  end_offset_seconds integer,
  duration_seconds integer,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists video_segments_job_idx
  on public.video_segments (job_id, segment_index);
