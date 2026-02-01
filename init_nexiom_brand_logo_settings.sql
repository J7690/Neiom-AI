-- Init / update Nexiom brand logo public settings (idempotent)
-- Utilisé via tools/admin_sql.py et l'RPC public.admin_execute_sql

insert into public.app_settings(key, value, updated_at)
values
  ('NEXIOM_BRAND_LOGO_PATH',     'logo de marque/1766323271626_nexiom_logo_variation_2.png', now()),
  ('NEXIOM_BRAND_LOGO_POSITION', 'bottom_right',                                            now()),
  ('NEXIOM_BRAND_LOGO_SIZE',     '0.18',                                                    now()),
  ('NEXIOM_BRAND_LOGO_OPACITY',  '0.9',                                                     now())
on conflict (key) do update set
  value      = excluded.value,
  updated_at = now();
