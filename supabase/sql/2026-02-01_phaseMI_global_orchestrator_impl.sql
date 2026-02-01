-- Phase MI – Implémentation orchestrateur global & RPC mission-aware
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-02-01_phaseMI_global_orchestrator_impl.sql

-- 1) RPC list_content_jobs_for_mission : lister les content_jobs liés à une mission
create or replace function public.list_content_jobs_for_mission(
  p_mission_id uuid,
  p_status text default null,
  p_limit int default 200
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v jsonb;
begin
  if p_mission_id is null then
    raise exception 'p_mission_id cannot be null';
  end if;

  select coalesce(jsonb_agg(row_to_json(c)), '[]'::jsonb)
  into v
  from (
    select *
    from public.content_jobs
    where mission_id = p_mission_id
      and (p_status is null or status = p_status)
    order by (metadata->>'date')::date nulls last, created_at desc
    limit p_limit
  ) c;

  return v;
end;
$$;

grant execute on function public.list_content_jobs_for_mission(uuid, text, int)
  to anon, authenticated;


-- 2) RPC list_mission_calendar : calendrier éditorial filtré sur une mission
create or replace function public.list_mission_calendar(
  p_mission_id uuid,
  p_start_date date default now()::date,
  p_days int default 30
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v jsonb;
begin
  if p_mission_id is null then
    raise exception 'p_mission_id cannot be null';
  end if;

  with items as (
    select
      date(s.scheduled_at) as d,
      jsonb_build_object(
        'schedule_id', s.id,
        'time', to_char(s.scheduled_at, 'HH24:MI'),
        'post_id', s.post_id,
        'status', s.status,
        'channels', p.target_channels,
        'content', left(coalesce(p.content_text, ''), 140),
        'content_job_id', cj.id,
        'mission_id', cj.mission_id,
        'phase', cj.phase
      ) as item
    from public.social_schedules s
    join public.social_posts p on p.id = s.post_id
    join public.content_jobs cj on cj.social_post_id = s.post_id
    where cj.mission_id = p_mission_id
      and s.scheduled_at >= p_start_date
      and s.scheduled_at < p_start_date + (p_days || ' days')::interval
    order by s.scheduled_at asc
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'date', d::date,
        'items', coalesce((select jsonb_agg(item) from items i where i.d = d), '[]'::jsonb)
      )
      order by d asc
    ),
    '[]'::jsonb
  )
  into v
  from generate_series(
    p_start_date,
    p_start_date + (p_days::text || ' days')::interval,
    '1 day'
  ) as d;

  return v;
end;
$$;

grant execute on function public.list_mission_calendar(uuid, date, int)
  to anon, authenticated;


-- 3) RPC get_mission_intelligence_summary : résumé du dernier rapport d'intelligence de mission
create or replace function public.get_mission_intelligence_summary(
  p_mission_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select report
  from public.studio_mission_intelligence_reports
  where mission_id = p_mission_id
  order by created_at desc
  limit 1;
$$;

grant execute on function public.get_mission_intelligence_summary(uuid)
  to anon, authenticated;


-- 4) Orchestrateur global multi-missions pour un canal donné et une date
create or replace function public.orchestrate_global_publishing(
  p_channel text,
  p_date date default current_date,
  p_max_posts_per_day int default 5,
  p_timezone text default 'UTC'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_date date := coalesce(p_date, current_date);
  v_daily_existing int := 0;
  v_jobs_scheduled int := 0;
  v_result jsonb := '[]'::jsonb;
  v_candidate record;
  v_schedule jsonb;
  v_scheduled_at timestamptz;
  v_missions_scheduled uuid[] := '{}'::uuid[];
begin
  if p_channel is null or trim(p_channel) = '' then
    raise exception 'p_channel is required';
  end if;

  -- 4.1) Nombre de posts déjà planifiés pour ce canal et cette date
  if p_max_posts_per_day is not null and p_max_posts_per_day > 0 then
    select count(*)
    into v_daily_existing
    from public.social_schedules s
    join public.social_posts p on p.id = s.post_id
    where p_channel = any(p.target_channels)
      and (s.scheduled_at at time zone p_timezone)::date = v_date
      and s.status in ('scheduled', 'running');
  end if;

  -- 4.2) Missions qui ont déjà au moins un post planifié ce jour-là sur ce canal
  select coalesce(array_agg(distinct cj.mission_id), '{}'::uuid[])
  into v_missions_scheduled
  from public.social_schedules s
  join public.social_posts p on p.id = s.post_id
  join public.content_jobs cj on cj.social_post_id = s.post_id
  where p_channel = any(p.target_channels)
    and (s.scheduled_at at time zone p_timezone)::date = v_date
    and s.status in ('scheduled', 'running')
    and cj.mission_id is not null;

  -- 4.3) Sélection des content_jobs candidats (toutes missions actives sur ce canal)
  for v_candidate in
    select
      cj.id as content_job_id,
      cj.mission_id,
      cj.phase,
      (cj.metadata->>'date')::date as planned_date,
      m.start_date,
      m.end_date,
      coalesce(o.priority, 'medium') as objective_priority
    from public.content_jobs cj
    join public.studio_marketing_missions m on m.id = cj.mission_id
    left join public.studio_marketing_objectives o on o.id = m.objective_id
    where cj.mission_id is not null
      and m.channel = p_channel
      and (p_channel = any(cj.channels))
      and cj.social_post_id is null
      and cj.status in ('draft', 'generated', 'approved')
      and (
        (cj.metadata->>'date')::date is null
        or (cj.metadata->>'date')::date = v_date
      )
      and (m.start_date is null or m.start_date <= v_date)
      and (m.end_date is null or m.end_date >= v_date)
      and m.status in ('planned', 'active')
    order by
      case coalesce(o.priority, 'medium')
        when 'high' then 1
        when 'medium' then 2
        when 'low' then 3
        else 4
      end,
      case coalesce(cj.phase, 'nurture')
        when 'intro' then 1
        when 'nurture' then 2
        when 'closing' then 3
        else 4
      end,
      cj.created_at
  loop
    -- 4.4) Respect du cap global par jour / canal
    if p_max_posts_per_day is not null and p_max_posts_per_day > 0
       and (v_daily_existing + v_jobs_scheduled) >= p_max_posts_per_day then
      exit;
    end if;

    -- 4.5) Au plus un post par mission pour ce jour (en tenant compte de l'existant)
    if v_candidate.mission_id = any(v_missions_scheduled) then
      continue;
    end if;

    -- 4.6) Auto-approval si nécessaire
    if (select status from public.content_jobs where id = v_candidate.content_job_id) <> 'approved' then
      update public.content_jobs
      set status = 'approved',
          updated_at = now()
      where id = v_candidate.content_job_id;
    end if;

    -- 4.7) Choix d'une heure "neutre" dans la journée (peut être raffiné plus tard)
    v_scheduled_at := (v_date::timestamptz + interval '12 hours');

    -- 4.8) Planifier le content_job via le RPC canonique
    v_schedule := public.schedule_content_job(v_candidate.content_job_id, v_scheduled_at, p_timezone);

    v_result := v_result || jsonb_build_array(
      jsonb_build_object(
        'mission_id', v_candidate.mission_id,
        'content_job_id', v_candidate.content_job_id,
        'schedule', v_schedule
      )
    );

    v_jobs_scheduled := v_jobs_scheduled + 1;
    v_missions_scheduled := v_missions_scheduled || v_candidate.mission_id;
  end loop;

  return jsonb_build_object(
    'date', v_date,
    'channel', p_channel,
    'jobs_scheduled', v_jobs_scheduled,
    'details', v_result
  );
end;
$$;

grant execute on function public.orchestrate_global_publishing(text, date, int, text)
  to anon, authenticated;


-- 5) Index de support (non destructifs)
create index if not exists content_jobs_mission_id_idx
  on public.content_jobs(mission_id);

create index if not exists content_jobs_mission_phase_status_idx
  on public.content_jobs(mission_id, phase, status);

create index if not exists studio_marketing_missions_status_channel_dates_idx
  on public.studio_marketing_missions(status, channel, start_date, end_date);
