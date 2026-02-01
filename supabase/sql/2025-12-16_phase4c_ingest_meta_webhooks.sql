-- Phase 4c – Meta Webhooks ingestion via RPC (NON DESTRUCTIF)

-- WhatsApp webhook JSON -> normalized ingest + route + analyze
create or replace function public.ingest_whatsapp_webhook(p_body jsonb)
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
  if coalesce(p_body->>'object','') not like '%whatsapp%' then
    return 0;
  end if;

  for e in select * from jsonb_array_elements(p_body->'entry') loop
    for ch in select * from jsonb_array_elements(coalesce(e->'changes','[]'::jsonb)) loop
      val := ch->'value';
      if (val ? 'messages') then
        for msg in select * from jsonb_array_elements(val->'messages') loop
          event_id := msg->>'id';
          author_id := coalesce(msg->>'from', null);
          content := coalesce((msg->'text'->>'body'), null);
          ts := coalesce(msg->>'timestamp', null);
          if ts is not null then
            ts_iso := to_timestamp((ts)::bigint);
          else
            ts_iso := now();
          end if;
          author_name := coalesce(val->'contacts'->0->'profile'->>'name', null);

          if event_id is not null and author_id is not null and content is not null then
            perform public.ingest_route_analyze('whatsapp','message', event_id, author_id, author_name, content, ts_iso, msg);
            v_cnt := v_cnt + 1;
          end if;
        end loop;
      end if;
    end loop;
  end loop;

  return v_cnt;
end;
$$;

grant execute on function public.ingest_whatsapp_webhook(jsonb) to anon, authenticated;

-- Facebook Page webhook JSON -> normalized ingest + route + analyze (messages only)
create or replace function public.ingest_facebook_webhook(p_body jsonb)
returns integer
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cnt integer := 0;
  e jsonb;
  ev jsonb;
  msg jsonb;
  event_id text;
  author_id text;
  content text;
  ts_ms text;
  ts_iso timestamptz;
begin
  if coalesce(p_body->>'object','') <> 'page' then
    return 0;
  end if;

  for e in select * from jsonb_array_elements(p_body->'entry') loop
    for ev in select * from jsonb_array_elements(coalesce(e->'messaging','[]'::jsonb)) loop
      msg := ev->'message';
      if msg is not null then
        event_id := coalesce(msg->>'mid', ev->>'message_id');
        author_id := coalesce(ev->'sender'->>'id', null);
        content := coalesce(msg->>'text', null);
        ts_ms := coalesce(ev->>'timestamp', null);
        if ts_ms is not null then
          ts_iso := to_timestamp(((ts_ms)::bigint)/1000.0);
        else
          ts_iso := now();
        end if;

        if author_id is not null and content is not null then
          perform public.ingest_route_analyze('facebook','message', coalesce(event_id, gen_random_uuid()::text), author_id, null, content, ts_iso, ev);
          v_cnt := v_cnt + 1;
        end if;
      end if;
    end loop;
  end loop;

  return v_cnt;
end;
$$;

grant execute on function public.ingest_facebook_webhook(jsonb) to anon, authenticated;

-- Router that detects payload type and dispatches
create or replace function public.ingest_meta_webhook(p_body jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  w integer := 0;
  f integer := 0;
begin
  w := public.ingest_whatsapp_webhook(p_body);
  f := public.ingest_facebook_webhook(p_body);
  return jsonb_build_object('whatsapp_count', w, 'facebook_count', f);
end;
$$;

grant execute on function public.ingest_meta_webhook(jsonb) to anon, authenticated;
