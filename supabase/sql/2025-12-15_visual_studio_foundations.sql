-- Visual editor foundations: projects, documents, versions

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
