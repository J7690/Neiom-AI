-- Phase 8 Readiness Audit
-- Advanced Activation & Channel Orchestration

-- 1) Check core Phase 7 orchestration tables
SELECT 'studio_orchestration_models' AS table_name,
       to_regclass('public.studio_orchestration_models') IS NOT NULL AS exists;

SELECT 'studio_multi_agent_systems' AS table_name,
       to_regclass('public.studio_multi_agent_systems') IS NOT NULL AS exists;

SELECT 'studio_autonomous_agents' AS table_name,
       to_regclass('public.studio_autonomous_agents') IS NOT NULL AS exists;

SELECT 'studio_decision_systems' AS table_name,
       to_regclass('public.studio_decision_systems') IS NOT NULL AS exists;

SELECT 'studio_realtime_cognitive' AS table_name,
       to_regclass('public.studio_realtime_cognitive') IS NOT NULL AS exists;

SELECT 'studio_edge_integration' AS table_name,
       to_regclass('public.studio_edge_integration') IS NOT NULL AS exists;

SELECT 'studio_workflow_orchestration' AS table_name,
       to_regclass('public.studio_workflow_orchestration') IS NOT NULL AS exists;

SELECT 'studio_workflow_executions' AS table_name,
       to_regclass('public.studio_workflow_executions') IS NOT NULL AS exists;

-- 2) Check messaging core tables used by Instagram/activation
SELECT 'public.messages' AS table_name,
       to_regclass('public.messages') IS NOT NULL AS exists;

SELECT 'public.message_analysis' AS table_name,
       to_regclass('public.message_analysis') IS NOT NULL AS exists;

-- 3) Check existing Instagram / AI reply Phase 8 functions
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

-- 4) Check (optional) existing activation tables (may be false before implementation)
SELECT 'studio_activation_channels' AS table_name,
       to_regclass('public.studio_activation_channels') IS NOT NULL AS exists
UNION ALL
SELECT 'studio_activation_scenarios' AS table_name,
       to_regclass('public.studio_activation_scenarios') IS NOT NULL AS exists
UNION ALL
SELECT 'studio_activation_executions' AS table_name,
       to_regclass('public.studio_activation_executions') IS NOT NULL AS exists
UNION ALL
SELECT 'studio_channel_messages_outbox' AS table_name,
       to_regclass('public.studio_channel_messages_outbox') IS NOT NULL AS exists;

-- 5) Check (optional) Phase 8 activation RPCs (may be empty before implementation)
SELECT n.nspname AS schema_name,
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
