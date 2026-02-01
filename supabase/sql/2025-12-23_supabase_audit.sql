-- Supabase meta audit: schemas, tables, functions, and key tables presence

-- 1) Basic context
select
  current_database() as db_name,
  current_schema()  as default_schema;

-- 2) List schemas
select schema_name
from information_schema.schemata
order by schema_name;

-- 3) List tables in main schemas (public, auth, storage)
select
  table_schema,
  table_name,
  table_type
from information_schema.tables
where table_schema in ('public', 'auth', 'storage')
order by table_schema, table_name;

-- 4) Check presence of key Nexiom tables
select
  'public.generation_jobs' as table_name,
  to_regclass('public.generation_jobs') is not null as exists;

select
  'public.image_assets' as table_name,
  to_regclass('public.image_assets') is not null as exists;

-- 5) List user-defined functions in public schema
select
  routine_schema,
  routine_name,
  routine_type,
  data_type
from information_schema.routines
where routine_schema = 'public'
order by routine_schema, routine_name;

-- 6) Check presence of admin_execute_sql RPC
select
  'public.admin_execute_sql' as function_name,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'admin_execute_sql'
  ) as exists;
