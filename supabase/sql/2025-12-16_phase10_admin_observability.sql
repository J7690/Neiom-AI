create or replace function public.get_pipeline_stats()
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_build_object(
    'contacts', (select count(*) from public.contacts),
    'contact_channels', (select count(*) from public.contact_channels),
    'conversations', jsonb_build_object(
      'total', (select count(*) from public.conversations),
      'open', (select count(*) from public.conversations where status = 'open'),
      'closed', (select count(*) from public.conversations where status = 'closed')
    ),
    'messages', jsonb_build_object(
      'total', (select count(*) from public.messages),
      'inbound', (select count(*) from public.messages where direction = 'inbound'),
      'outbound', (select count(*) from public.messages where direction = 'outbound')
    ),
    'webhook_events', jsonb_build_object(
      'total', (select count(*) from public.webhook_events),
      'unrouted', (select count(*) from public.webhook_events where routed_at is null)
    ),
    'social_posts', jsonb_build_object(
      'total', (select count(*) from public.social_posts),
      'by_status', coalesce((
        select jsonb_object_agg(status, cnt)
        from (
          select status, count(*) cnt from public.social_posts group by status
        ) s
      ), '{}'::jsonb)
    ),
    'social_schedules', (select count(*) from public.social_schedules),
    'social_metrics', (select count(*) from public.social_metrics),
    'leads', coalesce((
      select jsonb_object_agg(status, cnt)
      from (
        select status, count(*) cnt from public.leads group by status
      ) l
    ), '{}'::jsonb)
  );
end;
$$;

grant execute on function public.get_pipeline_stats() to anon, authenticated;

create or replace function public.simulate_comment(
  p_channel text,
  p_author_id text,
  p_author_name text,
  p_content text,
  p_event_id text default null,
  p_event_date timestamptz default now()
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_event_id text;
  v_res jsonb;
begin
  v_event_id := coalesce(p_event_id, gen_random_uuid()::text);
  v_res := public.ingest_route_analyze(p_channel, 'comment', v_event_id, p_author_id, p_author_name, p_content, p_event_date, jsonb_build_object('source','simulate'));
  return v_res;
end;
$$;

grant execute on function public.simulate_comment(text,text,text,text,text,timestamptz) to anon, authenticated;
