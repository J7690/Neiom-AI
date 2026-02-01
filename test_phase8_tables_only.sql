-- Phase 8 Tables Only Test Script
-- Simple verification of Phase 8 activation tables and RPCs

-- 1) Verify Phase 8 activation tables exist
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'studio_activation_channels',
    'studio_activation_scenarios',
    'studio_activation_executions',
    'studio_channel_messages_outbox'
)
ORDER BY table_name;

-- 2) Verify Phase 8 RPC functions exist
SELECT 
    p.proname AS function_name,
    pg_get_function_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
    'create_activation_channel',
    'create_activation_scenario',
    'enqueue_channel_message',
    'run_activation_scenario_on_message',
    'get_activation_dashboard'
)
ORDER BY p.proname;
