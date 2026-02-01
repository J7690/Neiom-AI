-- Phase 9 Readiness Audit
-- Batch routing for webhook_events and message pipeline

-- 1) Core messaging tables
SELECT 'webhook_events' AS table_name,
       to_regclass('public.webhook_events') IS NOT NULL AS exists;

SELECT 'contacts' AS table_name,
       to_regclass('public.contacts') IS NOT NULL AS exists;

SELECT 'contact_channels' AS table_name,
       to_regclass('public.contact_channels') IS NOT NULL AS exists;

SELECT 'conversations' AS table_name,
       to_regclass('public.conversations') IS NOT NULL AS exists;

SELECT 'messages' AS table_name,
       to_regclass('public.messages') IS NOT NULL AS exists;

SELECT 'message_analysis' AS table_name,
       to_regclass('public.message_analysis') IS NOT NULL AS exists;

-- 2) Check routed_at column on webhook_events
SELECT 'webhook_events.routed_at' AS item,
       EXISTS (
         SELECT 1
         FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'webhook_events'
           AND column_name = 'routed_at'
       ) AS exists;

-- 3) Check main routing / analysis functions
SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'ingest_webhook_event',
    'route_webhook_event',
    'analyze_message_simple',
    'route_unrouted_events'
  )
ORDER BY p.proname;

-- 4) Optional: Instagram ingestion & auto-reply (Phase 8 dependencies)
SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'ingest_instagram_webhook',
    'ai_reply_template',
    'auto_reply_stub'
  )
ORDER BY p.proname;

-- 5) Quick metrics: how many webhook_events are still unrouted
SELECT 'UNROUTED_EVENTS' AS metric,
       COUNT(*) AS value
FROM public.webhook_events
WHERE routed_at IS NULL;
