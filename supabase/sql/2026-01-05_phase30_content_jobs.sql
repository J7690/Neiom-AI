-- Phase 30 – Content jobs orchestrator base (NON DESTRUCTIF)

create table if not exists public.content_jobs (
  id uuid primary key default gen_random_uuid(),
  title text,
  objective text,
  format text,
  channels text[] not null default '{}'::text[],
  origin_ui text,
  status text not null default 'draft'
    check (status in ('draft','generated','pending_validation','approved','scheduled','published','archived')),
  author_agent text,
  generation_job_id uuid,
  social_post_id uuid,
  experiment_id uuid,
  variant_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.content_jobs enable row level security;

grant select, insert, update, delete on table public.content_jobs to anon, authenticated;

create or replace function public.upsert_content_job(
  p_id uuid default null,
  p_title text default null,
  p_objective text default null,
  p_format text default null,
  p_channels text[] default null,
  p_origin_ui text default null,
  p_status text default null,
  p_author_agent text default null,
  p_generation_job_id uuid default null,
  p_social_post_id uuid default null,
  p_experiment_id uuid default null,
  p_variant_id uuid default null,
  p_metadata jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_id uuid;
begin
  if p_id is null then
    insert into public.content_jobs(
      title,
      objective,
      format,
      channels,
      origin_ui,
      status,
      author_agent,
      generation_job_id,
      social_post_id,
      experiment_id,
      variant_id,
      metadata
    ) values (
      p_title,
      p_objective,
      p_format,
      coalesce(p_channels, '{}'::text[]),
      p_origin_ui,
      coalesce(p_status, 'draft'),
      p_author_agent,
      p_generation_job_id,
      p_social_post_id,
      p_experiment_id,
      p_variant_id,
      coalesce(p_metadata, '{}'::jsonb)
    ) returning id into v_id;
  else
    update public.content_jobs
    set title             = coalesce(p_title, title),
        objective         = coalesce(p_objective, objective),
        format            = coalesce(p_format, format),
        channels          = coalesce(p_channels, channels),
        origin_ui         = coalesce(p_origin_ui, origin_ui),
        status            = coalesce(p_status, status),
        author_agent      = coalesce(p_author_agent, author_agent),
        generation_job_id = coalesce(p_generation_job_id, generation_job_id),
        social_post_id    = coalesce(p_social_post_id, social_post_id),
        experiment_id     = coalesce(p_experiment_id, experiment_id),
        variant_id        = coalesce(p_variant_id, variant_id),
        metadata          = coalesce(p_metadata, metadata),
        updated_at        = now()
    where id = p_id
    returning id into v_id;

    if v_id is null then
      insert into public.content_jobs(
        title,
        objective,
        format,
        channels,
        origin_ui,
        status,
        author_agent,
        generation_job_id,
        social_post_id,
        experiment_id,
        variant_id,
        metadata
      ) values (
        p_title,
        p_objective,
        p_format,
        coalesce(p_channels, '{}'::text[]),
        p_origin_ui,
        coalesce(p_status, 'draft'),
        p_author_agent,
        p_generation_job_id,
        p_social_post_id,
        p_experiment_id,
        p_variant_id,
        coalesce(p_metadata, '{}'::jsonb)
      ) returning id into v_id;
    end if;
  end if;

  return (
    select to_jsonb(c)
    from public.content_jobs c
    where c.id = v_id
  );
end;
$$;

grant execute on function public.upsert_content_job(
  uuid,
  text,
  text,
  text,
  text[],
  text,
  text,
  text,
  uuid,
  uuid,
  uuid,
  uuid,
  jsonb
) to anon, authenticated;

create or replace function public.get_content_job(
  p_id uuid
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select to_jsonb(c) into v
  from public.content_jobs c
  where c.id = p_id;

  if v is null then
    raise exception 'content_job not found';
  end if;

  return v;
end;
$$;

grant execute on function public.get_content_job(uuid) to anon, authenticated;

create or replace function public.list_content_jobs(
  p_status text default null,
  p_limit int default 50
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select coalesce(jsonb_agg(row_to_json(c)), '[]'::jsonb) into v
  from (
    select *
    from public.content_jobs
    where (p_status is null or status = p_status)
    order by created_at desc
    limit p_limit
  ) c;
  return v;
end;
$$;

grant execute on function public.list_content_jobs(text,int) to anon, authenticated;
