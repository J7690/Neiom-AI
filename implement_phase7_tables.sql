-- Phase 7 Tables Implementation
-- Advanced AI Orchestration and Multi-Agent Systems

-- 1. AI Orchestration Models Table
CREATE TABLE IF NOT EXISTS studio_orchestration_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    model_type VARCHAR(100) NOT NULL CHECK (model_type IN ('central_coordinator', 'agent_manager', 'workflow_orchestrator', 'resource_optimizer', 'decision_engine')),
    orchestration_config JSONB NOT NULL DEFAULT '{}',
    agent_capabilities JSONB NOT NULL DEFAULT '{}',
    coordination_strategy VARCHAR(100) NOT NULL DEFAULT 'hierarchical',
    performance_metrics JSONB NOT NULL DEFAULT '{}',
    resource_requirements JSONB NOT NULL DEFAULT '{}',
    scaling_configuration JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Multi-Agent Systems Table
CREATE TABLE IF NOT EXISTS studio_multi_agent_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_name VARCHAR(255) NOT NULL,
    system_type VARCHAR(100) NOT NULL CHECK (system_type IN ('collaborative', 'competitive', 'hierarchical', 'swarm', 'hybrid')),
    agent_configuration JSONB NOT NULL DEFAULT '{}',
    communication_protocols JSONB NOT NULL DEFAULT '{}',
    coordination_mechanisms JSONB NOT NULL DEFAULT '{}',
    task_allocation_strategy VARCHAR(100) NOT NULL DEFAULT 'dynamic',
    system_performance JSONB NOT NULL DEFAULT '{}',
    scalability_config JSONB NOT NULL DEFAULT '{}',
    fault_tolerance_config JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Autonomous Agents Table
CREATE TABLE IF NOT EXISTS studio_autonomous_agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_name VARCHAR(255) NOT NULL,
    agent_type VARCHAR(100) NOT NULL CHECK (agent_type IN ('cognitive', 'reactive', 'deliberative', 'hybrid', 'learning')),
    agent_capabilities JSONB NOT NULL DEFAULT '{}',
    knowledge_base JSONB NOT NULL DEFAULT '{}',
    decision_making_model JSONB NOT NULL DEFAULT '{}',
    learning_algorithms JSONB NOT NULL DEFAULT '{}',
    communication_protocols JSONB NOT NULL DEFAULT '{}',
    resource_constraints JSONB NOT NULL DEFAULT '{}',
    performance_metrics JSONB NOT NULL DEFAULT '{}',
    autonomy_level INTEGER DEFAULT 5 CHECK (autonomy_level BETWEEN 1 AND 10),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Agent Interactions Table
CREATE TABLE IF NOT EXISTS studio_agent_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES studio_autonomous_agents(id) ON DELETE CASCADE,
    interaction_type VARCHAR(100) NOT NULL CHECK (interaction_type IN ('collaboration', 'negotiation', 'competition', 'coordination', 'learning')),
    target_agent_id UUID REFERENCES studio_autonomous_agents(id) ON DELETE CASCADE,
    interaction_context JSONB NOT NULL DEFAULT '{}',
    message_content JSONB NOT NULL DEFAULT '{}',
    interaction_outcome JSONB NOT NULL DEFAULT '{}',
    performance_impact JSONB NOT NULL DEFAULT '{}',
    interaction_duration_ms INTEGER DEFAULT 0,
    success_rate DECIMAL(5,4) DEFAULT 0.0000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Decision Making Systems Table
CREATE TABLE IF NOT EXISTS studio_decision_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_name VARCHAR(255) NOT NULL,
    decision_type VARCHAR(100) NOT NULL CHECK (decision_type IN ('strategic', 'tactical', 'operational', 'real_time', 'autonomous')),
    decision_models JSONB NOT NULL DEFAULT '{}',
    criteria_weights JSONB NOT NULL DEFAULT '{}',
    optimization_objectives JSONB NOT NULL DEFAULT '{}',
    constraint_definitions JSONB NOT NULL DEFAULT '{}',
    risk_assessment_config JSONB NOT NULL DEFAULT '{}',
    performance_metrics JSONB NOT NULL DEFAULT '{}',
    decision_history JSONB NOT NULL DEFAULT '{}',
    learning_config JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Autonomous Decisions Table
CREATE TABLE IF NOT EXISTS studio_autonomous_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_system_id UUID NOT NULL REFERENCES studio_decision_systems(id) ON DELETE CASCADE,
    decision_context JSONB NOT NULL DEFAULT '{}',
    decision_input JSONB NOT NULL DEFAULT '{}',
    decision_process JSONB NOT NULL DEFAULT '{}',
    decision_output JSONB NOT NULL DEFAULT '{}',
    decision_rationale JSONB NOT NULL DEFAULT '{}',
    confidence_score DECIMAL(5,4) DEFAULT 0.0000,
    risk_assessment JSONB NOT NULL DEFAULT '{}',
    expected_outcome JSONB NOT NULL DEFAULT '{}',
    actual_outcome JSONB,
    decision_latency_ms INTEGER DEFAULT 0,
    execution_status VARCHAR(50) DEFAULT 'pending' CHECK (execution_status IN ('pending', 'executing', 'completed', 'failed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    executed_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 7. Real-time Cognitive Processing Table
CREATE TABLE IF NOT EXISTS studio_realtime_cognitive (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    processing_session_id UUID NOT NULL,
    data_stream_type VARCHAR(100) NOT NULL CHECK (data_stream_type IN ('text', 'image', 'audio', 'video', 'multimodal', 'sensor')),
    input_data JSONB NOT NULL DEFAULT '{}',
    processing_pipeline JSONB NOT NULL DEFAULT '{}',
    cognitive_models_used JSONB NOT NULL DEFAULT '{}',
    processing_stages JSONB NOT NULL DEFAULT '{}',
    intermediate_results JSONB NOT NULL DEFAULT '{}',
    final_output JSONB NOT NULL DEFAULT '{}',
    processing_metrics JSONB NOT NULL DEFAULT '{}',
    quality_scores JSONB NOT NULL DEFAULT '{}',
    latency_breakdown JSONB NOT NULL DEFAULT '{}',
    stream_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Edge Computing Integration Table
CREATE TABLE IF NOT EXISTS studio_edge_integration (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    edge_device_id VARCHAR(255) NOT NULL,
    device_type VARCHAR(100) NOT NULL CHECK (device_type IN ('iot_sensor', 'mobile_device', 'edge_server', 'embedded_system', 'gateway')),
    device_capabilities JSONB NOT NULL DEFAULT '{}',
    computational_resources JSONB NOT NULL DEFAULT '{}',
    network_configuration JSONB NOT NULL DEFAULT '{}',
    deployed_models JSONB NOT NULL DEFAULT '{}',
    processing_configuration JSONB NOT NULL DEFAULT '{}',
    synchronization_config JSONB NOT NULL DEFAULT '{}',
    performance_metrics JSONB NOT NULL DEFAULT '{}',
    battery_status JSONB,
    connectivity_status VARCHAR(50) DEFAULT 'online' CHECK (connectivity_status IN ('online', 'offline', 'limited', 'error')),
    last_sync_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Workflow Orchestration Table
CREATE TABLE IF NOT EXISTS studio_workflow_orchestration (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_name VARCHAR(255) NOT NULL,
    workflow_type VARCHAR(100) NOT NULL CHECK (workflow_type IN ('sequential', 'parallel', 'conditional', 'iterative', 'adaptive')),
    workflow_definition JSONB NOT NULL DEFAULT '{}',
    task_dependencies JSONB NOT NULL DEFAULT '{}',
    resource_allocation JSONB NOT NULL DEFAULT '{}',
    execution_strategy VARCHAR(100) NOT NULL DEFAULT 'auto',
    monitoring_config JSONB NOT NULL DEFAULT '{}',
    optimization_config JSONB NOT NULL DEFAULT '{}',
    error_handling_config JSONB NOT NULL DEFAULT '{}',
    performance_targets JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. Workflow Executions Table
CREATE TABLE IF NOT EXISTS studio_workflow_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_id UUID NOT NULL REFERENCES studio_workflow_orchestration(id) ON DELETE CASCADE,
    execution_context JSONB NOT NULL DEFAULT '{}',
    execution_status VARCHAR(50) DEFAULT 'initialized' CHECK (execution_status IN ('initialized', 'running', 'paused', 'completed', 'failed', 'cancelled')),
    current_stage JSONB NOT NULL DEFAULT '{}',
    completed_stages JSONB NOT NULL DEFAULT '{}',
    stage_results JSONB NOT NULL DEFAULT '{}',
    resource_utilization JSONB NOT NULL DEFAULT '{}',
    performance_metrics JSONB NOT NULL DEFAULT '{}',
    error_log JSONB NOT NULL DEFAULT '{}',
    execution_metrics JSONB NOT NULL DEFAULT '{}',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    estimated_completion TIMESTAMP WITH TIME ZONE
);

-- Create Indexes for Performance Optimization
CREATE INDEX IF NOT EXISTS idx_orchestration_models_active ON studio_orchestration_models(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_orchestration_models_type ON studio_orchestration_models(model_type);
CREATE INDEX IF NOT EXISTS idx_multi_agent_systems_active ON studio_multi_agent_systems(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_multi_agent_systems_type ON studio_multi_agent_systems(system_type);
CREATE INDEX IF NOT EXISTS idx_autonomous_agents_active ON studio_autonomous_agents(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_autonomous_agents_type ON studio_autonomous_agents(agent_type);
CREATE INDEX IF NOT EXISTS idx_autonomous_agents_autonomy ON studio_autonomous_agents(autonomy_level);
CREATE INDEX IF NOT EXISTS idx_agent_interactions_agent ON studio_agent_interactions(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_interactions_target ON studio_agent_interactions(target_agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_interactions_type ON studio_agent_interactions(interaction_type);
CREATE INDEX IF NOT EXISTS idx_decision_systems_active ON studio_decision_systems(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_decision_systems_type ON studio_decision_systems(decision_type);
CREATE INDEX IF NOT EXISTS idx_autonomous_decisions_system ON studio_autonomous_decisions(decision_system_id);
CREATE INDEX IF NOT EXISTS idx_autonomous_decisions_status ON studio_autonomous_decisions(execution_status);
CREATE INDEX IF NOT EXISTS idx_autonomous_decisions_created ON studio_autonomous_decisions(created_at);
CREATE INDEX IF NOT EXISTS idx_realtime_cognitive_session ON studio_realtime_cognitive(processing_session_id);
CREATE INDEX IF NOT EXISTS idx_realtime_cognitive_stream ON studio_realtime_cognitive(stream_id);
CREATE INDEX IF NOT EXISTS idx_realtime_cognitive_type ON studio_realtime_cognitive(data_stream_type);
CREATE INDEX IF NOT EXISTS idx_realtime_cognitive_created ON studio_realtime_cognitive(created_at);
CREATE INDEX IF NOT EXISTS idx_edge_integration_device ON studio_edge_integration(edge_device_id);
CREATE INDEX IF NOT EXISTS idx_edge_integration_type ON studio_edge_integration(device_type);
CREATE INDEX IF NOT EXISTS idx_edge_integration_status ON studio_edge_integration(connectivity_status);
CREATE INDEX IF NOT EXISTS idx_edge_integration_active ON studio_edge_integration(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_workflow_orchestration_active ON studio_workflow_orchestration(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_workflow_orchestration_type ON studio_workflow_orchestration(workflow_type);
CREATE INDEX IF NOT EXISTS idx_workflow_executions_workflow ON studio_workflow_executions(workflow_id);
CREATE INDEX IF NOT EXISTS idx_workflow_executions_status ON studio_workflow_executions(execution_status);
CREATE INDEX IF NOT EXISTS idx_workflow_executions_started ON studio_workflow_executions(started_at);

-- Create RLS (Row Level Security) Policies
ALTER TABLE studio_orchestration_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_multi_agent_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_autonomous_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_agent_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_decision_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_autonomous_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_realtime_cognitive ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_edge_integration ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_workflow_orchestration ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_workflow_executions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Orchestration Models
CREATE POLICY "Users can view orchestration models" ON studio_orchestration_models FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert orchestration models" ON studio_orchestration_models FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own orchestration models" ON studio_orchestration_models FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can delete own orchestration models" ON studio_orchestration_models FOR DELETE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Multi-Agent Systems
CREATE POLICY "Users can view multi-agent systems" ON studio_multi_agent_systems FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert multi-agent systems" ON studio_multi_agent_systems FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own multi-agent systems" ON studio_multi_agent_systems FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can delete own multi-agent systems" ON studio_multi_agent_systems FOR DELETE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Autonomous Agents
CREATE POLICY "Users can view autonomous agents" ON studio_autonomous_agents FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert autonomous agents" ON studio_autonomous_agents FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own autonomous agents" ON studio_autonomous_agents FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can delete own autonomous agents" ON studio_autonomous_agents FOR DELETE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Agent Interactions
CREATE POLICY "Users can view agent interactions" ON studio_agent_interactions FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert agent interactions" ON studio_agent_interactions FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own agent interactions" ON studio_agent_interactions FOR UPDATE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Decision Systems
CREATE POLICY "Users can view decision systems" ON studio_decision_systems FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert decision systems" ON studio_decision_systems FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own decision systems" ON studio_decision_systems FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can delete own decision systems" ON studio_decision_systems FOR DELETE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Autonomous Decisions
CREATE POLICY "Users can view autonomous decisions" ON studio_autonomous_decisions FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert autonomous decisions" ON studio_autonomous_decisions FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own autonomous decisions" ON studio_autonomous_decisions FOR UPDATE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Real-time Cognitive Processing
CREATE POLICY "Users can view realtime cognitive" ON studio_realtime_cognitive FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert realtime cognitive" ON studio_realtime_cognitive FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own realtime cognitive" ON studio_realtime_cognitive FOR UPDATE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Edge Integration
CREATE POLICY "Users can view edge integration" ON studio_edge_integration FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert edge integration" ON studio_edge_integration FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own edge integration" ON studio_edge_integration FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can delete own edge integration" ON studio_edge_integration FOR DELETE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Workflow Orchestration
CREATE POLICY "Users can view workflow orchestration" ON studio_workflow_orchestration FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert workflow orchestration" ON studio_workflow_orchestration FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own workflow orchestration" ON studio_workflow_orchestration FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can delete own workflow orchestration" ON studio_workflow_orchestration FOR DELETE USING (auth.uid() IS NOT NULL);

-- RLS Policies for Workflow Executions
CREATE POLICY "Users can view workflow executions" ON studio_workflow_executions FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Users can insert workflow executions" ON studio_workflow_executions FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update own workflow executions" ON studio_workflow_executions FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Create Updated At Triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_orchestration_models_updated_at BEFORE UPDATE ON studio_orchestration_models FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_multi_agent_systems_updated_at BEFORE UPDATE ON studio_multi_agent_systems FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_autonomous_agents_updated_at BEFORE UPDATE ON studio_autonomous_agents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_decision_systems_updated_at BEFORE UPDATE ON studio_decision_systems FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_edge_integration_updated_at BEFORE UPDATE ON studio_edge_integration FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workflow_orchestration_updated_at BEFORE UPDATE ON studio_workflow_orchestration FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Phase 7 Tables Implementation Complete
