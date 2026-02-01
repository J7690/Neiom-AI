create or replace function public.create_editorial_plan_stub(
  p_author_agent text,
  p_objective text,
  p_start_date timestamptz default now(),
  p_days int default 7,
  p_channels text[] default '{}'::text[],
  p_timezone text default 'UTC',
  p_tone text default 'neutre',
  p_length int default 120
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_list jsonb := '[]'::jsonb;
  v_i int := 0;
  v_post uuid;
  v_sched uuid;
  v_content text;
  v_when timestamptz;
begin
  if coalesce(p_days,0) <= 0 then
    return jsonb_build_object('items', v_list);
  end if;

  while v_i < p_days loop
    v_content := public.suggest_content_stub(p_objective, p_tone, p_length);
    v_post := public.create_social_post(
      p_author_agent => p_author_agent,
      p_objective => p_objective,
      p_content_text => v_content,
      p_media_paths => '{}'::text[],
      p_target_channels => p_channels
    );
    v_when := p_start_date + make_interval(days => v_i);
    v_sched := public.schedule_social_post(v_post, v_when, p_timezone);
    v_list := v_list || jsonb_build_array(jsonb_build_object('post_id', v_post, 'schedule_id', v_sched, 'scheduled_at', v_when));
    v_i := v_i + 1;
  end loop;

  return jsonb_build_object('items', v_list);
end;
$$;

grant execute on function public.create_editorial_plan_stub(text,text,timestamptz,int,text[],text,text,int) to anon, authenticated;

create or replace function public.get_recent_activity(
  p_limit int default 50
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_messages jsonb;
  v_posts jsonb;
  v_schedules jsonb;
  v_leads jsonb;
begin
  select coalesce(jsonb_agg(x), '[]'::jsonb) into v_messages
  from (
    select jsonb_build_object(
      'id', m.id,
      'sent_at', m.sent_at,
      'channel', m.channel,
      'direction', m.direction,
      'content', left(coalesce(m.content_text,''), 160)
    ) as x
    from public.messages m
    order by m.sent_at desc nulls last
    limit p_limit
  ) t;

  select coalesce(jsonb_agg(x), '[]'::jsonb) into v_posts
  from (
    select jsonb_build_object(
      'id', p.id,
      'created_at', p.created_at,
      'status', p.status,
      'channels', p.target_channels,
      'content', left(coalesce(p.content_text,''), 160)
    ) as x
    from public.social_posts p
    order by p.created_at desc nulls last
    limit p_limit
  ) t2;

  select coalesce(jsonb_agg(x), '[]'::jsonb) into v_schedules
  from (
    select jsonb_build_object(
      'id', s.id,
      'scheduled_at', s.scheduled_at,
      'timezone', s.timezone
    ) as x
    from public.social_schedules s
    order by s.scheduled_at desc nulls last
    limit p_limit
  ) t3;

  select coalesce(jsonb_agg(x), '[]'::jsonb) into v_leads
  from (
    select jsonb_build_object(
      'id', l.id,
      'created_at', l.created_at,
      'status', l.status
    ) as x
    from public.leads l
    order by l.created_at desc nulls last
    limit p_limit
  ) t4;

  return jsonb_build_object(
    'messages', v_messages,
    'posts', v_posts,
    'schedules', v_schedules,
    'leads', v_leads
  );
end;
$$;

grant execute on function public.get_recent_activity(int) to anon, authenticated;

create or replace function public.get_metrics_timeseries(
  p_days int default 7
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_series jsonb;
begin
  with days as (
    select generate_series((current_date - (p_days - 1)), current_date, interval '1 day')::date as d
  ),
  mi as (
    select date(m.sent_at) d, count(*) c from public.messages m where m.direction = 'inbound' group by 1
  ),
  mo as (
    select date(m.sent_at) d, count(*) c from public.messages m where m.direction = 'outbound' group by 1
  ),
  sp as (
    select date(p.created_at) d, count(*) c from public.social_posts p group by 1
  ),
  ld as (
    select date(l.created_at) d, count(*) c from public.leads l group by 1
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'date', d.d,
    'messages_in', coalesce(mi.c,0),
    'messages_out', coalesce(mo.c,0),
    'social_posts', coalesce(sp.c,0),
    'leads', coalesce(ld.c,0)
  ) order by d.d), '[]'::jsonb) into v_series
  from days d
  left join mi on mi.d = d.d
  left join mo on mo.d = d.d
  left join sp on sp.d = d.d
  left join ld on ld.d = d.d;

  return v_series;
end;
$$;

grant execute on function public.get_metrics_timeseries(int) to anon, authenticated;

create or replace function public.upsert_setting(p_key text, p_value text)
returns boolean
language plpgsql
security definer
set search_path = public as
$$
begin
  insert into public.app_settings(key, value)
  values (p_key, p_value)
  on conflict (key) do update set value = excluded.value;
  return true;
end;
$$;

grant execute on function public.upsert_setting(text,text) to anon, authenticated;
