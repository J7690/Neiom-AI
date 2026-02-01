-- Phase 4d – Meta security helpers (RPC) and pgcrypto (NON DESTRUCTIF)

create extension if not exists pgcrypto;

-- Hardened verify_whatsapp_challenge: STABLE and reads from app_settings directly
create or replace function public.verify_whatsapp_challenge(
  mode text,
  verify_token text,
  challenge text
)
returns text
language plpgsql
security definer
stable
set search_path = public as
$$
declare
  expected_token text;
begin
  select value into expected_token from public.app_settings where key = 'WHATSAPP_VERIFY_TOKEN';
  if mode = 'subscribe' and verify_token is not null and expected_token is not null and verify_token = expected_token then
    return challenge;
  else
    raise exception 'unauthorized';
  end if;
end;
$$;

grant execute on function public.verify_whatsapp_challenge(text,text,text) to anon, authenticated;

-- Do NOT expose get_setting to anon
revoke execute on function public.get_setting(text) from anon;

-- Verify Meta signature helper
create or replace function public.verify_meta_signature(
  signature_header text,
  body_text text
)
returns boolean
language plpgsql
security definer
stable
set search_path = public as
$$
declare
  secret text;
  computed text;
  expected text;
begin
  select value into secret from public.app_settings where key = 'META_APP_SECRET';
  if secret is null then
    return false;
  end if;
  computed := encode(hmac(convert_to(coalesce(body_text,''),'utf8'), convert_to(secret,'utf8'), 'sha256'), 'hex');
  expected := 'sha256=' || lower(computed);
  return lower(coalesce(signature_header,'')) = expected;
end;
$$;

grant execute on function public.verify_meta_signature(text,text) to anon, authenticated;

-- Receive Meta webhook via RPC: checks signature then ingests/dispatches
create or replace function public.receive_meta_webhook(
  signature_header text,
  body jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  if not public.verify_meta_signature(signature_header, body::text) then
    raise exception 'invalid signature';
  end if;
  return public.ingest_meta_webhook(body);
end;
$$;

grant execute on function public.receive_meta_webhook(text,jsonb) to anon, authenticated;
