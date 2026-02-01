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
