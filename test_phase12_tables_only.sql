-- Phase 12 Tables / Functions Only Test
-- Verifies presence of pipeline orchestrator and settings functions

-- 1) Core tables
SELECT 'app_settings' AS table_name,
       to_regclass('public.app_settings') IS NOT NULL AS exists;

SELECT 'messages' AS table_name,
       to_regclass('public.messages') IS NOT NULL AS exists;

SELECT 'social_posts' AS table_name,
       to_regclass('public.social_posts') IS NOT NULL AS exists;

SELECT 'social_schedules' AS table_name,
       to_regclass('public.social_schedules') IS NOT NULL AS exists;

-- 2) Functions
SELECT 'run_pipeline_once' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'run_pipeline_once'
       ) AS exists;

SELECT 'settings_overview' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'settings_overview'
       ) AS exists;
