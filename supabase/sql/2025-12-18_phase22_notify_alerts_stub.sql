-- Phase 22 – Notify alerts stub (NON DESTRUCTIF)

create or replace function public.notify_recent_alerts_stub(p_emails text[])
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cnt int := 0;
  v_list jsonb := '[]'::jsonb;
begin
  select count(*) into v_cnt from public.alert_events where created_at >= now() - interval '1 day' and acknowledged = false;
  v_list := coalesce((select jsonb_agg(row_to_json(a)) from (
    select id, alert_type, severity, message, created_at
    from public.alert_events
    where created_at >= now() - interval '1 day' and acknowledged = false
    order by created_at desc
  ) a), '[]'::jsonb);

  perform public.log_event('alerts','info','Notify recent alerts (stub)', jsonb_build_object('emails', p_emails, 'count', v_cnt, 'alerts', v_list));
  return v_cnt;
end; $$;

grant execute on function public.notify_recent_alerts_stub(text[]) to anon, authenticated;
