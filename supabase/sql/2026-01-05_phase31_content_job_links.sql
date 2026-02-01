-- Phase 31 – Content jobs linking wrappers (NON DESTRUCTIF)

create or replace function public.link_content_job_to_post(
  p_content_job_id uuid,
  p_post_id uuid,
  p_status text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v jsonb;
begin
  update public.content_jobs
  set social_post_id = p_post_id,
      status = coalesce(p_status, status),
      updated_at = now()
  where id = p_content_job_id
  returning to_jsonb(content_jobs.*) into v;

  if v is null then
    raise exception 'content_job not found';
  end if;

  return v;
end;
$$;

grant execute on function public.link_content_job_to_post(uuid,uuid,text) to anon, authenticated;

create or replace function public.link_content_job_to_generation_job(
  p_content_job_id uuid,
  p_generation_job_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v jsonb;
begin
  update public.content_jobs
  set generation_job_id = p_generation_job_id,
      updated_at = now()
  where id = p_content_job_id
  returning to_jsonb(content_jobs.*) into v;

  if v is null then
    raise exception 'content_job not found';
  end if;

  return v;
end;
$$;

grant execute on function public.link_content_job_to_generation_job(uuid,uuid) to anon, authenticated;
