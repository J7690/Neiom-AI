-- Phase 10 Readiness Audit
-- Admin observability & comment simulation

-- 1) Core tables used by get_pipeline_stats
SELECT 'contacts' AS table_name,
       to_regclass('public.contacts') IS NOT NULL AS exists;

SELECT 'contact_channels' AS table_name,
       to_regclass('public.contact_channels') IS NOT NULL AS exists;

SELECT 'conversations' AS table_name,
       to_regclass('public.conversations') IS NOT NULL AS exists;

SELECT 'messages' AS table_name,
       to_regclass('public.messages') IS NOT NULL AS exists;

SELECT 'webhook_events' AS table_name,
       to_regclass('public.webhook_events') IS NOT NULL AS exists;

SELECT 'social_posts' AS table_name,
       to_regclass('public.social_posts') IS NOT NULL AS exists;

SELECT 'social_schedules' AS table_name,
       to_regclass('public.social_schedules') IS NOT NULL AS exists;

SELECT 'social_metrics' AS table_name,
       to_regclass('public.social_metrics') IS NOT NULL AS exists;

SELECT 'leads' AS table_name,
       to_regclass('public.leads') IS NOT NULL AS exists;

-- 2) Check key functions for Phase 10
SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'get_pipeline_stats',
    'simulate_comment',
    'ingest_route_analyze'
  )
ORDER BY p.proname;

-- 3) Quick view of pipeline stats (if function exists)
SELECT CASE
         WHEN EXISTS (
           SELECT 1 FROM pg_proc p
           JOIN pg_namespace n ON p.pronamespace = n.oid
           WHERE n.nspname = 'public'
             AND p.proname = 'get_pipeline_stats'
         )
         THEN 'get_pipeline_stats_available'
         ELSE 'get_pipeline_stats_missing'
       END AS status;
