create extension if not exists pgcrypto;

create or replace function public.simulate_message(
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
  v_res := public.ingest_route_analyze(p_channel, 'message', v_event_id, p_author_id, p_author_name, p_content, p_event_date, jsonb_build_object('source','simulate'));
  return v_res;
end;
$$;

revoke all on function public.simulate_message(text,text,text,text,text,timestamptz) from public;
grant execute on function public.simulate_message(text,text,text,text,text,timestamptz) to anon, authenticated;

create or replace function public.set_conversation_escalation(
  p_conversation_id uuid,
  p_value boolean
)
returns void
language plpgsql
security definer
set search_path = public as
$$
begin
  update public.conversations
  set metadata = coalesce(metadata,'{}'::jsonb) || jsonb_build_object('needs_escalation', p_value),
      updated_at = now()
  where id = p_conversation_id;
end;
$$;

revoke all on function public.set_conversation_escalation(uuid,boolean) from public;
grant execute on function public.set_conversation_escalation(uuid,boolean) to anon, authenticated;

create or replace function public.respond_with_stub(
  p_conversation_id uuid,
  p_text text
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare
  v_channel text;
  v_contact_id uuid;
  v_message_id uuid;
begin
  select channel, contact_id into v_channel, v_contact_id
  from public.conversations where id = p_conversation_id;
  if not found then
    raise exception 'conversation not found';
  end if;

  insert into public.messages(
    conversation_id, contact_id, channel, direction, message_type, content_text, media_url, provider_message_id, sent_at, metadata
  ) values (
    p_conversation_id, v_contact_id, v_channel, 'outbound', 'text', p_text, null, 'stub_'||gen_random_uuid()::text, now(), '{}'::jsonb
  ) returning id into v_message_id;

  update public.conversations set last_message_at = now() where id = p_conversation_id;

  return v_message_id;
end;
$$;

revoke all on function public.respond_with_stub(uuid,text) from public;
grant execute on function public.respond_with_stub(uuid,text) to anon, authenticated;

create or replace function public.run_schedules_once()
returns integer
language plpgsql
security definer
set search_path = public as
$$
declare
  v_count integer := 0;
  rec record;
begin
  for rec in select s.id, s.post_id from public.social_schedules s where s.status = 'scheduled' and s.scheduled_at <= now() loop
    update public.social_schedules set status = 'running' where id = rec.id;
    perform public.publish_post_stub(rec.post_id);
    update public.social_schedules set status = 'failed' where id = rec.id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function public.run_schedules_once() from public;
grant execute on function public.run_schedules_once() to anon, authenticated;
