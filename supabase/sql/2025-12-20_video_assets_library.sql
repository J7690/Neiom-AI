-- Video assets library for real rushes used in orchestrated video generation

create table if not exists public.video_assets_library (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null,
  name text,
  description text,
  location text,
  tags jsonb default '[]'::jsonb,
  shot_type text,
  duration_seconds integer,
  resolution_width integer,
  resolution_height integer,
  frame_rate numeric,
  lighting text,
  source_type text,
  created_at timestamptz not null default now(),
  created_by uuid
);

grant select, insert, update, delete on table public.video_assets_library to anon, authenticated;

create index if not exists video_assets_library_location_idx
  on public.video_assets_library (location, created_at desc);

create index if not exists video_assets_library_shot_type_idx
  on public.video_assets_library (shot_type, created_at desc);
