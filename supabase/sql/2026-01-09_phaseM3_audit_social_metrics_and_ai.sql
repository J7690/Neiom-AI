-- Phase M3 – Audit des métriques sociales et fonctions IA liées aux missions
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseM3_audit_social_metrics_and_ai.sql

-- 1) Tables sociales principales (Facebook / multi-réseaux)
select table_schema, table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'facebook_pages',
    'facebook_posts',
    'facebook_post_insights',
    'facebook_insights',
    'social_accounts',
    'social_insights_daily',
    'social_posts',
    'social_post_insights'
  )
order by table_name;

-- 3) Fonctions RPC d'overview de performance sociale
select
  n.nspname as schema,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as result_type
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_facebook_post_performance_overview',
    'get_objective_performance_summary',
    'generate_performance_predictions',
    'analyze_advanced_patterns'
  )
order by p.proname;

-- 4) Vérifier l'existence éventuelle d'une Edge Function mission-brain côté SQL (trace)
select 'missions_table_exists' as step,
       (select count(*) from information_schema.tables where table_schema = 'public' and table_name = 'studio_marketing_missions') as missions_table_count;
