revoke all on table public.app_settings from public;
revoke all on table public.app_settings from anon;
revoke all on table public.app_settings from authenticated;

grant select on table public.app_settings to service_role;

revoke execute on function public.get_setting(text) from public;
revoke execute on function public.get_setting(text) from anon;
revoke execute on function public.get_setting(text) from authenticated;

grant execute on function public.get_setting(text) to service_role;

revoke execute on function public.set_setting(text,text) from public;
revoke execute on function public.set_setting(text,text) from anon;
revoke execute on function public.set_setting(text,text) from authenticated;

grant execute on function public.set_setting(text,text) to service_role;

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
