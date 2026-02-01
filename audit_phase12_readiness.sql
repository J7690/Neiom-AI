-- Phase 12 Readiness Audit
-- Pipeline orchestrator and settings overview

-- 1) Core tables / settings
SELECT 'app_settings' AS table_name,
       to_regclass('public.app_settings') IS NOT NULL AS exists;

SELECT 'messages' AS table_name,
       to_regclass('public.messages') IS NOT NULL AS exists;

SELECT 'social_posts' AS table_name,
       to_regclass('public.social_posts') IS NOT NULL AS exists;

SELECT 'social_schedules' AS table_name,
       to_regclass('public.social_schedules') IS NOT NULL AS exists;

-- 2) Check Phase 12 functions and their dependencies
SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'run_pipeline_once',
    'settings_overview',
    'route_unrouted_events',
    'auto_reply_recent_inbound',
    'run_schedules_once',
    'collect_metrics_stub'
  )
ORDER BY p.proname;

-- 3) Current settings overview (if function exists)
SELECT CASE
         WHEN EXISTS (
           SELECT 1 FROM pg_proc p
           JOIN pg_namespace n ON p.pronamespace = n.oid
           WHERE n.nspname = 'public'
             AND p.proname = 'settings_overview'
         )
         THEN 'settings_overview_available'
         ELSE 'settings_overview_missing'
       END AS status;
