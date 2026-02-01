create table if not exists public.avatar_profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  face_reference_paths text[] not null,
  environment_reference_paths text[],
  face_strength double precision default 0.7,
  environment_strength double precision default 0.35,
  is_primary boolean default false,
  created_at timestamptz not null default now()
);

create index if not exists avatar_profiles_primary_idx
  on public.avatar_profiles (is_primary, created_at desc);
