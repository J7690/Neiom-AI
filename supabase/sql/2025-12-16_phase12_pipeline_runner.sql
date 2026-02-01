-- Phase 12 – Orchestrateur de pipeline + aperçu des réglages (NON DESTRUCTIF)

create or replace function public.run_pipeline_once(
  p_since interval default interval '1 hour',
  p_limit int default 100
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_routed int := 0;
  v_auto int := 0;
  v_sched int := 0;
  v_metrics int := 0;
begin
  v_routed := coalesce(public.route_unrouted_events(null, p_limit), 0);
  v_auto := coalesce(public.auto_reply_recent_inbound(p_since, p_limit), 0);
  v_sched := coalesce(public.run_schedules_once(), 0);
  v_metrics := coalesce(public.collect_metrics_stub(), 0);
  return jsonb_build_object(
    'routed', v_routed,
    'auto_replied', v_auto,
    'schedules_run', v_sched,
    'metrics_collected', v_metrics
  );
end;
$$;

grant execute on function public.run_pipeline_once(interval,int) to anon, authenticated;

create or replace function public.settings_overview()
returns jsonb
language sql
security definer
set search_path = public as
$$
  select jsonb_build_object(
    'WHATSAPP_VERIFY_TOKEN', exists(select 1 from public.app_settings where key='WHATSAPP_VERIFY_TOKEN' and nullif(value,'') is not null),
    'META_APP_SECRET', exists(select 1 from public.app_settings where key='META_APP_SECRET' and nullif(value,'') is not null),
    'OPENROUTER_API_KEY', exists(select 1 from public.app_settings where key='OPENROUTER_API_KEY' and nullif(value,'') is not null),
    'NEXIOM_DEFAULT_CHAT_MODEL', exists(select 1 from public.app_settings where key='NEXIOM_DEFAULT_CHAT_MODEL' and nullif(value,'') is not null),
    'WHATSAPP_PHONE_NUMBER_ID', exists(select 1 from public.app_settings where key='WHATSAPP_PHONE_NUMBER_ID' and nullif(value,'') is not null),
    'WHATSAPP_ACCESS_TOKEN', exists(select 1 from public.app_settings where key='WHATSAPP_ACCESS_TOKEN' and nullif(value,'') is not null),
    'WHATSAPP_API_BASE_URL', exists(select 1 from public.app_settings where key='WHATSAPP_API_BASE_URL' and nullif(value,'') is not null)
  );
$$;

grant execute on function public.settings_overview() to anon, authenticated;
