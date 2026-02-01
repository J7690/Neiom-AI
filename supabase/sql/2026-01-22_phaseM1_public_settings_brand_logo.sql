-- Phase M1 – Public settings access for non-sensitive keys (brand logo)

create or replace function public.get_public_setting(p_key text)
returns text
language plpgsql
security definer
set search_path = public as
$$
declare
  v_value text;
begin
  -- Only expose a small allowlist of non-sensitive settings to authenticated clients
  if p_key not in (
    'NEXIOM_BRAND_LOGO_PATH',
    'NEXIOM_BRAND_LOGO_POSITION',
    'NEXIOM_BRAND_LOGO_SIZE',
    'NEXIOM_BRAND_LOGO_OPACITY'
  ) then
    return null;
  end if;

  select value into v_value from public.app_settings where key = p_key;
  return v_value;
end;
$$;

revoke all on function public.get_public_setting(text) from public;
grant execute on function public.get_public_setting(text) to authenticated;
