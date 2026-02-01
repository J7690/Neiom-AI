-- Phase M2 – Audit marketing objectives & missions
-- Exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseM2_audit_marketing_objectives_missions.sql

-- 1) Schéma réel de studio_marketing_objectives
select
  table_schema,
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'studio_marketing_objectives'
order by ordinal_position;

-- 2) Vérifier l'existence éventuelle de studio_marketing_missions
select
  table_schema,
  table_name
from information_schema.tables
where table_schema = 'public'
  and table_name = 'studio_marketing_missions';

-- 3) Compter les objectifs marketing actuels
select
  'objectives_counts' as step,
  status,
  count(*) as cnt
from public.studio_marketing_objectives
group by status
order by status;

-- 4) Lister quelques fonctions RPC liées au marketing
select
  n.nspname as schema,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as result_type
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_marketing_objectives',
    'get_marketing_objective_state',
    'create_content_jobs_from_objective'
  )
order by p.proname;
