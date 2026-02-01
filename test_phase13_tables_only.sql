-- Phase 13 Tables / Functions Only Test
-- Verifies presence of editorial plan, activity, metrics, and settings tools

-- 1) Core tables
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

-- 2) Functions
SELECT 'create_editorial_plan_stub' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'create_editorial_plan_stub'
       ) AS exists;

SELECT 'get_recent_activity' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'get_recent_activity'
       ) AS exists;

SELECT 'get_metrics_timeseries' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'get_metrics_timeseries'
       ) AS exists;

SELECT 'upsert_setting' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'upsert_setting'
       ) AS exists;
