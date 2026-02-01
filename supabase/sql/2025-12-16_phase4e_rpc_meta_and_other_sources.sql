-- Phase 4e – Finalize RPC-only webhook receivers and additional sources (NON DESTRUCTIF)

-- Receive Meta webhook via RPC: header read from PostgREST GUC
-- Call as POST to /rest/v1/rpc/receive_meta_webhook with JSON body (Content-Type: application/json)
create or replace function public.receive_meta_webhook(
  body jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_sig text;
begin
  -- PostgREST exposes request headers as GUCs: request.header.<lowercase-header-name>
  v_sig := current_setting('request.header.x-hub-signature-256', true);
  if not public.verify_meta_signature(v_sig, body::text) then
    raise exception 'invalid signature';
  end if;
  return public.ingest_meta_webhook(body);
end;
$$;

grant execute on function public.receive_meta_webhook(jsonb) to anon, authenticated;

-- TikTok webhook via RPC (minimal): accepts provider JSON and normalizes as message/comment events
create or replace function public.ingest_tiktok_webhook(p_body jsonb)
returns integer
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cnt integer := 0;
  ev jsonb;
  event_id text;
  author_id text;
  author_name text;
  content text;
  ts_iso timestamptz;
begin
  for ev in select * from jsonb_array_elements(coalesce(p_body->'events','[]'::jsonb)) loop
    event_id := coalesce(ev->>'id', gen_random_uuid()::text);
    author_id := coalesce(ev->>'user_id', ev->>'author_id');
    author_name := coalesce(ev->>'user_name', ev->>'author_name');
    content := coalesce(ev->>'text', ev->>'comment', ev->>'message');
    ts_iso := coalesce(to_timestamp((ev->>'timestamp')::bigint), now());
    if content is not null then
      perform public.ingest_route_analyze('tiktok', 'message', event_id, author_id, author_name, content, ts_iso, ev);
      v_cnt := v_cnt + 1;
    end if;
  end loop;
  return v_cnt;
end;
$$;

grant execute on function public.ingest_tiktok_webhook(jsonb) to anon, authenticated;

-- YouTube webhook via RPC (minimal): accepts provider JSON and normalizes as message/comment events
create or replace function public.ingest_youtube_webhook(p_body jsonb)
returns integer
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cnt integer := 0;
  ev jsonb;
  event_id text;
  author_id text;
  author_name text;
  content text;
  ts_iso timestamptz;
begin
  for ev in select * from jsonb_array_elements(coalesce(p_body->'events','[]'::jsonb)) loop
    event_id := coalesce(ev->>'id', gen_random_uuid()::text);
    author_id := coalesce(ev->>'author_id', null);
    author_name := coalesce(ev->>'author_name', null);
    content := coalesce(ev->>'text', ev->>'comment', ev->>'message');
    ts_iso := coalesce(to_timestamp((ev->>'timestamp')::bigint), now());
    if content is not null then
      perform public.ingest_route_analyze('youtube', 'message', event_id, author_id, author_name, content, ts_iso, ev);
      v_cnt := v_cnt + 1;
    end if;
  end loop;
  return v_cnt;
end;
$$;

grant execute on function public.ingest_youtube_webhook(jsonb) to anon, authenticated;
