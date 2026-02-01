-- Phase 7 Tables Only Test Script
-- Simple verification of Phase 7 table existence

-- Test 1: Verify Phase 7 tables exist
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'ai_orchestration_models',
    'multi_agent_systems', 
    'autonomous_agents',
    'agent_interactions',
    'decision_making_systems',
    'autonomous_decisions',
    'realtime_cognitive_processing',
    'edge_computing_integration',
    'workflow_orchestration',
    'workflow_executions'
)
ORDER BY table_name;

-- Test 2: Verify Phase 7 RPC functions exist
SELECT 
    proname as function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN (
    'create_orchestration_model',
    'update_orchestration_model',
    'create_multi_agent_system',
    'orchestrate_agent_collaboration',
    'create_autonomous_agent',
    'activate_autonomous_agent',
    'deactivate_autonomous_agent',
    'record_agent_interaction',
    'create_decision_making_system',
    'make_autonomous_decision',
    'process_cognitive_stream',
    'analyze_cognitive_performance',
    'register_edge_device',
    'sync_edge_device',
    'analyze_edge_performance',
    'create_workflow',
    'execute_workflow',
    'monitor_workflow_execution',
    'get_system_performance_metrics',
    'analyze_agent_collaboration_patterns',
    'optimize_system_resources'
)
ORDER BY proname;

-- Test 3: Simple data count check
SELECT 
    'ai_orchestration_models' as table_name, COUNT(*) as record_count
FROM ai_orchestration_models
UNION ALL
SELECT 
    'multi_agent_systems' as table_name, COUNT(*) as record_count
FROM multi_agent_systems
UNION ALL
SELECT 
    'autonomous_agents' as table_name, COUNT(*) as record_count
FROM autonomous_agents
UNION ALL
SELECT 
    'decision_making_systems' as table_name, COUNT(*) as record_count
FROM decision_making_systems
UNION ALL
SELECT 
    'workflow_orchestration' as table_name, COUNT(*) as record_count
FROM workflow_orchestration
ORDER BY table_name;
