-- Phase 3 – Audit réel du pipeline marketing / recommandations
-- A exécuter avec : python tools/admin_sql.py supabase/sql/2026-01-07_phase73_audit_marketing_brain.sql

-- 1) Schéma de la table studio_marketing_recommendations
select
  table_schema,
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'studio_marketing_recommendations'
order by ordinal_position;

-- 2) Aperçu des dernières recommandations stockées
select
  id,
  objective,
  recommendation_summary,
  reasoning,
  proposed_format,
  proposed_message,
  proposed_media_prompt,
  confidence_level,
  status,
  created_at,
  approved_at,
  approved_by,
  published_at,
  published_facebook_id
from public.studio_marketing_recommendations
order by created_at desc
limit 10;

-- 3) Schéma de studio_facebook_prepared_posts (pour le chaînage approbation → publication)
select
  table_schema,
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'studio_facebook_prepared_posts'
order by ordinal_position;

-- 4) Aperçu des posts préparés récents
select
  id,
  recommendation_id,
  final_message,
  media_type,
  status,
  created_at,
  updated_at
from public.studio_facebook_prepared_posts
order by created_at desc
limit 10;

-- 5) Signatures réelles des fonctions marketing clés
select
  n.nspname as schema,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as result_type,
  l.lanname as language
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
join pg_language l on l.oid = p.prolang
where n.nspname = 'public'
  and p.proname in (
    'generate_marketing_recommendation',
    'approve_marketing_recommendation',
    'reject_marketing_recommendation',
    'get_pending_recommendations',
    'create_marketing_alert',
    'analyze_performance_patterns'
  )
order by p.proname;

-- 6) Vérification basique des tables d’assets IA utilisées en aval
select
  table_schema,
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('generation_jobs', 'image_assets')
order by table_name, ordinal_position;

-- 7) Quelques jobs de génération récents
select
  id,
  type,
  prompt,
  model,
  status,
  job_mode,
  result_url,
  created_at
from public.generation_jobs
order by created_at desc
limit 10;
