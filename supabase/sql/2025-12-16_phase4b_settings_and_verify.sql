-- Phase 4b – Settings store + WhatsApp GET verification via RPC (NON DESTRUCTIF)

create table if not exists public.app_settings (
  key text primary key,
  value text,
  updated_at timestamptz not null default now()
);

create or replace function public.set_setting(p_key text, p_value text)
returns void
language plpgsql
security definer
set search_path = public as
$$
begin
  insert into public.app_settings(key, value, updated_at)
  values (p_key, p_value, now())
  on conflict (key) do update set value = excluded.value, updated_at = now();
end;
$$;

create or replace function public.get_setting(p_key text)
returns text
language sql
security definer
set search_path = public as
$$
  select value from public.app_settings where key = p_key;
$$;

revoke all on table public.app_settings from anon;
revoke all on table public.app_settings from authenticated;
grant select on table public.app_settings to service_role;

revoke all on function public.set_setting(text,text) from public;
revoke all on function public.get_setting(text) from public;
revoke execute on function public.set_setting(text,text) from anon;
revoke execute on function public.set_setting(text,text) from authenticated;
revoke execute on function public.get_setting(text) from anon;
revoke execute on function public.get_setting(text) from authenticated;
grant execute on function public.set_setting(text,text) to service_role;
grant execute on function public.get_setting(text) to service_role;

-- WhatsApp GET challenge verifier as RPC (usable at /rest/v1/rpc/verify_whatsapp_challenge)
-- Call as GET: .../rest/v1/rpc/verify_whatsapp_challenge?mode=subscribe&verify_token=...&challenge=...
create or replace function public.verify_whatsapp_challenge(
  mode text,
  verify_token text,
  challenge text
)
returns text
language plpgsql
security definer
set search_path = public as
$$
declare
  expected_token text;
begin
  select value into expected_token from public.app_settings where key = 'WHATSAPP_VERIFY_TOKEN';
  if mode = 'subscribe' and verify_token is not null and verify_token = expected_token then
    return challenge;
  else
    raise exception 'unauthorized';
  end if;
end;
$$;

grant execute on function public.verify_whatsapp_challenge(text,text,text) to anon, authenticated;
