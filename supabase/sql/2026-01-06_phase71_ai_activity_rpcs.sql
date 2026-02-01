-- Phase 6 – Créer tables ai_activity_* et RPCs de reporting (partie 2)
-- Objectif : RPCs de lecture pour le reporting 2h/24h/7j

-- RPC pour lire l'activité IA sur 2 heures
create or replace function public.get_ai_activity_2h(p_since timestamptz)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (
    select * from public.ai_activity_2h 
    where bucket >= p_since 
    order by bucket
  ) t;
end;
$$;

-- RPC pour lire l'activité IA quotidienne
create or replace function public.get_ai_activity_daily(p_days int)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (
    select * from public.ai_activity_daily 
    where bucket >= current_date - interval '1 day' * p_days 
    order by bucket
  ) t;
end;
$$;

-- RPC pour lire l'activité IA hebdomadaire
create or replace function public.get_ai_activity_weekly(p_weeks int)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (
    select * from public.ai_activity_weekly 
    where bucket >= current_date - interval '1 week' * p_weeks 
    order by bucket
  ) t;
end;
$$;

-- RPC pour agréger les données en temps réel (optionnel, pour alimenter les tables)
create or replace function public.aggregate_ai_activity(p_bucket_type text default '2h')
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_start_time timestamptz;
  v_end_time timestamptz;
  v_bucket_interval interval;
  v_messages_received int;
  v_messages_answered_by_ai int;
  v_messages_ai_skipped int;
  v_messages_needs_human int;
  v_alerts_created int;
  v_bucket timestamptz;
begin
  -- Définir l'intervalle selon le type
  if p_bucket_type = '2h' then
    v_bucket_interval := interval '2 hours';
    v_start_time := date_trunc('hour', now()) - (interval '2 hours' * floor(extract(hour from now()) / 2));
    v_end_time := v_start_time + v_bucket_interval;
  elsif p_bucket_type = 'daily' then
    v_bucket_interval := interval '1 day';
    v_start_time := date_trunc('day', now());
    v_end_time := v_start_time + v_bucket_interval;
  elsif p_bucket_type = 'weekly' then
    v_bucket_interval := interval '1 week';
    v_start_time := date_trunc('week', now());
    v_end_time := v_start_time + v_bucket_interval;
  else
    raise exception 'Invalid bucket_type. Use 2h, daily, or weekly';
  end if;

  -- Compter les messages dans la période
  select 
    count(*) as messages_received,
    count(*) filter (where answered_by_ai = true) as messages_answered_by_ai,
    count(*) filter (where ai_skipped = true) as messages_ai_skipped,
    count(*) filter (where needs_human = true) as messages_needs_human
  into 
    v_messages_received,
    v_messages_answered_by_ai,
    v_messages_ai_skipped,
    v_messages_needs_human
  from public.messages
  where created_at >= v_start_time and created_at < v_end_time;

  -- Compter les alertes dans la période
  select count(*) into v_alerts_created
  from public.ai_alerts
  where created_at >= v_start_time and created_at < v_end_time;

  -- Insérer ou mettre à jour l'agrégat
  if p_bucket_type = '2h' then
    v_bucket := v_start_time;
    insert into public.ai_activity_2h (
      bucket, messages_received, messages_answered_by_ai, 
      messages_ai_skipped, messages_needs_human, alerts_created
    )
    values (
      v_bucket, v_messages_received, v_messages_answered_by_ai,
      v_messages_ai_skipped, v_messages_needs_human, v_alerts_created
    )
    on conflict (bucket) do update set
      messages_received = excluded.messages_received,
      messages_answered_by_ai = excluded.messages_answered_by_ai,
      messages_ai_skipped = excluded.messages_ai_skipped,
      messages_needs_human = excluded.messages_needs_human,
      alerts_created = excluded.alerts_created,
      created_at = now();
  elsif p_bucket_type = 'daily' then
    v_bucket := v_start_time::date;
    insert into public.ai_activity_daily (
      bucket, messages_received, messages_answered_by_ai, 
      messages_ai_skipped, messages_needs_human, alerts_created
    )
    values (
      v_bucket, v_messages_received, v_messages_answered_by_ai,
      v_messages_ai_skipped, v_messages_needs_human, v_alerts_created
    )
    on conflict (bucket) do update set
      messages_received = excluded.messages_received,
      messages_answered_by_ai = excluded.messages_answered_by_ai,
      messages_ai_skipped = excluded.messages_ai_skipped,
      messages_needs_human = excluded.messages_needs_human,
      alerts_created = excluded.alerts_created,
      created_at = now();
  elsif p_bucket_type = 'weekly' then
    v_bucket := v_start_time::date;
    insert into public.ai_activity_weekly (
      bucket, messages_received, messages_answered_by_ai, 
      messages_ai_skipped, messages_needs_human, alerts_created
    )
    values (
      v_bucket, v_messages_received, v_messages_answered_by_ai,
      v_messages_ai_skipped, v_messages_needs_human, v_alerts_created
    )
    on conflict (bucket) do update set
      messages_received = excluded.messages_received,
      messages_answered_by_ai = excluded.messages_answered_by_ai,
      messages_ai_skipped = excluded.messages_ai_skipped,
      messages_needs_human = excluded.messages_needs_human,
      alerts_created = excluded.alerts_created,
      created_at = now();
  end if;

  return jsonb_build_object(
    'bucket_type', p_bucket_type,
    'bucket', v_bucket,
    'start_time', v_start_time,
    'end_time', v_end_time,
    'messages_received', v_messages_received,
    'messages_answered_by_ai', v_messages_answered_by_ai,
    'messages_ai_skipped', v_messages_ai_skipped,
    'messages_needs_human', v_messages_needs_human,
    'alerts_created', v_alerts_created
  );
end;
$$;

-- Grants pour les rôles Supabase
grant execute on function public.get_ai_activity_2h(timestamptz) to anon, authenticated;
grant execute on function public.get_ai_activity_daily(int) to anon, authenticated;
grant execute on function public.get_ai_activity_weekly(int) to anon, authenticated;
grant execute on function public.aggregate_ai_activity(text) to anon, authenticated;
