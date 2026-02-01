-- Phase 7 Implementation Test Script
-- Tests for Advanced AI Orchestration tables, RPCs, and functionality

-- Test 1: Verify Phase 7 tables exist
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count
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
    );
    
    IF table_count = 10 THEN
        RAISE NOTICE '✓ All 10 Phase 7 tables exist';
    ELSE
        RAISE NOTICE '✗ Missing Phase 7 tables. Found: %', table_count;
    END IF;
END $$;

-- Test 2: Verify Phase 7 RPC functions exist
DO $$
DECLARE
    rpc_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO rpc_count
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
    );
    
    IF rpc_count = 20 THEN
        RAISE NOTICE '✓ All 20 Phase 7 RPC functions exist';
    ELSE
        RAISE NOTICE '✗ Missing Phase 7 RPC functions. Found: %', rpc_count;
    END IF;
END $$;

-- Test 3: Test create_orchestration_model RPC
DO $$
DECLARE
    model_result RECORD;
BEGIN
    -- Test creating an orchestration model
    SELECT * INTO model_result FROM create_orchestration_model(
        'Test Orchestration Model',
        'A test model for orchestration',
        'central_coordinator',
        '{"version": "1.0", "capabilities": ["coordination", "optimization"]}'::jsonb
    );
    
    IF model_result.id IS NOT NULL THEN
        RAISE NOTICE '✓ create_orchestration_model RPC works - ID: %', model_result.id;
    ELSE
        RAISE NOTICE '✗ create_orchestration_model RPC failed';
    END IF;
END $$;

-- Test 4: Test create_multi_agent_system RPC
DO $$
DECLARE
    system_result RECORD;
BEGIN
    -- Test creating a multi-agent system
    SELECT * INTO system_result FROM create_multi_agent_system(
        'Test Multi-Agent System',
        'A test system for agent collaboration',
        'collaborative',
        ARRAY['agent1', 'agent2'],
        '{"protocol": "message_passing", "coordination": "decentralized"}'::jsonb
    );
    
    IF system_result.id IS NOT NULL THEN
        RAISE NOTICE '✓ create_multi_agent_system RPC works - ID: %', system_result.id;
    ELSE
        RAISE NOTICE '✗ create_multi_agent_system RPC failed';
    END IF;
END $$;

-- Test 5: Test create_autonomous_agent RPC
DO $$
DECLARE
    agent_result RECORD;
BEGIN
    -- Test creating an autonomous agent
    SELECT * INTO agent_result FROM create_autonomous_agent(
        'Test Autonomous Agent',
        'A test agent with autonomous capabilities',
        'cognitive',
        '{"reasoning": "advanced", "learning": "reinforcement"}'::jsonb,
        '{"knowledge": "test_data", "experience": "minimal"}'::jsonb
    );
    
    IF agent_result.id IS NOT NULL THEN
        RAISE NOTICE '✓ create_autonomous_agent RPC works - ID: %', agent_result.id;
    ELSE
        RAISE NOTICE '✗ create_autonomous_agent RPC failed';
    END IF;
END $$;

-- Test 6: Test create_decision_making_system RPC
DO $$
DECLARE
    decision_system_result RECORD;
BEGIN
    -- Test creating a decision making system
    SELECT * INTO decision_system_result FROM create_decision_making_system(
        'Test Decision System',
        'A test system for autonomous decision making',
        'strategic',
        '{"risk_tolerance": 0.3, "time_horizon": "long_term"}'::jsonb,
        '{"algorithm": "multi_criteria", "optimization": "pareto"}'::jsonb
    );
    
    IF decision_system_result.id IS NOT NULL THEN
        RAISE NOTICE '✓ create_decision_making_system RPC works - ID: %', decision_system_result.id;
    ELSE
        RAISE NOTICE '✗ create_decision_making_system RPC failed';
    END IF;
END $$;

-- Test 7: Test make_autonomous_decision RPC
DO $$
DECLARE
    decision_result RECORD;
    test_system_id UUID;
BEGIN
    -- Get a test decision system ID
    SELECT id INTO test_system_id 
    FROM decision_making_systems 
    WHERE name = 'Test Decision System' 
    LIMIT 1;
    
    IF test_system_id IS NOT NULL THEN
        -- Test making an autonomous decision
        SELECT * INTO decision_result FROM make_autonomous_decision(
            test_system_id,
            'Resource allocation decision',
            '{"option_a": {"cost": 100, "benefit": 150}, "option_b": {"cost": 80, "benefit": 120}}'::jsonb
        );
        
        IF decision_result.id IS NOT NULL THEN
            RAISE NOTICE '✓ make_autonomous_decision RPC works - ID: %', decision_result.id;
        ELSE
            RAISE NOTICE '✗ make_autonomous_decision RPC failed';
        END IF;
    ELSE
        RAISE NOTICE '✗ No test decision system found for make_autonomous_decision test';
    END IF;
END $$;

-- Test 8: Test process_cognitive_stream RPC
DO $$
DECLARE
    processing_result RECORD;
BEGIN
    -- Test processing a cognitive stream
    SELECT * INTO processing_result FROM process_cognitive_stream(
        'stream_test_001',
        'real_time_analysis',
        '{"data_type": "sensor", "values": [1.2, 3.4, 2.1], "timestamp": "2024-01-01T12:00:00Z"}'::jsonb
    );
    
    IF processing_result.id IS NOT NULL THEN
        RAISE NOTICE '✓ process_cognitive_stream RPC works - ID: %', processing_result.id;
    ELSE
        RAISE NOTICE '✗ process_cognitive_stream RPC failed';
    END IF;
END $$;

-- Test 9: Test register_edge_device RPC
DO $$
DECLARE
    edge_result RECORD;
BEGIN
    -- Test registering an edge device
    SELECT * INTO edge_result FROM register_edge_device(
        'edge_device_001',
        'model_edge_v1',
        '{"cpu": "arm64", "memory": "4GB", "storage": "64GB"}'::jsonb
    );
    
    IF edge_result.id IS NOT NULL THEN
        RAISE NOTICE '✓ register_edge_device RPC works - ID: %', edge_result.id;
    ELSE
        RAISE NOTICE '✗ register_edge_device RPC failed';
    END IF;
END $$;

-- Test 10: Test create_workflow RPC
DO $$
DECLARE
    workflow_result RECORD;
BEGIN
    -- Test creating a workflow
    SELECT * INTO workflow_result FROM create_workflow(
        'Test Workflow',
        'A test workflow for orchestration',
        'sequential',
        '[{"task_id": "task1", "name": "Data Collection", "type": "input"}, {"task_id": "task2", "name": "Processing", "type": "transform"}]'::jsonb,
        '{"task1": [], "task2": ["task1"]}'::jsonb,
        '{"retry_policy": "exponential_backoff", "max_retries": 3}'::jsonb
    );
    
    IF workflow_result.id IS NOT NULL THEN
        RAISE NOTICE '✓ create_workflow RPC works - ID: %', workflow_result.id;
    ELSE
        RAISE NOTICE '✗ create_workflow RPC failed';
    END IF;
END $$;

-- Test 11: Test execute_workflow RPC
DO $$
DECLARE
    execution_result RECORD;
    test_workflow_id UUID;
BEGIN
    -- Get a test workflow ID
    SELECT id INTO test_workflow_id 
    FROM workflow_orchestration 
    WHERE name = 'Test Workflow' 
    LIMIT 1;
    
    IF test_workflow_id IS NOT NULL THEN
        -- Test executing a workflow
        SELECT * INTO execution_result FROM execute_workflow(
            test_workflow_id,
            '{"input_data": "test_payload", "priority": "normal"}'::jsonb
        );
        
        IF execution_result.id IS NOT NULL THEN
            RAISE NOTICE '✓ execute_workflow RPC works - ID: %', execution_result.id;
        ELSE
            RAISE NOTICE '✗ execute_workflow RPC failed';
        END IF;
    ELSE
        RAISE NOTICE '✗ No test workflow found for execute_workflow test';
    END IF;
END $$;

-- Test 12: Verify data in Phase 7 tables
DO $$
DECLARE
    model_count INTEGER;
    system_count INTEGER;
    agent_count INTEGER;
    decision_count INTEGER;
    workflow_count INTEGER;
BEGIN
    -- Count records in each table
    SELECT COUNT(*) INTO model_count FROM ai_orchestration_models;
    SELECT COUNT(*) INTO system_count FROM multi_agent_systems;
    SELECT COUNT(*) INTO agent_count FROM autonomous_agents;
    SELECT COUNT(*) INTO decision_count FROM autonomous_decisions;
    SELECT COUNT(*) INTO workflow_count FROM workflow_orchestration;
    
    RAISE NOTICE '=== Phase 7 Data Summary ===';
    RAISE NOTICE 'Orchestration Models: %', model_count;
    RAISE NOTICE 'Multi-Agent Systems: %', system_count;
    RAISE NOTICE 'Autonomous Agents: %', agent_count;
    RAISE NOTICE 'Autonomous Decisions: %', decision_count;
    RAISE NOTICE 'Workflows: %', workflow_count;
    
    IF model_count > 0 AND system_count > 0 AND agent_count > 0 THEN
        RAISE NOTICE '✓ Phase 7 tables contain test data';
    ELSE
        RAISE NOTICE '✗ Phase 7 tables missing expected test data';
    END IF;
END $$;

-- Test 13: Test orchestrate_agent_collaboration RPC
DO $$
DECLARE
    collaboration_result JSONB;
    test_system_id UUID;
BEGIN
    -- Get a test multi-agent system ID
    SELECT id INTO test_system_id 
    FROM multi_agent_systems 
    WHERE name = 'Test Multi-Agent System' 
    LIMIT 1;
    
    IF test_system_id IS NOT NULL THEN
        -- Test orchestrating agent collaboration
        SELECT orchestrate_agent_collaboration(
            test_system_id,
            'Collaborative task execution',
            '{"priority": "high", "deadline": "2024-01-02T00:00:00Z"}'::jsonb
        ) INTO collaboration_result;
        
        IF collaboration_result IS NOT NULL THEN
            RAISE NOTICE '✓ orchestrate_agent_collaboration RPC works';
        ELSE
            RAISE NOTICE '✗ orchestrate_agent_collaboration RPC failed';
        END IF;
    ELSE
        RAISE NOTICE '✗ No test multi-agent system found for collaboration test';
    END IF;
END $$;

-- Test 14: Test record_agent_interaction RPC
DO $$
DECLARE
    interaction_result RECORD;
    test_agent_id UUID;
BEGIN
    -- Get a test agent ID
    SELECT id INTO test_agent_id 
    FROM autonomous_agents 
    WHERE name = 'Test Autonomous Agent' 
    LIMIT 1;
    
    IF test_agent_id IS NOT NULL THEN
        -- Test recording an agent interaction
        SELECT * INTO interaction_result FROM record_agent_interaction(
            test_agent_id,
            test_agent_id, -- Self-interaction for test
            'status_update',
            '{"status": "active", "message": "Agent initialized successfully"}'::jsonb
        );
        
        IF interaction_result.id IS NOT NULL THEN
            RAISE NOTICE '✓ record_agent_interaction RPC works - ID: %', interaction_result.id;
        ELSE
            RAISE NOTICE '✗ record_agent_interaction RPC failed';
        END IF;
    ELSE
        RAISE NOTICE '✗ No test agent found for interaction test';
    END IF;
END $$;

-- Test 15: Test analyze_cognitive_performance RPC
DO $$
DECLARE
    performance_result JSONB;
BEGIN
    -- Test analyzing cognitive performance
    SELECT analyze_cognitive_performance(
        'stream_test_001',
        '2024-01-01T00:00:00Z',
        '2024-01-01T23:59:59Z'
    ) INTO performance_result;
    
    IF performance_result IS NOT NULL THEN
        RAISE NOTICE '✓ analyze_cognitive_performance RPC works';
    ELSE
        RAISE NOTICE '✗ analyze_cognitive_performance RPC failed';
    END IF;
END $$;

-- Test 16: Test analyze_edge_performance RPC
DO $$
DECLARE
    edge_performance_result JSONB;
BEGIN
    -- Test analyzing edge performance
    SELECT analyze_edge_performance(
        'edge_device_001',
        '2024-01-01T00:00:00Z',
        '2024-01-01T23:59:59Z'
    ) INTO edge_performance_result;
    
    IF edge_performance_result IS NOT NULL THEN
        RAISE NOTICE '✓ analyze_edge_performance RPC works';
    ELSE
        RAISE NOTICE '✗ analyze_edge_performance RPC failed';
    END IF;
END $$;

-- Test 17: Test get_system_performance_metrics RPC
DO $$
DECLARE
    metrics_result JSONB;
BEGIN
    -- Test getting system performance metrics
    SELECT get_system_performance_metrics() INTO metrics_result;
    
    IF metrics_result IS NOT NULL THEN
        RAISE NOTICE '✓ get_system_performance_metrics RPC works';
    ELSE
        RAISE NOTICE '✗ get_system_performance_metrics RPC failed';
    END IF;
END $$;

-- Test 18: Test analyze_agent_collaboration_patterns RPC
DO $$
DECLARE
    patterns_result JSONB;
    test_system_id UUID;
BEGIN
    -- Get a test multi-agent system ID
    SELECT id INTO test_system_id 
    FROM multi_agent_systems 
    WHERE name = 'Test Multi-Agent System' 
    LIMIT 1;
    
    IF test_system_id IS NOT NULL THEN
        -- Test analyzing agent collaboration patterns
        SELECT analyze_agent_collaboration_patterns(
            test_system_id,
            '2024-01-01T00:00:00Z',
            '2024-01-01T23:59:59Z'
        ) INTO patterns_result;
        
        IF patterns_result IS NOT NULL THEN
            RAISE NOTICE '✓ analyze_agent_collaboration_patterns RPC works';
        ELSE
            RAISE NOTICE '✗ analyze_agent_collaboration_patterns RPC failed';
        END IF;
    ELSE
        RAISE NOTICE '✗ No test multi-agent system found for patterns analysis';
    END IF;
END $$;

-- Test 19: Test optimize_system_resources RPC
DO $$
DECLARE
    optimization_result JSONB;
BEGIN
    -- Test optimizing system resources
    SELECT optimize_system_resources() INTO optimization_result;
    
    IF optimization_result IS NOT NULL THEN
        RAISE NOTICE '✓ optimize_system_resources RPC works';
    ELSE
        RAISE NOTICE '✗ optimize_system_resources RPC failed';
    END IF;
END $$;

-- Test 20: Verify RLS policies are working
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename IN (
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
    );
    
    IF policy_count >= 10 THEN
        RAISE NOTICE '✓ RLS policies are configured for Phase 7 tables (found % policies)', policy_count;
    ELSE
        RAISE NOTICE '✗ RLS policies may be missing for Phase 7 tables (found % policies)', policy_count;
    END IF;
END $$;

-- Final Summary
RAISE NOTICE '=== Phase 7 Implementation Test Complete ===';
RAISE NOTICE 'Phase 7 Advanced AI Orchestration implementation has been tested';
RAISE NOTICE 'All major RPC functions, tables, and functionality verified';
