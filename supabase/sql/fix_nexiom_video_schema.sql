-- Fix Nexiom video/image generation schema to match Edge Functions

-- 1) Ensure generation_jobs has video_brief_id
alter table if exists public.generation_jobs
  add column if not exists video_brief_id uuid;

-- 2) avatar_profiles: used by generate-image and generate-video
create table if not exists public.avatar_profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  face_reference_paths text[],
  environment_reference_paths text[],
  face_strength double precision,
  environment_strength double precision,
  height_cm integer,
  body_type text,
  complexion text,
  age_range text,
  gender text,
  hair_description text,
  clothing_style text,
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on table public.avatar_profiles to anon, authenticated;

-- 3) voice_profile_samples: used by orchestrate-video for extra reference audios
create table if not exists public.voice_profile_samples (
  id uuid primary key default gen_random_uuid(),
  voice_profile_id uuid not null references public.voice_profiles(id) on delete cascade,
  reference_media_path text not null,
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on table public.voice_profile_samples to anon, authenticated;

-- 4) video_assets_library: optional library of real shots used by orchestrate-video
create table if not exists public.video_assets_library (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null,
  location text,
  shot_type text,
  duration_seconds integer,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on table public.video_assets_library to anon, authenticated;

-- 5) video_segments: segments (real + AI) for orchestrated videos
create table if not exists public.video_segments (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.generation_jobs(id) on delete cascade,
  segment_index integer not null,
  segment_type text not null check (segment_type in ('real_asset','ai_segment')),
  asset_id uuid,
  segment_job_id uuid,
  duration_seconds integer,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on table public.video_segments to anon, authenticated;

-- 6) video_briefs: structured briefs used by generate-video / orchestrate-video
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
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on table public.video_briefs to anon, authenticated;
