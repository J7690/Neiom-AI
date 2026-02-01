-- Phase 15 – Agents stubs + Enrichissement locale (NON DESTRUCTIF)

create or replace function public.enrich_contacts_locale_stub()
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_count int := 0;
begin
  update public.contacts
    set locale = coalesce(locale, case when whatsapp_phone like '+226%' or whatsapp_phone like '00226%' then 'fr_BF' else 'fr_FR' end),
        country = coalesce(country, case when whatsapp_phone like '+226%' or whatsapp_phone like '00226%' then 'BF' else country end),
        updated_at = now()
  where (locale is null or country is null)
    and (whatsapp_phone is not null and whatsapp_phone <> '');
  GET DIAGNOSTICS v_count = ROW_COUNT;
  return v_count;
end;
$$;

grant execute on function public.enrich_contacts_locale_stub() to anon, authenticated;

create or replace function public.agent_support_run_once(
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
  v_leads int := 0;
begin
  v_routed := coalesce(public.route_unrouted_events(null, p_limit), 0);
  v_auto := coalesce(public.auto_reply_recent_inbound(p_since, p_limit), 0);
  v_leads := coalesce(public.derive_leads_from_recent_messages(p_since, p_limit), 0);
  return jsonb_build_object(
    'routed', v_routed,
    'auto_replied', v_auto,
    'leads_created', v_leads
  );
end;
$$;

grant execute on function public.agent_support_run_once(interval,int) to anon, authenticated;

create or replace function public.agent_marketing_generate_week_plan_stub(
  p_author_agent text,
  p_objective text,
  p_channels text[] default '{}'::text[],
  p_timezone text default 'Africa/Ouagadougou',
  p_tone text default 'neutre',
  p_length int default 120
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return public.create_editorial_plan_stub(
    p_author_agent => p_author_agent,
    p_objective => p_objective,
    p_start_date => now(),
    p_days => 7,
    p_channels => p_channels,
    p_timezone => p_timezone,
    p_tone => p_tone,
    p_length => p_length
  );
end;
$$;

grant execute on function public.agent_marketing_generate_week_plan_stub(text,text,text[],text,text,int) to anon, authenticated;
