-- Phase 13 Readiness Audit
-- Editorial plan, recent activity, metrics timeseries, settings upsert

-- 1) Core tables used by Phase 13
SELECT 'social_posts' AS table_name,
       to_regclass('public.social_posts') IS NOT NULL AS exists;

SELECT 'social_schedules' AS table_name,
       to_regclass('public.social_schedules') IS NOT NULL AS exists;

SELECT 'messages' AS table_name,
       to_regclass('public.messages') IS NOT NULL AS exists;

SELECT 'leads' AS table_name,
       to_regclass('public.leads') IS NOT NULL AS exists;

SELECT 'app_settings' AS table_name,
       to_regclass('public.app_settings') IS NOT NULL AS exists;

-- 2) Check Phase 13 functions
SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'create_editorial_plan_stub',
    'get_recent_activity',
    'get_metrics_timeseries',
    'upsert_setting'
  )
ORDER BY p.proname;

-- 3) Quick aggregates for sanity
SELECT 'messages_total' AS metric,
       COUNT(*) AS value
FROM public.messages
UNION ALL
SELECT 'social_posts_total' AS metric,
       COUNT(*) AS value
FROM public.social_posts
UNION ALL
SELECT 'social_schedules_total' AS metric,
       COUNT(*) AS value
FROM public.social_schedules
UNION ALL
SELECT 'leads_total' AS metric,
       COUNT(*) AS value
FROM public.leads;
