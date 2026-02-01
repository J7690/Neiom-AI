-- Phase 8 – Instagram ingestion RPC + AI reply template + Auto-reply stub (NON DESTRUCTIF)

create or replace function public.ingest_instagram_webhook(p_body jsonb)
returns integer
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cnt integer := 0;
  e jsonb;
  ch jsonb;
  val jsonb;
  msg jsonb;
  event_id text;
  author_id text;
  author_name text;
  content text;
  ts text;
  ts_iso timestamptz;
begin
  if position('instagram' in lower(coalesce(p_body->>'object',''))) = 0 then
    return 0;
  end if;

  for e in select * from jsonb_array_elements(coalesce(p_body->'entry','[]'::jsonb)) loop
    -- style via changes.value.messages[]
    for ch in select * from jsonb_array_elements(coalesce(e->'changes','[]'::jsonb)) loop
      val := ch->'value';
      if (val ? 'messages') then
        for msg in select * from jsonb_array_elements(val->'messages') loop
          event_id := coalesce(msg->>'id', msg->>'mid', gen_random_uuid()::text);
          author_id := coalesce(msg->>'from', null);
          content := coalesce((msg->'text'->>'body'), msg->>'text', null);
          ts := coalesce(msg->>'timestamp', null);
          ts_iso := case when ts is not null then to_timestamp((ts)::bigint) else now() end;
          author_name := null;

          if author_id is not null and content is not null then
            perform public.ingest_route_analyze('instagram','message', event_id, author_id, author_name, content, ts_iso, msg);
            v_cnt := v_cnt + 1;
          end if;
        end loop;
      end if;
    end loop;

    -- style via messaging[] (similar to facebook)
    for msg in select * from jsonb_array_elements(coalesce(e->'messaging','[]'::jsonb)) loop
      event_id := coalesce(msg->'message'->>'mid', gen_random_uuid()::text);
      author_id := coalesce(msg->'sender'->>'id', null);
      content := coalesce(msg->'message'->>'text', null);
      ts := coalesce(msg->>'timestamp', null);
      ts_iso := case when ts is not null then to_timestamp(((ts)::bigint)/1000.0) else now() end;
      if author_id is not null and content is not null then
        perform public.ingest_route_analyze('instagram','message', event_id, author_id, null, content, ts_iso, msg);
        v_cnt := v_cnt + 1;
      end if;
    end loop;
  end loop;

  return v_cnt;
end;
$$;

grant execute on function public.ingest_instagram_webhook(jsonb) to anon, authenticated;

-- AI reply template (rule-based, no external tokens required)
create or replace function public.ai_reply_template(p_message_id uuid)
returns text
language plpgsql
security definer
set search_path = public as
$$
declare
  v_msg record;
  v_analysis record;
  v_text text := '';
  v_greet text := 'Bonjour,';
  v_body text := '';
  v_footer text := 'Cordialement, l''équipe Nexiom.';
begin
  select m.id, m.content_text, m.conversation_id into v_msg
  from public.messages m where m.id = p_message_id;
  if not found then raise exception 'message not found'; end if;

  select intent, sentiment, needs_escalation into v_analysis
  from public.message_analysis where message_id = p_message_id limit 1;

  if v_msg.content_text is null then
    v_body := ' merci pour votre message.';
  else
    if position('?' in v_msg.content_text) > 0 or coalesce(v_analysis.intent,'') = 'question' then
      v_body := ' merci pour votre question. Nous revenons vers vous avec plus de détails sous peu.';
    else
      v_body := ' merci pour votre message. Nous avons bien noté votre demande.';
    end if;
    if coalesce(v_analysis.needs_escalation,false) then
      v_body := v_body || ' Un membre de notre équipe va vous assister rapidement.';
    end if;
  end if;

  v_text := trim(v_greet || ' ' || v_body || ' ' || v_footer);
  return v_text;
end;
$$;

grant execute on function public.ai_reply_template(uuid) to anon, authenticated;

-- Auto reply stub: composes a reply and inserts an outbound message in the conversation
create or replace function public.auto_reply_stub(p_message_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare
  v_msg record;
  v_reply text;
  v_out uuid;
begin
  select id, conversation_id into v_msg from public.messages where id = p_message_id;
  if not found then raise exception 'message not found'; end if;
  v_reply := public.ai_reply_template(p_message_id);
  v_out := public.respond_with_stub(v_msg.conversation_id, v_reply);
  return v_out;
end;
$$;

grant execute on function public.auto_reply_stub(uuid) to anon, authenticated;
