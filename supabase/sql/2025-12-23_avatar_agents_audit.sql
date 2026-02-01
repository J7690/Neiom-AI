-- Audit des briques avatar / génération / agents dans le schéma public

-- 1) Tables clés
select 'avatar_profiles'  as table_name, to_regclass('public.avatar_profiles')  is not null as exists
union all
select 'image_agents'     as table_name, to_regclass('public.image_agents')     is not null as exists
union all
select 'avatar_previews'  as table_name, to_regclass('public.avatar_previews')  is not null as exists
union all
select 'generation_jobs'  as table_name, to_regclass('public.generation_jobs')  is not null as exists
union all
select 'image_assets'     as table_name, to_regclass('public.image_assets')     is not null as exists
union all
select 'video_segments'   as table_name, to_regclass('public.video_segments')   is not null as exists
;

-- 2) Détail des colonnes pour les tables avatar & agents
select
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('avatar_profiles', 'image_agents', 'avatar_previews')
order by table_name, ordinal_position;

-- 3) Fonctions Postgres pertinentes
select
  n.nspname                            as schema,
  p.proname                            as function_name,
  pg_get_function_identity_arguments(p.oid) as args,
  pg_get_userbyid(p.proowner)         as owner
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'admin_execute_sql',
    'get_avatar_profiles',
    'get_image_agents',
    'get_avatar_previews'
  )
order by function_name;
