-- Patch: add missing provider-related columns on public.generation_jobs

alter table if exists public.generation_jobs
  add column if not exists provider text,
  add column if not exists provider_job_id text,
  add column if not exists quality_tier text,
  add column if not exists provider_metadata jsonb;
