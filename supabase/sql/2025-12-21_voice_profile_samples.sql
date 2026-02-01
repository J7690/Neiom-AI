create table if not exists public.voice_profile_samples (
  id uuid primary key default gen_random_uuid(),
  voice_profile_id uuid not null references public.voice_profiles(id) on delete cascade,
  reference_media_path text not null,
  created_at timestamptz not null default now()
);

create index if not exists voice_profile_samples_profile_idx
  on public.voice_profile_samples (voice_profile_id, created_at desc);
