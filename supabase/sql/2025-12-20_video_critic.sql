-- Video critic fields on generation_jobs

alter table if exists public.generation_jobs
  add column if not exists quality_score numeric,
  add column if not exists critic_report text,
  add column if not exists critic_metadata jsonb;
