-- Phase 5 – Créer RPC schedule_content_job et intégrer UI
-- Objectif : planifier un content_job en créant le post et le schedule associés

create or replace function public.schedule_content_job(
  p_content_job_id uuid,
  p_schedule_at timestamptz,
  p_timezone text default 'UTC'
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_job public.content_jobs%rowtype;
  v_post_id uuid;
  v_schedule_id uuid;
begin
  -- 1. Récupérer le content_job
  select * into v_job from public.content_jobs where id = p_content_job_id;
  if not found then
    raise exception 'content_job not found';
  end if;

  -- 2. Validation
  if v_job.status != 'approved' then
    raise exception 'content_job must be approved before scheduling';
  end if;

  if v_job.social_post_id is not null then
    raise exception 'content_job already has a social post';
  end if;

  -- 3. Créer le post (version générique, sans canaux spécifiques)
  insert into public.social_posts (
    author_agent,
    objective,
    content_text,
    target_channels,
    status
  )
  values (
    coalesce(v_job.author_agent, 'content_job'),
    v_job.objective,
    coalesce(v_job.title, v_job.objective),
    v_job.channels,
    'scheduled'
  )
  returning id into v_post_id;

  -- 4. Créer le schedule
  insert into public.social_schedules (
    post_id,
    scheduled_at,
    timezone
  )
  values (
    v_post_id,
    p_schedule_at,
    p_timezone
  )
  returning id into v_schedule_id;

  -- 5. Mettre à jour le content_job
  update public.content_jobs
    set social_post_id = v_post_id,
        status = 'scheduled',
        updated_at = now()
    where id = p_content_job_id;

  -- 6. Retourner le résultat
  return jsonb_build_object(
    'post_id', v_post_id,
    'schedule_id', v_schedule_id,
    'scheduled_at', p_schedule_at,
    'timezone', p_timezone,
    'content_job_id', p_content_job_id,
    'channels', v_job.channels,
    'objective', v_job.objective
  );
end;
$$;

grant execute on function public.schedule_content_job(uuid, timestamptz, text) to anon, authenticated;
