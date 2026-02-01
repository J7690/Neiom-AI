-- Phase MI v3 – Adjust schedule_content_jobs_for_mission to auto-approve jobs before scheduling
-- Run with:
--   python tools/admin_sql.py --file supabase/sql/2026-02-01_phaseMI_content_jobs_missions_v3.sql

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

    -- Auto-approve job if needed before scheduling
    if v_job.status <> 'approved' then
      update public.content_jobs
      set status = 'approved',
          updated_at = now()
      where id = v_job.id;
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
