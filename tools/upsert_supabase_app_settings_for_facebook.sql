-- Configure SUPABASE_URL et SUPABASE_ANON_KEY dans app_settings pour les appels Edge
insert into public.app_settings(key, value, updated_at)
values
  ('SUPABASE_URL', '<SUPABASE_URL>', now()),
  ('SUPABASE_ANON_KEY', '<SUPABASE_ANON_KEY>', now())
on conflict (key) do update set
  value = excluded.value,
  updated_at = now();
