-- Phase 9 Tables / Functions Only Test
-- Verifies presence of core tables, routed_at column and routing functions

-- 1) Core tables
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

-- 2) routed_at column on webhook_events
SELECT 'webhook_events.routed_at' AS item,
       EXISTS (
         SELECT 1
         FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'webhook_events'
           AND column_name = 'routed_at'
       ) AS exists;

-- 3) Routing related functions
SELECT 'ingest_webhook_event' AS function_name,
       EXISTS (
         SELECT 1
         FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public'
           AND p.proname = 'ingest_webhook_event'
       ) AS exists;

SELECT 'route_webhook_event' AS function_name,
       EXISTS (
         SELECT 1
         FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public'
           AND p.proname = 'route_webhook_event'
       ) AS exists;

SELECT 'route_unrouted_events' AS function_name,
       EXISTS (
         SELECT 1
         FROM pg_proc p
         JOIN pg_namespace n ON p.pronamespace = n.oid
         WHERE n.nspname = 'public'
           AND p.proname = 'route_unrouted_events'
       ) AS exists;
