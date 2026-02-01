-- Phase 9 – Batch routing for webhook_events via RPC (NON DESTRUCTIF)

alter table if exists public.webhook_events
  add column if not exists routed_at timestamptz;

create or replace function public.route_webhook_event(
  p_channel text,
  p_event_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
DECLARE
  v_evt public.webhook_events%rowtype;
  v_contact_id uuid;
  v_conversation_id uuid;
  v_message_id uuid;
  v_external_id text;
BEGIN
  select * into v_evt from public.webhook_events where channel = lower(p_channel) and event_id = p_event_id;
  if not found then
    raise exception 'event not found';
  end if;

  v_external_id := v_evt.author_id;

  if v_external_id is not null then
    select cc.contact_id into v_contact_id
      from public.contact_channels cc
      where cc.channel = lower(p_channel)
        and cc.external_id = v_external_id
      limit 1;

    if v_contact_id is null then
      insert into public.contacts(full_name, metadata)
      values (v_evt.author_name, '{}'::jsonb)
      returning id into v_contact_id;

      insert into public.contact_channels(contact_id, channel, external_id, display_name, metadata)
      values (v_contact_id, lower(p_channel), v_external_id, v_evt.author_name, '{}'::jsonb);
    end if;
  end if;

  select c.id into v_conversation_id
  from public.conversations c
  where c.contact_id = v_contact_id
    and c.channel = lower(p_channel)
    and c.status = 'open'
  order by c.created_at desc
  limit 1;

  if v_conversation_id is null then
    insert into public.conversations(contact_id, channel, status, last_message_at)
    values (v_contact_id, lower(p_channel), 'open', coalesce(v_evt.event_date, now()))
    returning id into v_conversation_id;
  end if;

  begin
    insert into public.messages(
      conversation_id, contact_id, channel, direction, message_type, content_text, media_url, provider_message_id, sent_at, metadata
    ) values (
      v_conversation_id, v_contact_id, lower(p_channel), 'inbound', 'text', v_evt.content, null, v_evt.event_id, coalesce(v_evt.event_date, now()), '{}'::jsonb
    ) returning id into v_message_id;
  exception when unique_violation then
    select id into v_message_id
    from public.messages
    where channel = lower(p_channel) and provider_message_id = v_evt.event_id
    limit 1;
  end;

  update public.conversations
    set last_message_at = coalesce(v_evt.event_date, now())
    where id = v_conversation_id;

  update public.webhook_events
    set conversation_id = v_conversation_id,
        routed_at = now()
    where channel = lower(p_channel) and event_id = p_event_id;

  return jsonb_build_object('conversation_id', v_conversation_id, 'message_id', v_message_id);
END;
$$;

revoke all on function public.route_webhook_event(text,text) from public;
grant execute on function public.route_webhook_event(text,text) to anon, authenticated;

create or replace function public.route_unrouted_events(
  p_channel text default null,
  p_limit integer default 100
)
returns integer
language plpgsql
security definer
set search_path = public as
$$
DECLARE
  v_count integer := 0;
  rec record;
  v_msg_id uuid;
  v_conv_id uuid;
BEGIN
  for rec in
    select channel, event_id from public.webhook_events
    where routed_at is null and (p_channel is null or channel = lower(p_channel))
    order by event_date asc nulls last
    limit p_limit
  loop
    -- If a message already exists for this (channel,event_id), mark as routed idempotently
    select id, conversation_id into v_msg_id, v_conv_id
    from public.messages
    where channel = rec.channel and provider_message_id = rec.event_id
    limit 1;

    if v_msg_id is not null then
      update public.webhook_events
        set conversation_id = v_conv_id,
            routed_at = now()
        where channel = rec.channel and event_id = rec.event_id;
    else
      perform public.route_webhook_event(rec.channel, rec.event_id);
    end if;
    v_count := v_count + 1;
  end loop;
  return v_count;
END;
$$;

grant execute on function public.route_unrouted_events(text,integer) to anon, authenticated;
