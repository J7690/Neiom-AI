-- Phase 20 – Dashboard & Alerts (NON DESTRUCTIF)

-- 1) Alerts RPCs
create or replace function public.list_alerts(p_limit int default 50)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select coalesce(jsonb_agg(x), '[]'::jsonb) into v from (
    select jsonb_build_object(
      'id', a.id,
      'alert_type', a.alert_type,
      'severity', a.severity,
      'message', a.message,
      'metadata', a.metadata,
      'acknowledged', a.acknowledged,
      'created_at', a.created_at
    ) as x
    from public.alert_events a
    order by a.created_at desc
    limit p_limit
  ) t;
  return v;
end; $$;

grant execute on function public.list_alerts(int) to anon, authenticated;

create or replace function public.ack_alert(p_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public as
$$
begin
  update public.alert_events set acknowledged = true where id = p_id;
  return found;
end; $$;

grant execute on function public.ack_alert(uuid) to anon, authenticated;

-- 2) Dashboard overview RPC
create or replace function public.get_dashboard_overview(p_days int default 7)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare
  v_start timestamptz := now() - make_interval(days => coalesce(p_days,7));
  v jsonb;
begin
  select jsonb_build_object(
    'messages_in', (select count(*) from public.messages m where m.direction='inbound' and m.sent_at >= v_start),
    'messages_out', (select count(*) from public.messages m where m.direction='outbound' and m.sent_at >= v_start),
    'posts_created', (select count(*) from public.social_posts p where p.created_at >= v_start),
    'leads', (select count(*) from public.leads l where l.created_at >= v_start),
    'open_conversations', (select count(*) from public.conversations c where c.status = 'open'),
    'scheduled_upcoming', (select count(*) from public.social_schedules s where s.scheduled_at >= now() and s.scheduled_at < now() + make_interval(days => coalesce(p_days,7)))
  ) into v;
  return v;
end; $$;

grant execute on function public.get_dashboard_overview(int) to anon, authenticated;
