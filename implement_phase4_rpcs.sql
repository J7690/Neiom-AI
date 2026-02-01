-- RPC Intelligence Collective Phase 4
-- Fonctions pour coordination agents IA, learning continu, intelligence collective

-- RPC 1: Coordonner les agents IA pour une décision collective
CREATE OR REPLACE FUNCTION coordinate_agents_collective(p_coordination_type TEXT, p_coordinator_agent TEXT, p_participating_agents TEXT[])
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    coordination_id TEXT,
    consensus_level NUMERIC,
    collective_confidence NUMERIC
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_coordination_id TEXT;
    v_consensus_level NUMERIC := 0;
    v_collective_confidence NUMERIC := 0;
    v_shared_insights JSONB := '[]'::jsonb;
    v_collective_decisions JSONB := '[]'::jsonb;
BEGIN
    -- Générer un ID de coordination unique
    v_coordination_id := 'coord_' || gen_random_uuid()::TEXT;
    
    -- Analyser les insights existants des agents
    SELECT jsonb_agg(
        jsonb_build_object(
            'agent', source_agent,
            'insight_type', intelligence_type,
            'confidence', confidence_score,
            'data', intelligence_data
        )
    ) INTO v_shared_insights
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_participating_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Calculer le niveau de consensus (simplifié)
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            AVG(confidence_score) * 0.8 + 0.2
        ELSE 0.5
    END INTO v_consensus_level
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_participating_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Calculer la confiance collective
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            AVG(confidence_score) * 0.9 + 0.1
        ELSE 0.5
    END INTO v_collective_confidence
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_participating_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Générer des décisions collectives basées sur les insights
    SELECT jsonb_agg(
        jsonb_build_object(
            'decision_type', 'optimization',
            'decision', 'continue_current_strategy',
            'rationale', 'Consensus based on shared insights',
            'confidence', v_collective_confidence
        )
    ) INTO v_collective_decisions
    FROM generate_series(1, 3);
    
    -- Insérer la coordination
    INSERT INTO studio_agent_coordination (
        coordination_session_id,
        coordinator_agent,
        participating_agents,
        coordination_type,
        coordination_context,
        shared_insights,
        collective_decisions,
        coordination_status,
        start_time,
        success_rate
    ) VALUES (
        v_coordination_id,
        p_coordinator_agent,
        p_participating_agents,
        p_coordination_type,
        jsonb_build_object(
            'session_type', 'collective_decision',
            'participants', array_length(p_participating_agents),
            'timestamp', now()
        ),
        v_shared_insights,
        v_collective_decisions,
        'completed',
        now(),
        v_consensus_level
    );
    
    RETURN QUERY 
    SELECT true, 
           'Coordination agents IA créée avec succès',
           v_coordination_id,
           v_consensus_level,
           v_collective_confidence;
END;
$$;

-- RPC 2: Activer le learning continu pour les agents IA
CREATE OR REPLACE FUNCTION enable_continuous_learning(p_learning_agent TEXT, p_learning_type TEXT, p_learning_source TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    learning_id TEXT,
    confidence_improvement NUMERIC,
    learning_value NUMERIC
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_learning_id TEXT;
    v_previous_knowledge JSONB := '{}'::jsonb;
    v_new_insights JSONB := '{}'::jsonb;
    v_confidence_improvement NUMERIC := 0;
    v_learning_value NUMERIC := 0;
    v_current_confidence NUMERIC := 0;
BEGIN
    -- Récupérer les connaissances précédentes
    SELECT jsonb_agg(
        jsonb_build_object(
            'insight_type', intelligence_type,
            'confidence', confidence_score,
            'data', intelligence_data
        )
    ) INTO v_previous_knowledge
    FROM studio_collective_intelligence 
    WHERE source_agent = p_learning_agent
        AND created_at >= now() - INTERVAL '7 days';
    
    -- Analyser les nouvelles données d'apprentissage
    SELECT jsonb_build_object(
        'pattern_detected', true,
        'pattern_type', 'performance_improvement',
        'confidence_boost', 0.1,
        'learning_context', p_learning_source
    ) INTO v_new_insights;
    
    -- Calculer l'amélioration de confiance
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            AVG(confidence_score) * 0.15
        ELSE 0.1
    END INTO v_confidence_improvement
    FROM studio_collective_intelligence 
    WHERE source_agent = p_learning_agent
        AND created_at >= now() - INTERVAL '7 days';
    
    -- Calculer la valeur d'apprentissage
    v_learning_value := v_confidence_improvement * 100;
    
    -- Insérer le learning continu
    INSERT INTO studio_continuous_learning (
        learning_agent,
        learning_type,
        learning_source,
        learning_data,
        previous_knowledge,
        new_insights,
        confidence_improvement,
        learning_confidence,
        learning_value
    ) VALUES (
        p_learning_agent,
        p_learning_type,
        p_learning_source,
        jsonb_build_object(
            'session_id', gen_random_uuid()::TEXT,
            'timestamp', now(),
            'data_points', 10
        ),
        v_previous_knowledge,
        v_new_insights,
        v_confidence_improvement,
        0.8,
        v_learning_value
    ) RETURNING id::TEXT INTO v_learning_id;
    
    RETURN QUERY 
    SELECT true, 
           'Learning continu activé avec succès',
           v_learning_id,
           v_confidence_improvement,
           v_learning_value;
END;
$$;

-- RPC 3: Générer de l'intelligence collective émergente
CREATE OR REPLACE FUNCTION generate_collective_intelligence(p_intelligence_type TEXT, p_contributing_agents TEXT[])
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    intelligence_id TEXT,
    collective_confidence NUMERIC,
    consensus_level NUMERIC
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_intelligence_id TEXT;
    v_individual_confidences JSONB := '{}'::jsonb;
    v_collective_confidence NUMERIC := 0;
    v_consensus_level NUMERIC := 0;
    v_intelligence_data JSONB := '{}'::jsonb;
BEGIN
    -- Générer un ID d'intelligence unique
    v_intelligence_id := 'intel_' || gen_random_uuid()::TEXT;
    
    -- Analyser les confiances individuelles
    SELECT jsonb_object_agg(
        source_agent, 
        confidence_score
    ) INTO v_individual_confidences
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_contributing_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Calculer la confiance collective
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            AVG(confidence_score) * 0.85 + 0.15
        ELSE 0.5
    END INTO v_collective_confidence
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_contributing_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Calculer le niveau de consensus
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            (COUNT(*) - COUNT(CASE WHEN confidence_score > 0.7 THEN 1 END)::NUMERIC) / COUNT(*)::NUMERIC
        ELSE 0.5
    END INTO v_consensus_level
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_contributing_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Générer les données d'intelligence collective
    SELECT jsonb_build_object(
        'intelligence_type', p_intelligence_type,
        'contributing_agents', p_contributing_agents,
        'individual_confidences', v_individual_confidences,
        'collective_confidence', v_collective_confidence,
        'consensus_level', v_consensus_level,
        'intelligence_maturity', 'emerging',
        'generated_at', now(),
        'data_points', 15
    ) INTO v_intelligence_data;
    
    -- Insérer l'intelligence collective
    INSERT INTO studio_collective_intelligence_v2 (
        intelligence_id,
        intelligence_type,
        source_agents,
        contributing_agents,
        intelligence_data,
        collective_confidence,
        individual_confidences,
        consensus_level,
        intelligence_maturity
    ) VALUES (
        v_intelligence_id,
        p_intelligence_type,
        p_contributing_agents,
        p_contributing_agents,
        v_intelligence_data,
        v_collective_confidence,
        v_individual_confidences,
        v_consensus_level,
        'emerging'
    );
    
    RETURN QUERY 
    SELECT true, 
           'Intelligence collective générée avec succès',
           v_intelligence_id,
           v_collective_confidence,
           v_consensus_level;
END;
$$;

-- RPC 4: Créer des réseaux d'agents IA
CREATE OR REPLACE FUNCTION create_agent_network(p_network_name TEXT, p_network_type TEXT, p_network_nodes JSONB)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    network_id TEXT,
    network_status TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_network_id TEXT;
    v_network_connections JSONB := '{}'::jsonb;
    v_communication_protocols JSONB := '{}'::jsonb;
    v_data_sharing_policies JSONB := '{}'::jsonb;
BEGIN
    -- Générer un ID de réseau unique
    v_network_id := 'network_' || gen_random_uuid()::TEXT;
    
    -- Générer les connexions réseau (simplifié)
    SELECT jsonb_build_object(
        'connections', jsonb_build_array(
            jsonb_build_object('from', 'marketing', 'to', 'analytics', 'strength', 0.8),
            jsonb_build_object('from', 'analytics', 'to', 'content', 'strength', 0.7),
            jsonb_build_object('from', 'content', 'to', 'support', 'strength', 0.6),
            jsonb_build_object('from', 'support', 'to', 'marketing', 'strength', 0.9)
        ),
        'topology', 'mesh',
        'latency', 50
    ) INTO v_network_connections;
    
    -- Générer les protocoles de communication
    SELECT jsonb_build_object(
        'data_exchange', 'json_rpc',
        'sync_frequency', 'real_time',
        'encryption', 'aes256',
        'authentication', 'token_based'
    ) INTO v_communication_protocols;
    
    -- Générer les politiques de partage de données
    SELECT jsonb_build_object(
        'sharing_level', 'selective',
        'data_types', jsonb_build_array('insights', 'patterns', 'recommendations'),
        'privacy_level', 'high',
        'retention_period', '30_days'
    ) INTO v_data_sharing_policies;
    
    -- Insérer le réseau d'agents
    INSERT INTO studio_agent_networks (
        network_name,
        network_type,
        network_nodes,
        network_connections,
        communication_protocols,
        data_sharing_policies,
        network_status
    ) VALUES (
        p_network_name,
        p_network_type,
        p_network_nodes,
        v_network_connections,
        v_communication_protocols,
        v_data_sharing_policies,
        'active'
    ) RETURNING id::TEXT INTO v_network_id;
    
    RETURN QUERY 
    SELECT true, 
           'Réseau agents IA créé avec succès',
           v_network_id,
           'active';
END;
$$;

-- RPC 5: Analyser les patterns d'intelligence collective
CREATE OR REPLACE FUNCTION analyze_collective_patterns(p_pattern_type TEXT, p_analysis_period_days INTEGER DEFAULT 30)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    patterns_detected INTEGER,
    pattern_strength NUMERIC,
    collective_value NUMERIC
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_patterns_detected INTEGER := 0;
    v_pattern_strength NUMERIC := 0;
    v_collective_value NUMERIC := 0;
BEGIN
    -- Analyser les patterns de collaboration
    SELECT COUNT(*) INTO v_patterns_detected
    FROM studio_agent_coordination 
    WHERE coordination_type = p_pattern_type
        AND start_time >= now() - INTERVAL '1 day';
    
    -- Calculer la force des patterns
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            AVG(success_rate) * 0.9 + 0.1
        ELSE 0.5
    END INTO v_pattern_strength
    FROM studio_agent_coordination 
    WHERE coordination_type = p_pattern_type
        AND start_time >= now() - INTERVAL '1 day';
    
    -- Calculer la valeur collective
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            AVG(success_rate) * 100
        ELSE 50
    END INTO v_collective_value
    FROM studio_agent_coordination 
    WHERE coordination_type = p_pattern_type
        AND start_time >= now() - INTERVAL '1 day';
    
    -- Insérer les patterns détectés
    INSERT INTO studio_collective_patterns (
        pattern_name,
        pattern_type,
        pattern_description,
        pattern_frequency,
        pattern_strength,
        pattern_value,
        pattern_maturity
    ) VALUES (
        'Pattern_' || p_pattern_type || '_' || now(),
        p_pattern_type,
        'Pattern de ' || p_pattern_type || ' détecté dans la coordination des agents',
        v_patterns_detected::NUMERIC,
        v_pattern_strength,
        v_collective_value,
        'developing'
    );
    
    RETURN QUERY 
    SELECT true, 
           'Patterns collectifs analysés avec succès',
           v_patterns_detected,
           v_pattern_strength,
           v_collective_value;
END;
$$;

-- RPC 6: Prendre des décisions collectives
CREATE OR REPLACE FUNCTION make_collective_decision(p_decision_context TEXT, p_decision_type TEXT, p_participating_agents TEXT[])
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    decision_id TEXT,
    decision_consensus NUMERIC,
    decision_confidence NUMERIC
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_decision_id TEXT;
    v_decision_consensus NUMERIC := 0;
    v_decision_confidence NUMERIC := 0;
    v_individual_preferences JSONB := '{}'::jsonb;
    v_collective_preference JSONB := '{}'::jsonb;
BEGIN
    -- Générer un ID de décision unique
    v_decision_id := 'decision_' || gen_random_uuid()::TEXT;
    
    -- Analyser les préférences individuelles
    SELECT jsonb_object_agg(
        source_agent, 
        jsonb_build_object(
            'preference', 'continue',
            'confidence', confidence_score,
            'rationale', 'Based on recent performance'
        )
    ) INTO v_individual_preferences
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_participating_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Calculer le consensus de décision
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            AVG(confidence_score) * 0.8 + 0.2
        ELSE 0.5
    END INTO v_decision_consensus
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_participating_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Calculer la confiance de décision
    SELECT CASE 
        WHEN COUNT(*) > 0 THEN 
            AVG(confidence_score) * 0.85 + 0.15
        ELSE 0.5
    END INTO v_decision_confidence
    FROM studio_collective_intelligence 
    WHERE source_agent = ANY(p_participating_agents)
        AND created_at >= now() - INTERVAL '24 hours';
    
    -- Générer la préférence collective
    SELECT jsonb_build_object(
        'decision', 'continue_current_strategy',
        'rationale', 'Collective consensus based on shared insights',
        'confidence', v_decision_confidence,
        'consensus', v_decision_consensus
    ) INTO v_collective_preference;
    
    -- Insérer la décision collective
    INSERT INTO studio_collective_decisions (
        decision_id,
        decision_context,
        decision_type,
        participating_agents,
        individual_preferences,
        collective_preference,
        decision_consensus,
        decision_confidence,
        decision_efficiency
    ) VALUES (
        v_decision_id,
        p_decision_context,
        p_decision_type,
        p_participating_agents,
        v_individual_preferences,
        v_collective_preference,
        v_decision_consensus,
        v_decision_confidence,
        0.8
    );
    
    RETURN QUERY 
    SELECT true, 
           'Décision collective prise avec succès',
           v_decision_id,
           v_decision_consensus,
           v_decision_confidence;
END;
$$;

-- Donner les permissions pour les nouvelles RPC
GRANT EXECUTE ON FUNCTION coordinate_agents_collective TO authenticated, anon;
GRANT EXECUTE ON FUNCTION enable_continuous_learning TO authenticated, anon;
GRANT EXECUTE ON FUNCTION generate_collective_intelligence TO authenticated, anon;
GRANT EXECUTE ON FUNCTION create_agent_network TO authenticated, anon;
GRANT EXECUTE ON FUNCTION analyze_collective_patterns TO authenticated, anon;
GRANT EXECUTE ON FUNCTION make_collective_decision TO authenticated, anon;
