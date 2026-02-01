-- Phase 7 Basic Test Script
-- Basic verification of Phase 7 tables and RPCs

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
    proname as function_name,
    pg_get_function_arguments(oid) as arguments
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

-- Test 3: Test create_orchestration_model RPC
SELECT * FROM create_orchestration_model(
    'Test Orchestration Model',
    'A test model for orchestration',
    'central_coordinator',
    '{"version": "1.0", "capabilities": ["coordination", "optimization"]}'::jsonb
);

-- Test 4: Test create_multi_agent_system RPC
SELECT * FROM create_multi_agent_system(
    'Test Multi-Agent System',
    'A test system for agent collaboration',
    'collaborative',
    ARRAY['agent1', 'agent2'],
    '{"protocol": "message_passing", "coordination": "decentralized"}'::jsonb
);

-- Test 5: Test create_autonomous_agent RPC
SELECT * FROM create_autonomous_agent(
    'Test Autonomous Agent',
    'A test agent with autonomous capabilities',
    'cognitive',
    '{"reasoning": "advanced", "learning": "reinforcement"}'::jsonb,
    '{"knowledge": "test_data", "experience": "minimal"}'::jsonb
);

-- Test 6: Test create_decision_making_system RPC
SELECT * FROM create_decision_making_system(
    'Test Decision System',
    'A test system for autonomous decision making',
    'strategic',
    '{"risk_tolerance": 0.3, "time_horizon": "long_term"}'::jsonb,
    '{"algorithm": "multi_criteria", "optimization": "pareto"}'::jsonb
);

-- Test 7: Test make_autonomous_decision RPC
SELECT * FROM make_autonomous_decision(
    (SELECT id FROM decision_making_systems WHERE name = 'Test Decision System' LIMIT 1),
    'Resource allocation decision',
    '{"option_a": {"cost": 100, "benefit": 150}, "option_b": {"cost": 80, "benefit": 120}}'::jsonb
);

-- Test 8: Test process_cognitive_stream RPC
SELECT * FROM process_cognitive_stream(
    'stream_test_001',
    'real_time_analysis',
    '{"data_type": "sensor", "values": [1.2, 3.4, 2.1], "timestamp": "2024-01-01T12:00:00Z"}'::jsonb
);

-- Test 9: Test register_edge_device RPC
SELECT * FROM register_edge_device(
    'edge_device_001',
    'model_edge_v1',
    '{"cpu": "arm64", "memory": "4GB", "storage": "64GB"}'::jsonb
);

-- Test 10: Test create_workflow RPC
SELECT * FROM create_workflow(
    'Test Workflow',
    'A test workflow for orchestration',
    'sequential',
    '[{"task_id": "task1", "name": "Data Collection", "type": "input"}, {"task_id": "task2", "name": "Processing", "type": "transform"}]'::jsonb,
    '{"task1": [], "task2": ["task1"]}'::jsonb,
    '{"retry_policy": "exponential_backoff", "max_retries": 3}'::jsonb
);

-- Test 11: Test execute_workflow RPC
SELECT * FROM execute_workflow(
    (SELECT id FROM workflow_orchestration WHERE name = 'Test Workflow' LIMIT 1),
    '{"input_data": "test_payload", "priority": "normal"}'::jsonb
);

-- Test 12: Verify data in Phase 7 tables
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
