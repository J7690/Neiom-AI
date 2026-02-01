-- Phase 11 Tables / Functions Only Test
-- Verifies presence of Phase 11 tools and core tables

-- 1) Core tables
SELECT 'social_posts' AS table_name,
       to_regclass('public.social_posts') IS NOT NULL AS exists;

SELECT 'social_schedules' AS table_name,
       to_regclass('public.social_schedules') IS NOT NULL AS exists;

SELECT 'messages' AS table_name,
       to_regclass('public.messages') IS NOT NULL AS exists;

SELECT 'leads' AS table_name,
       to_regclass('public.leads') IS NOT NULL AS exists;

-- 2) Phase 11 functions
SELECT 'suggest_content_stub' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'suggest_content_stub'
       ) AS exists;

SELECT 'create_and_schedule_post_stub' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'create_and_schedule_post_stub'
       ) AS exists;

SELECT 'seed_random_messages' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'seed_random_messages'
       ) AS exists;

SELECT 'auto_reply_recent_inbound' AS function_name,
       EXISTS (
         SELECT 1 FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public' AND p.proname = 'auto_reply_recent_inbound'
       ) AS exists;
