-- Phase 10 Tables / Functions Only Test
-- Verifies presence of core tables and observability functions

-- 1) Core tables
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

-- 2) Functions
SELECT 'get_pipeline_stats' AS function_name,
       EXISTS (
         SELECT 1
         FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public'
           AND p.proname = 'get_pipeline_stats'
       ) AS exists;

SELECT 'simulate_comment' AS function_name,
       EXISTS (
         SELECT 1
         FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public'
           AND p.proname = 'simulate_comment'
       ) AS exists;

SELECT 'ingest_route_analyze' AS function_name,
       EXISTS (
         SELECT 1
         FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public'
           AND p.proname = 'ingest_route_analyze'
       ) AS exists;
