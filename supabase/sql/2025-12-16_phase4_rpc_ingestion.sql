-- Phase 4 – RPC-only ingestion, routing, analysis, publishing, metrics (NON DESTRUCTIF)
-- All logic is exposed as SECURITY DEFINER RPC functions to comply with RPC-admin-only execution.

-- 1) Ingest a normalized webhook event (idempotent on (channel,event_id))
create or replace function public.ingest_webhook_event(
  p_channel text,
  p_type text,
  p_event_id text,
  p_author_id text,
  p_author_name text,
  p_content text,
  p_event_date timestamptz,
  p_post_id text,
  p_conversation_id uuid,
  p_raw_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
DECLARE
  v_row public.webhook_events%rowtype;
BEGIN
  insert into public.webhook_events(
    channel, type, event_id, author_id, author_name, content, event_date, post_id, conversation_id, raw_payload
  ) values (
    lower(p_channel), case when p_type = 'comment' then 'comment' else 'message' end, p_event_id,
    p_author_id, p_author_name, p_content, coalesce(p_event_date, now()), p_post_id, p_conversation_id, coalesce(p_raw_payload, '{}'::jsonb)
  )
  on conflict (channel, event_id) do update set
    author_id = excluded.author_id,
    author_name = excluded.author_name,
    content = excluded.content,
    event_date = excluded.event_date,
    post_id = excluded.post_id,
    conversation_id = excluded.conversation_id,
    raw_payload = excluded.raw_payload
  returning * into v_row;

  return to_jsonb(v_row);
END;
$$;

revoke all on function public.ingest_webhook_event(text,text,text,text,text,text,timestamptz,text,uuid,jsonb) from public;
grant execute on function public.ingest_webhook_event(text,text,text,text,text,text,timestamptz,text,uuid,jsonb) to anon, authenticated;

-- 2) Route a stored event to conversations/messages (contact+channel upsert; conversation upsert; message insert)
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

  insert into public.messages(
    conversation_id, contact_id, channel, direction, message_type, content_text, media_url, provider_message_id, sent_at, metadata
  ) values (
    v_conversation_id, v_contact_id, lower(p_channel), 'inbound', 'text', v_evt.content, null, v_evt.event_id, coalesce(v_evt.event_date, now()), '{}'::jsonb
  ) returning id into v_message_id;

  update public.conversations
    set last_message_at = coalesce(v_evt.event_date, now())
    where id = v_conversation_id;

  return jsonb_build_object('conversation_id', v_conversation_id, 'message_id', v_message_id);
END;
$$;

revoke all on function public.route_webhook_event(text,text) from public;
grant execute on function public.route_webhook_event(text,text) to anon, authenticated;

-- 3) Simple analyzer without external tokens
create or replace function public.analyze_message_simple(
  p_message_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
DECLARE
  v_msg record;
  v_intent text;
  v_sentiment text := 'neutral';
  v_conf numeric := 0.5;
  v_escalate boolean := false;
  v_existing uuid;
  v_meta jsonb;
BEGIN
  select m.id, m.content_text, m.conversation_id into v_msg
  from public.messages m where m.id = p_message_id;
  if not found then raise exception 'message not found'; end if;

  if v_msg.content_text is null then
    v_intent := 'other';
  else
    if position('?' in v_msg.content_text) > 0 then v_intent := 'question'; else v_intent := 'statement'; end if;
    if v_msg.content_text ~* '(urgent|help|assistance|support|problem|issue)' then v_escalate := true; end if;
  end if;

  select id into v_existing from public.message_analysis where message_id = p_message_id limit 1;
  if v_existing is null then
    insert into public.message_analysis(message_id, intent, sentiment, confidence, needs_escalation, metadata)
    values (p_message_id, v_intent, v_sentiment, v_conf, v_escalate, '{}'::jsonb);
  else
    update public.message_analysis
      set intent = v_intent,
          sentiment = v_sentiment,
          confidence = v_conf,
          needs_escalation = v_escalate,
          updated_at = now()
      where id = v_existing;
  end if;

  if v_escalate then
    select metadata into v_meta from public.conversations where id = v_msg.conversation_id;
    if v_meta is null then v_meta := '{}'::jsonb; end if;
    update public.conversations set metadata = v_meta || jsonb_build_object('needs_escalation', true)
    where id = v_msg.conversation_id;
  end if;

  return jsonb_build_object('message_id', p_message_id, 'intent', v_intent, 'sentiment', v_sentiment, 'confidence', v_conf, 'needs_escalation', v_escalate);
END;
$$;

revoke all on function public.analyze_message_simple(uuid) from public;
grant execute on function public.analyze_message_simple(uuid) to anon, authenticated;

-- 4) Publish stub (no tokens)
create or replace function public.publish_post_stub(
  p_post_id uuid
)
returns void
language plpgsql
security definer
set search_path = public as
$$
DECLARE
  v_post record;
  ch text;
BEGIN
  select id, target_channels into v_post from public.social_posts where id = p_post_id;
  if not found then raise exception 'post not found'; end if;

  update public.social_posts set status = 'publishing', updated_at = now() where id = p_post_id;

  foreach ch in array coalesce(v_post.target_channels, '{}'::text[]) loop
    insert into public.publish_logs(post_id, channel, status, error_message, provider_response)
    values (p_post_id, ch, 'error', 'Provider tokens not configured', '{}'::jsonb);
  end loop;

  update public.social_posts set status = 'failed', updated_at = now() where id = p_post_id;
END;
$$;

revoke all on function public.publish_post_stub(uuid) from public;
grant execute on function public.publish_post_stub(uuid) to anon, authenticated;

-- 5) Metrics collector stub (no tokens)
create or replace function public.collect_metrics_stub()
returns integer
language plpgsql
security definer
set search_path = public as
$$
DECLARE
  v_count integer := 0;
  rec record;
  ch text;
BEGIN
  for rec in select id, target_channels from public.social_posts where coalesce(status, 'draft') <> 'draft' loop
    foreach ch in array coalesce(rec.target_channels, '{}'::text[]) loop
      insert into public.social_metrics(post_id, channel, impressions, views, likes, comments, shares, engagement_rate, fetched_at)
      values (rec.id, ch, null, null, null, null, null, null, now());
      v_count := v_count + 1;
    end loop;
  end loop;
  return v_count;
END;
$$;

revoke all on function public.collect_metrics_stub() from public;
grant execute on function public.collect_metrics_stub() to anon, authenticated;

-- 6) Convenience: ingest + route + analyze in one RPC
create or replace function public.ingest_route_analyze(
  p_channel text,
  p_type text,
  p_event_id text,
  p_author_id text,
  p_author_name text,
  p_content text,
  p_event_date timestamptz,
  p_raw_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
DECLARE
  v_res jsonb;
  v_msg_id uuid;
BEGIN
  perform public.ingest_webhook_event(p_channel, p_type, p_event_id, p_author_id, p_author_name, p_content, p_event_date, null, null, p_raw_payload);
  v_res := public.route_webhook_event(p_channel, p_event_id);
  v_msg_id := (v_res->>'message_id')::uuid;
  perform public.analyze_message_simple(v_msg_id);
  return v_res;
END;
$$;

revoke all on function public.ingest_route_analyze(text,text,text,text,text,text,timestamptz,jsonb) from public;
grant execute on function public.ingest_route_analyze(text,text,text,text,text,text,timestamptz,jsonb) to anon, authenticated;
