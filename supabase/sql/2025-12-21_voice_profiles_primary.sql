create table if not exists public.voice_profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sample_url text not null,
  reference_media_path text,
  audio_job_id uuid references public.generation_jobs(id),
  created_at timestamptz not null default now()
);

alter table if exists public.voice_profiles
  add column if not exists is_primary boolean default false;

create index if not exists voice_profiles_is_primary_idx
  on public.voice_profiles (is_primary, created_at desc);
