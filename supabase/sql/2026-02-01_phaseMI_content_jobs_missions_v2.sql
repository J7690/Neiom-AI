-- Phase MI v2 – Link marketing missions to content_jobs and schedule them
-- Run with:
--   python tools/admin_sql.py --file supabase/sql/2026-02-01_phaseMI_content_jobs_missions_v2.sql

-- 1) Enrich content_jobs with mission_id and phase (non destructive)
alter table public.content_jobs
  add column if not exists mission_id uuid
    references public.studio_marketing_missions(id)
    on delete set null;

alter table public.content_jobs
  add column if not exists phase text
    check (phase in ('intro','nurture','closing'));

-- 2) Create create_content_jobs_from_mission: generate content_jobs for a mission
create or replace function public.create_content_jobs_from_mission(
  p_mission_id uuid,
  p_start_date date default null,
  p_days int default null,
  p_timezone text default 'UTC',
  p_tone text default 'neutre',
  p_length int default 120,
  p_author_agent text default 'mission_brain'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mission public.studio_marketing_missions%rowtype;
  v_objective public.studio_marketing_objectives%rowtype;
  v_objective_code text;
  v_start_date date;
  v_end_date date;
  v_days int;
  v_job_ids uuid[] := '{}'::uuid[];
  v_i int;
  v_job_id uuid;
  v_current_date date;
  v_phase text;
begin
  if p_mission_id is null then
    raise exception 'p_mission_id cannot be null';
  end if;

  select * into v_mission
  from public.studio_marketing_missions
  where id = p_mission_id;

  if not found then
    raise exception 'studio_marketing_missions not found for id %', p_mission_id;
  end if;

  if v_mission.objective_id is not null then
    select * into v_objective
    from public.studio_marketing_objectives
    where id = v_mission.objective_id;
  end if;

  v_objective_code := coalesce(v_objective.objective, v_mission.metric, 'engagement');

  if p_start_date is not null then
    v_start_date := p_start_date;
  elsif v_mission.start_date is not null then
    v_start_date := v_mission.start_date;
  else
    v_start_date := current_date;
  end if;

  if p_days is not null and p_days > 0 then
    v_days := p_days;
    v_end_date := v_start_date + (p_days - 1);
  elsif v_mission.end_date is not null and v_mission.end_date >= v_start_date then
    v_end_date := v_mission.end_date;
    v_days := (v_end_date - v_start_date + 1);
  else
    v_days := 7;
    v_end_date := v_start_date + (v_days - 1);
  end if;

  if v_days <= 0 then
    raise exception 'computed days for mission % is not positive', p_mission_id;
  end if;

  v_current_date := v_start_date;

  for v_i in 1..v_days loop
    if v_i = 1 then
      v_phase := 'intro';
    elsif v_i = v_days then
      v_phase := 'closing';
    else
      v_phase := 'nurture';
    end if;

    insert into public.content_jobs (
      title,
      objective,
      format,
      channels,
      origin_ui,
      status,
      author_agent,
      mission_id,
      phase,
      metadata
    )
    values (
      coalesce(v_mission.activity_ref, v_objective_code),
      v_objective_code,
      'post',
      array[v_mission.channel],
      'mission_campaign',
      'draft',
      p_author_agent,
      p_mission_id,
      v_phase,
      jsonb_build_object(
        'date', v_current_date,
        'timezone', p_timezone,
        'tone', p_tone,
        'length', p_length,
        'day_index', v_i,
        'mission_channel', v_mission.channel,
        'mission_metric', v_mission.metric,
        'phase', v_phase
      )
    )
    returning id into v_job_id;

    v_job_ids := v_job_ids || v_job_id;
    v_current_date := v_current_date + 1;
  end loop;

  return jsonb_build_object(
    'mission_id', p_mission_id,
    'objective', v_objective_code,
    'start_date', v_start_date,
    'end_date', v_end_date,
    'days', v_days,
    'created_job_ids', v_job_ids,
    'created_count', coalesce(array_length(v_job_ids, 1), 0),
    'timezone', p_timezone,
    'tone', p_tone,
    'length', p_length,
    'author_agent', p_author_agent
  );
end;
$$;

grant execute on function public.create_content_jobs_from_mission(
  uuid, date, int, text, text, int, text
) to anon, authenticated;

-- 3) Create schedule_content_jobs_for_mission: schedule content_jobs for a mission
create or replace function public.schedule_content_jobs_for_mission(
  p_mission_id uuid,
  p_timezone text default 'UTC',
  p_max_posts_per_day int default 3
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mission public.studio_marketing_missions%rowtype;
  v_job record;
  v_result jsonb := '[]'::jsonb;
  v_date date;
  v_scheduled_at timestamptz;
  v_schedule jsonb;
  v_jobs_scheduled int := 0;
  v_existing_count int;
begin
  if p_mission_id is null then
    raise exception 'p_mission_id cannot be null';
  end if;

  select * into v_mission
  from public.studio_marketing_missions
  where id = p_mission_id;

  if not found then
    raise exception 'studio_marketing_missions not found for id %', p_mission_id;
  end if;

  for v_job in
    select *
    from public.content_jobs
    where mission_id = p_mission_id
      and social_post_id is null
      and status in ('draft','generated','approved')
    order by (metadata->>'date')::date nulls last, created_at
  loop
    v_date := coalesce((v_job.metadata->>'date')::date, current_date);

    if p_max_posts_per_day is not null and p_max_posts_per_day > 0 then
      select count(*) into v_existing_count
      from public.social_schedules s
      join public.social_posts p on p.id = s.post_id
      where v_mission.channel = any(p.target_channels)
        and (s.scheduled_at at time zone p_timezone)::date = v_date
        and s.status in ('scheduled','running');

      if v_existing_count >= p_max_posts_per_day then
        continue;
      end if;
    end if;

    v_scheduled_at := (v_date::timestamptz + interval '12 hours');

    v_schedule := public.schedule_content_job(v_job.id, v_scheduled_at, p_timezone);

    v_result := v_result || jsonb_build_array(
      jsonb_build_object(
        'content_job_id', v_job.id,
        'schedule', v_schedule
      )
    );
    v_jobs_scheduled := v_jobs_scheduled + 1;
  end loop;

  return jsonb_build_object(
    'mission_id', p_mission_id,
    'jobs_scheduled', v_jobs_scheduled,
    'details', v_result
  );
end;
$$;

grant execute on function public.schedule_content_jobs_for_mission(uuid, text, int)
  to anon, authenticated;
