-- Phase 8 Implementation Test Script
-- Advanced Activation & Channel Orchestration

-- 1) Check activation tables and basic counts
SELECT 'studio_activation_channels' AS table_name, COUNT(*) AS row_count
FROM studio_activation_channels
UNION ALL
SELECT 'studio_activation_scenarios' AS table_name, COUNT(*) AS row_count
FROM studio_activation_scenarios
UNION ALL
SELECT 'studio_activation_executions' AS table_name, COUNT(*) AS row_count
FROM studio_activation_executions
UNION ALL
SELECT 'studio_channel_messages_outbox' AS table_name, COUNT(*) AS row_count
FROM studio_channel_messages_outbox
ORDER BY table_name;

-- 2) Check RPCs are registered
SELECT 
    n.nspname AS schema_name,
    p.proname AS function_name,
    pg_get_function_result(p.oid) AS return_type,
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

-- 3) Quick dashboard check
SELECT public.get_activation_dashboard();
