-- Nexiom – Supabase schema for AI generation

-- Table to track generation jobs (video, image, audio)
create table if not exists public.generation_jobs (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('video', 'image', 'audio')),
  prompt text not null,
  model text,
  duration_seconds integer,
  reference_media_path text,
  status text not null default 'pending' check (status in ('pending', 'processing', 'completed', 'failed')),
  result_url text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists generation_jobs_type_status_idx
  on public.generation_jobs (type, status);

-- Simple trigger to keep updated_at fresh
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_generation_jobs_updated_at
before update on public.generation_jobs
for each row execute procedure public.set_updated_at();

-- RPC to get a single job by id
create or replace function public.get_generation_job(job_id uuid)
returns public.generation_jobs
language sql
stable
security definer
set search_path = public as
$$
  select * from public.generation_jobs where id = job_id;
$$;

grant usage on schema public to anon, authenticated;

grant select, insert, update on table public.generation_jobs to anon, authenticated;

grant execute on function public.get_generation_job(uuid) to anon, authenticated;

alter table if exists public.generation_jobs
  add column if not exists provider text,
  add column if not exists provider_job_id text,
  add column if not exists quality_tier text,
  add column if not exists provider_metadata jsonb;

-- Table to store reusable cloned voice profiles
create table if not exists public.voice_profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sample_url text not null,
  reference_media_path text,
  audio_job_id uuid references public.generation_jobs(id),
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on table public.voice_profiles to anon, authenticated;

-- Table to store reusable text templates (scripts, marketing texts)
create table if not exists public.text_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  content text not null,
  category text not null check (category in ('video_script', 'image_overlay', 'generic')),
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on table public.text_templates to anon, authenticated;

alter table if exists public.generation_jobs
  add column if not exists parent_job_id uuid references public.generation_jobs(id),
  add column if not exists job_mode text,
  add column if not exists negative_prompt text,
  add column if not exists aspect_ratio text,
  add column if not exists seed bigint,
  add column if not exists width integer,
  add column if not exists height integer;

create table if not exists public.image_assets (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.generation_jobs(id) on delete cascade,
  parent_asset_id uuid references public.image_assets(id) on delete set null,
  variant_type text not null check (variant_type in ('base','img2img','inpaint','outpaint','background_removal','upscale','variation')),
  storage_path text not null,
  thumbnail_path text,
  mask_path text,
  prompt text,
  negative_prompt text,
  seed bigint,
  width integer,
  height integer,
  aspect_ratio text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists image_assets_job_id_created_at_idx
  on public.image_assets (job_id, created_at);

grant select, insert, update, delete on table public.image_assets to anon, authenticated;

create table if not exists public.visual_projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid,
  tags jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

grant select, insert, update, delete on table public.visual_projects to anon, authenticated;

create table if not exists public.visual_documents (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.visual_projects(id) on delete cascade,
  title text,
  width integer,
  height integer,
  dpi integer,
  background_color text,
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists visual_documents_project_id_idx
  on public.visual_documents (project_id);

grant select, insert, update, delete on table public.visual_documents to anon, authenticated;

create table if not exists public.visual_document_versions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.visual_documents(id) on delete cascade,
  version_index integer not null,
  is_current boolean not null default true,
  canvas_state jsonb not null default '{}'::jsonb,
  thumbnail_asset_id uuid references public.image_assets(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists visual_document_versions_document_idx
  on public.visual_document_versions (document_id, version_index desc);

create index if not exists visual_document_versions_current_idx
  on public.visual_document_versions (document_id, is_current);

grant select, insert, update, delete on table public.visual_document_versions to anon, authenticated;
