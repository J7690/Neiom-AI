-- Extension des tables pour Phase 4 : Intelligence Collective
-- Tables pour coordination agents IA, learning continu, intelligence collective

-- Table pour la coordination des agents IA
CREATE TABLE IF NOT EXISTS studio_agent_coordination (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coordination_session_id TEXT NOT NULL,
    coordinator_agent TEXT NOT NULL CHECK (coordinator_agent IN ('marketing', 'support', 'analytics', 'content')),
    participating_agents TEXT[] DEFAULT '{}',
    coordination_type TEXT NOT NULL CHECK (coordination_type IN ('strategy', 'optimization', 'crisis', 'opportunity')),
    coordination_context JSONB DEFAULT '{}'::jsonb,
    shared_insights JSONB DEFAULT '[]'::jsonb,
    collective_decisions JSONB DEFAULT '[]'::jsonb,
    coordination_status TEXT DEFAULT 'active' CHECK (coordination_status IN ('active', 'completed', 'failed', 'cancelled')),
    start_time TIMESTAMPTZ DEFAULT now(),
    end_time TIMESTAMPTZ,
    duration_seconds INTEGER,
    success_rate NUMERIC CHECK (success_rate >= 0 AND success_rate <= 1),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour le learning continu des agents IA
CREATE TABLE IF NOT EXISTS studio_continuous_learning (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learning_agent TEXT NOT NULL CHECK (learning_agent IN ('marketing', 'support', 'analytics', 'content')),
    learning_type TEXT NOT NULL CHECK (learning_type IN ('pattern', 'correlation', 'causation', 'prediction', 'optimization')),
    learning_source TEXT NOT NULL,
    learning_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    previous_knowledge JSONB DEFAULT '{}'::jsonb,
    new_insights JSONB DEFAULT '{}'::jsonb,
    confidence_improvement NUMERIC DEFAULT 0,
    accuracy_improvement NUMERIC DEFAULT 0,
    learning_confidence NUMERIC CHECK (learning_confidence >= 0 AND learning_confidence <= 1),
    validation_status TEXT DEFAULT 'pending' CHECK (validation_status IN ('pending', 'validated', 'rejected', 'implemented')),
    validation_results JSONB DEFAULT '{}'::jsonb,
    learning_value NUMERIC CHECK (learning_value >= 0 AND learning_value <= 100),
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '90 days')
);

-- Table pour l'intelligence collective émergente
CREATE TABLE IF NOT EXISTS studio_collective_intelligence_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    intelligence_id TEXT UNIQUE NOT NULL,
    intelligence_type TEXT NOT NULL CHECK (intelligence_type IN ('pattern', 'recommendation', 'prediction', 'optimization', 'strategy')),
    source_agents TEXT[] DEFAULT '{}',
    contributing_agents TEXT[] DEFAULT '{}',
    validation_agents TEXT[] DEFAULT '{}',
    intelligence_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    collective_confidence NUMERIC CHECK (collective_confidence >= 0 AND collective_confidence <= 1),
    individual_confidences JSONB DEFAULT '{}'::jsonb,
    consensus_level NUMERIC CHECK (consensus_level >= 0 AND consensus_level <= 1),
    conflict_resolution JSONB DEFAULT '{}'::jsonb,
    collective_impact NUMERIC CHECK (collective_impact >= 0 AND collective_impact <= 100),
    intelligence_maturity TEXT DEFAULT 'emerging' CHECK (intelligence_maturity IN ('emerging', 'developing', 'mature', 'validated')),
    application_count INTEGER DEFAULT 0,
    success_rate NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days')
);

-- Table pour les réseaux d'agents IA
CREATE TABLE IF NOT EXISTS studio_agent_networks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    network_name TEXT NOT NULL,
    network_type TEXT NOT NULL CHECK (network_type IN ('hierarchical', 'peer_to_peer', 'hybrid', 'centralized')),
    network_nodes JSONB DEFAULT '{}'::jsonb,
    network_connections JSONB DEFAULT '{}'::jsonb,
    communication_protocols JSONB DEFAULT '{}'::jsonb,
    data_sharing_policies JSONB DEFAULT '{}'::jsonb,
    network_status TEXT DEFAULT 'active' CHECK (network_status IN ('active', 'inactive', 'degraded', 'failed')),
    network_performance JSONB DEFAULT '{}'::jsonb,
    last_activity TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les métriques d'intelligence collective
CREATE TABLE IF NOT EXISTS studio_collective_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_type TEXT NOT NULL CHECK (metric_type IN ('coordination', 'learning', 'intelligence', 'network', 'performance')),
    metric_category TEXT NOT NULL CHECK (metric_category IN ('efficiency', 'accuracy', 'collaboration', 'innovation', 'impact')),
    metric_value NUMERIC NOT NULL,
    metric_unit TEXT NOT NULL,
    baseline_value NUMERIC DEFAULT 0,
    improvement_percentage NUMERIC DEFAULT 0,
    measurement_period TEXT DEFAULT 'daily',
    contributing_factors JSONB DEFAULT '{}'::jsonb,
    measurement_context JSONB DEFAULT '{}'::jsonb,
    confidence_level NUMERIC CHECK (confidence_level >= 0 AND confidence_level <= 1),
    trend_direction TEXT CHECK (trend_direction IN ('up', 'down', 'stable', 'volatile')),
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '7 days')
);

-- Table pour les patterns d'intelligence collective
CREATE TABLE IF NOT EXISTS studio_collective_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_name TEXT NOT NULL,
    pattern_type TEXT NOT NULL CHECK (pattern_type IN ('collaboration', 'learning', 'decision', 'innovation', 'optimization')),
    pattern_description TEXT NOT NULL,
    pattern_frequency NUMERIC DEFAULT 0,
    pattern_strength NUMERIC CHECK (pattern_strength >= 0 AND pattern_strength <= 1),
    participating_agents TEXT[] DEFAULT '{}',
    pattern_outcomes JSONB DEFAULT '{}'::jsonb,
    pattern_value NUMERIC CHECK (pattern_value >= 0 AND pattern_value <= 100),
    pattern_maturity TEXT DEFAULT 'emerging' CHECK (pattern_maturity IN ('emerging', 'developing', 'mature', 'validated')),
    application_count INTEGER DEFAULT 0,
    success_rate NUMERIC DEFAULT 0,
    last_observed TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les décisions collectives
CREATE TABLE IF NOT EXISTS studio_collective_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    decision_id TEXT UNIQUE NOT NULL,
    decision_context TEXT NOT NULL,
    decision_type TEXT NOT NULL CHECK (decision_type IN ('strategic', 'tactical', 'operational', 'crisis')),
    participating_agents TEXT[] DEFAULT '{}',
    individual_preferences JSONB DEFAULT '{}'::jsonb,
    collective_preference JSONB DEFAULT '{}'::jsonb,
    decision_consensus NUMERIC CHECK (decision_consensus >= 0 AND decision_consensus <= 1),
    decision_confidence NUMERIC CHECK (decision_confidence >= 0 AND decision_confidence <= 1),
    decision_outcome JSONB DEFAULT '{}'::jsonb,
    decision_success NUMERIC CHECK (decision_success >= 0 AND decision_success <= 1),
    decision_efficiency NUMERIC CHECK (decision_efficiency >= 0 AND decision_efficiency <= 1),
    decision_timestamp TIMESTAMPTZ DEFAULT now(),
    implementation_status TEXT DEFAULT 'pending' CHECK (implementation_status IN ('pending', 'in_progress', 'completed', 'failed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les feedback loops d'intelligence collective
CREATE TABLE IF NOT EXISTS studio_collective_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feedback_session_id TEXT NOT NULL,
    feedback_source TEXT NOT NULL CHECK (feedback_source IN ('agent', 'system', 'human', 'environment')),
    feedback_type TEXT NOT NULL CHECK (feedback_type IN ('performance', 'accuracy', 'collaboration', 'learning', 'innovation')),
    feedback_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    feedback_metrics JSONB DEFAULT '{}'::jsonb,
    improvement_suggestions JSONB DEFAULT '[]'::jsonb,
    action_items JSONB DEFAULT '[]'::jsonb,
    feedback_priority TEXT DEFAULT 'medium' CHECK (feedback_priority IN ('low', 'medium', 'high', 'critical')),
    feedback_status TEXT DEFAULT 'open' CHECK (feedback_status IN ('open', 'in_progress', 'resolved', 'dismissed')),
    resolution_outcome JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS studio_agent_coordination_session_idx ON studio_agent_coordination(coordination_session_id);
CREATE INDEX IF NOT EXISTS studio_agent_coordination_status_idx ON studio_agent_coordination(coordination_status);
CREATE INDEX IF NOT EXISTS studio_agent_coordination_coordinator_idx ON studio_agent_coordination(coordinator_agent);
CREATE INDEX IF NOT EXISTS studio_continuous_learning_agent_idx ON studio_continuous_learning(learning_agent);
CREATE INDEX IF NOT EXISTS studio_continuous_learning_type_idx ON studio_continuous_learning(learning_type);
CREATE INDEX IF NOT EXISTS studio_continuous_learning_confidence_idx ON studio_continuous_learning(learning_confidence DESC);
CREATE INDEX IF NOT EXISTS studio_collective_intelligence_v2_id_idx ON studio_collective_intelligence_v2(intelligence_id);
CREATE INDEX IF NOT EXISTS studio_collective_intelligence_v2_type_idx ON studio_collective_intelligence_v2(intelligence_type);
CREATE INDEX IF NOT EXISTS studio_collective_intelligence_v2_confidence_idx ON studio_collective_intelligence_v2(collective_confidence DESC);
CREATE INDEX IF NOT EXISTS studio_collective_intelligence_v2_maturity_idx ON studio_collective_intelligence_v2(intelligence_maturity);
CREATE INDEX IF NOT EXISTS studio_agent_networks_status_idx ON studio_agent_networks(network_status);
CREATE INDEX IF NOT EXISTS studio_collective_metrics_type_idx ON studio_collective_metrics(metric_type);
CREATE INDEX IF NOT EXISTS studio_collective_metrics_category_idx ON studio_collective_metrics(metric_category);
CREATE INDEX IF NOT EXISTS studio_collective_patterns_type_idx ON studio_collective_patterns(pattern_type);
CREATE INDEX IF NOT EXISTS studio_collective_patterns_strength_idx ON studio_collective_patterns(pattern_strength DESC);
CREATE INDEX IF NOT EXISTS studio_collective_decisions_type_idx ON studio_collective_decisions(decision_type);
CREATE INDEX IF NOT EXISTS studio_collective_decisions_consensus_idx ON studio_collective_decisions(decision_consensus DESC);
CREATE INDEX IF NOT EXISTS studio_collective_feedback_status_idx ON studio_collective_feedback(feedback_status);
CREATE INDEX IF NOT EXISTS studio_collective_feedback_priority_idx ON studio_collective_feedback(feedback_priority);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer les triggers
DROP TRIGGER IF EXISTS set_studio_agent_coordination_updated_at ON studio_agent_coordination;
CREATE TRIGGER set_studio_agent_coordination_updated_at
    BEFORE UPDATE ON studio_agent_coordination
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_collective_intelligence_v2_updated_at ON studio_collective_intelligence_v2;
CREATE TRIGGER set_studio_collective_intelligence_v2_updated_at
    BEFORE UPDATE ON studio_collective_intelligence_v2
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_agent_networks_updated_at ON studio_agent_networks;
CREATE TRIGGER set_studio_agent_networks_updated_at
    BEFORE UPDATE ON studio_agent_networks
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_collective_patterns_updated_at ON studio_collective_patterns;
CREATE TRIGGER set_studio_collective_patterns_updated_at
    BEFORE UPDATE ON studio_collective_patterns
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_collective_decisions_updated_at ON studio_collective_decisions;
CREATE TRIGGER set_studio_collective_decisions_updated_at
    BEFORE UPDATE ON studio_collective_decisions
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Activer RLS
ALTER TABLE studio_agent_coordination ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_continuous_learning ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_collective_intelligence_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_agent_networks ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_collective_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_collective_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_collective_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_collective_feedback ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view agent coordination" ON studio_agent_coordination
    FOR SELECT USING (true);

CREATE POLICY "Users can manage agent coordination" ON studio_agent_coordination
    FOR ALL USING (true);

CREATE POLICY "Users can view continuous learning" ON studio_continuous_learning
    FOR SELECT USING (true);

CREATE POLICY "Users can manage continuous learning" ON studio_continuous_learning
    FOR ALL USING (true);

CREATE POLICY "Users can view collective intelligence v2" ON studio_collective_intelligence_v2
    FOR SELECT USING (true);

CREATE POLICY "Users can manage collective intelligence v2" ON studio_collective_intelligence_v2
    FOR ALL USING (true);

CREATE POLICY "Users can view agent networks" ON studio_agent_networks
    FOR SELECT USING (true);

CREATE POLICY "Users can manage agent networks" ON studio_agent_networks
    FOR ALL USING (true);

CREATE POLICY "Users can view collective metrics" ON studio_collective_metrics
    FOR SELECT USING (true);

CREATE POLICY "Users can manage collective metrics" ON studio_collective_metrics
    FOR ALL USING (true);

CREATE POLICY "Users can view collective patterns" ON studio_collective_patterns
    FOR SELECT USING (true);

CREATE POLICY "Users can manage collective patterns" ON studio_collective_patterns
    FOR ALL USING (true);

CREATE POLICY "Users can view collective decisions" ON studio_collective_decisions
    FOR SELECT USING (true);

CREATE POLICY "Users can manage collective decisions" ON studio_collective_decisions
    FOR ALL USING (true);

CREATE POLICY "Users can view collective feedback" ON studio_collective_feedback
    FOR SELECT USING (true);

CREATE POLICY "Users can manage collective feedback" ON studio_collective_feedback
    FOR ALL USING (true);

-- Donner les permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_agent_coordination TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_continuous_learning TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_collective_intelligence_v2 TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_agent_networks TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_collective_metrics TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_collective_patterns TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_collective_decisions TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_collective_feedback TO authenticated, anon;
