-- Phase 11 Readiness Audit
-- No-secrets tools: content suggestion, auto-scheduling, seed messages, auto-reply batch

-- 1) Core tables used by Phase 11 tools
SELECT 'social_posts' AS table_name,
       to_regclass('public.social_posts') IS NOT NULL AS exists;

SELECT 'social_schedules' AS table_name,
       to_regclass('public.social_schedules') IS NOT NULL AS exists;

SELECT 'messages' AS table_name,
       to_regclass('public.messages') IS NOT NULL AS exists;

SELECT 'leads' AS table_name,
       to_regclass('public.leads') IS NOT NULL AS exists;

-- 2) Check Phase 11 main functions and their dependencies
SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'suggest_content_stub',
    'create_and_schedule_post_stub',
    'seed_random_messages',
    'auto_reply_recent_inbound',
    'create_social_post',
    'schedule_social_post',
    'simulate_message',
    'auto_reply_stub'
  )
ORDER BY p.proname;

-- 3) Quick aggregate view: count of messages and social posts
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
FROM public.social_schedules;
