-- Phase MI – Audit global orchestrateur de publication (READ-ONLY)
-- Objectif : vérifier le schéma réel (tables & RPC) pour les missions,
-- content_jobs, posts sociaux et planning avant d’implémenter
-- un orchestrateur global multi-missions.

-- 1) Tables clés présentes
select
  table_schema,
  table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'studio_marketing_objectives',
    'studio_marketing_missions',
    'content_jobs',
    'social_posts',
    'social_schedules',
    'studio_marketing_recommendations',
    'studio_facebook_prepared_posts',
    'studio_mission_intelligence_reports'
  )
order by table_name;

-- 2) Colonnes des tables clés
select
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length,
  numeric_precision,
  numeric_scale
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'studio_marketing_objectives',
    'studio_marketing_missions',
    'content_jobs',
    'social_posts',
    'social_schedules',
    'studio_marketing_recommendations',
    'studio_facebook_prepared_posts',
    'studio_mission_intelligence_reports'
  )
order by table_name, ordinal_position;

-- 3) Indexes existants sur ces tables
select
  schemaname,
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename in (
    'studio_marketing_objectives',
    'studio_marketing_missions',
    'content_jobs',
    'social_posts',
    'social_schedules',
    'studio_marketing_recommendations',
    'studio_facebook_prepared_posts',
    'studio_mission_intelligence_reports'
  )
order by tablename, indexname;

-- 4) Contraintes (PK, FK, CHECK, UNIQUE) sur ces tables
select
  table_name,
  constraint_name,
  constraint_type
from information_schema.table_constraints
where table_schema = 'public'
  and table_name in (
    'studio_marketing_objectives',
    'studio_marketing_missions',
    'content_jobs',
    'social_posts',
    'social_schedules',
    'studio_marketing_recommendations',
    'studio_facebook_prepared_posts',
    'studio_mission_intelligence_reports'
  )
order by table_name, constraint_name;

-- 5) Volume actuel des tables clés (pour avoir un ordre de grandeur)
select 'studio_marketing_objectives' as table_name, count(*) as row_count from public.studio_marketing_objectives
union all
select 'studio_marketing_missions', count(*) from public.studio_marketing_missions
union all
select 'content_jobs', count(*) from public.content_jobs
union all
select 'social_posts', count(*) from public.social_posts
union all
select 'social_schedules', count(*) from public.social_schedules
union all
select 'studio_marketing_recommendations', count(*) from public.studio_marketing_recommendations
union all
select 'studio_facebook_prepared_posts', count(*) from public.studio_facebook_prepared_posts
union all
select 'studio_mission_intelligence_reports', count(*) from public.studio_mission_intelligence_reports;

-- 6) Fonctions / RPC critiques pour le planning & l’orchestration
select
  n.nspname as schema,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as result_type,
  p.prokind,
  p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    -- Missions / content_jobs
    'create_content_jobs_from_mission',
    'schedule_content_jobs_for_mission',
    'create_content_jobs_from_objective',
    'schedule_content_job',
    -- Planning social & Facebook
    'schedule_facebook_publication',
    'schedule_facebook_publication_smart',
    'get_best_facebook_time_for_topic',
    'get_best_facebook_time_summary',
    'create_and_schedule_post_stub',
    -- Calendrier & activité
    'list_calendar',
    'create_editorial_plan_stub',
    'get_recent_activity',
    'get_metrics_timeseries',
    -- Marketing / mission intelligence
    'get_marketing_objectives',
    'get_marketing_objective_state',
    'get_latest_mission_intelligence_report'
  )
order by p.proname;

-- 7) Droits d’exécution sur ces fonctions (pour vérifier ce qui est callable depuis Flutter)
select
  r.routine_schema as schema,
  r.routine_name as function_name,
  p.grantee,
  p.privilege_type
from information_schema.routines r
join information_schema.routine_privileges p
  on p.specific_schema = r.specific_schema
 and p.specific_name = r.specific_name
where r.routine_schema = 'public'
  and r.routine_name in (
    'create_content_jobs_from_mission',
    'schedule_content_jobs_for_mission',
    'create_content_jobs_from_objective',
    'schedule_content_job',
    'schedule_facebook_publication',
    'schedule_facebook_publication_smart',
    'get_best_facebook_time_for_topic',
    'get_best_facebook_time_summary',
    'create_and_schedule_post_stub',
    'list_calendar',
    'create_editorial_plan_stub',
    'get_recent_activity',
    'get_metrics_timeseries',
    'get_marketing_objectives',
    'get_marketing_objective_state',
    'get_latest_mission_intelligence_report'
  )
order by r.routine_name, p.grantee, p.privilege_type;
