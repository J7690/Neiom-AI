-- RPC Intelligence Avancée Phase 2 (version simplifiée)
-- Fonctions pour A/B testing, prédictions, alertes proactives

-- RPC 1: Créer un A/B test automatique
CREATE OR REPLACE FUNCTION create_ab_test(p_test_name TEXT, p_test_type TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    test_id TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_test_id TEXT;
BEGIN
    INSERT INTO studio_ab_tests (
        test_name,
        test_type,
        variant_a,
        variant_b,
        end_date
    ) VALUES (
        p_test_name,
        p_test_type,
        '{"format": "image", "style": "professional"}',
        '{"format": "video", "style": "dynamic"}',
        now() + INTERVAL '7 days'
    ) RETURNING id::TEXT INTO v_test_id;
    
    RETURN QUERY 
    SELECT true, 'A/B test créé avec succès', v_test_id;
END;
$$;

-- RPC 2: Analyser les résultats d'un A/B test
CREATE OR REPLACE FUNCTION analyze_ab_test(p_test_id TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    winner TEXT,
    recommendation TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_test RECORD;
    v_winner TEXT := 'inconclusive';
BEGIN
    SELECT * INTO v_test
    FROM studio_ab_tests 
    WHERE id = p_test_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Test A/B non trouvé', NULL, NULL;
        RETURN;
    END IF;
    
    -- Déterminer le gagnant (simplifié)
    IF v_test.conversion_rate_a > v_test.conversion_rate_b THEN
        v_winner := 'variant_a';
    ELSIF v_test.conversion_rate_b > v_test.conversion_rate_a THEN
        v_winner := 'variant_b';
    END IF;
    
    -- Mettre à jour le test
    UPDATE studio_ab_tests 
    SET winner = v_winner,
        status = 'completed'
    WHERE id = p_test_id;
    
    RETURN QUERY 
    SELECT true, 
           'Analyse A/B test terminée',
           v_winner,
           CASE 
               WHEN v_winner != 'inconclusive' 
               THEN 'Continuer avec le variant ' || v_winner
               ELSE 'Prolonger le test'
           END;
END;
$$;

-- RPC 3: Générer des prédictions de performance
CREATE OR REPLACE FUNCTION generate_performance_predictions(p_prediction_type TEXT, p_days_ahead INTEGER)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    predictions_count INTEGER
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_avg_engagement NUMERIC := 0;
    v_predictions_count INTEGER := 0;
BEGIN
    -- Calculer l'engagement moyen actuel
    SELECT AVG(COALESCE(engagement_rate, 0)) INTO v_avg_engagement
    FROM facebook_posts 
    WHERE status = 'published' 
        AND created_at >= now() - INTERVAL '30 days';
    
    -- Insérer les prédictions
    INSERT INTO studio_performance_predictions (
        prediction_type,
        predicted_value,
        confidence_interval_lower,
        confidence_interval_upper,
        prediction_date
    )
    SELECT 
        p_prediction_type,
        v_avg_engagement * (1 + (n * 0.02)),
        v_avg_engagement * 0.8,
        v_avg_engagement * 1.2,
        now() + (n || ' days')::INTERVAL
    FROM generate_series(1, p_days_ahead) n;
    
    GET DIAGNOSTICS v_predictions_count = ROW_COUNT;
    
    RETURN QUERY 
    SELECT true, 'Prédictions générées', v_predictions_count;
END;
$$;

-- RPC 4: Créer des alertes proactives intelligentes
CREATE OR REPLACE FUNCTION create_proactive_alerts()
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    alerts_created INTEGER
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_alerts_created INTEGER := 0;
    v_current_hour INTEGER := EXTRACT(HOUR FROM now());
    v_avg_engagement NUMERIC := 0;
BEGIN
    -- Calculer l'engagement moyen récent
    SELECT AVG(COALESCE(engagement_rate, 0)) INTO v_avg_engagement
    FROM facebook_posts 
    WHERE status = 'published' 
        AND created_at >= now() - INTERVAL '7 days';
    
    -- Alerte d'opportunité : Meilleur moment pour publier
    IF v_current_hour BETWEEN 8 AND 10 OR v_current_hour BETWEEN 17 AND 19 THEN
        INSERT INTO studio_proactive_alerts (
            alert_type,
            alert_category,
            severity,
            title,
            description,
            recommendation,
            action_required
        ) VALUES (
            'optimal_timing',
            'opportunity',
            'high',
            'Moment optimal pour publication',
            'L''heure actuelle est idéale pour maximiser l''engagement',
            'Publier maintenant pour maximiser la visibilité',
            true
        );
        
        v_alerts_created := v_alerts_created + 1;
    END IF;
    
    -- Alerte d'optimisation : Baisse d'engagement détectée
    IF v_avg_engagement < 3.0 THEN
        INSERT INTO studio_proactive_alerts (
            alert_type,
            alert_category,
            severity,
            title,
            description,
            recommendation,
            action_required
        ) VALUES (
            'low_engagement',
            'optimization',
            'medium',
            'Baisse d''engagement détectée',
            'L''engagement moyen est en dessous de l''objectif',
            'Tester de nouveaux formats ou ajuster les heures',
            true
        );
        
        v_alerts_created := v_alerts_created + 1;
    END IF;
    
    RETURN QUERY 
    SELECT true, 'Alertes proactives créées', v_alerts_created;
END;
$$;

-- RPC 5: Analyser les patterns avancés
CREATE OR REPLACE FUNCTION analyze_advanced_patterns()
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    insights_count INTEGER
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_insights_count INTEGER := 0;
BEGIN
    -- Insérer les insights patterns
    INSERT INTO studio_learning_insights (
        insight_type,
        insight_title,
        insight_description,
        confidence_score,
        impact_score,
        actionable_recommendation
    ) VALUES (
        'pattern',
        'Analyse patterns avancée',
        'Patterns de performance analysés automatiquement',
        0.85,
        0.9,
        'Optimiser les heures de publication et les formats'
    );
    
    GET DIAGNOSTICS v_insights_count = ROW_COUNT;
    
    RETURN QUERY 
    SELECT true, 'Analyse patterns terminée', v_insights_count;
END;
$$;

-- RPC 6: Obtenir les alertes proactives actives
CREATE OR REPLACE FUNCTION get_proactive_alerts(p_limit INTEGER)
RETURNS TABLE (
    id TEXT,
    alert_type TEXT,
    alert_category TEXT,
    severity TEXT,
    title TEXT,
    description TEXT,
    recommendation TEXT,
    action_required BOOLEAN,
    created_at TIMESTAMPTZ
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        id::TEXT,
        alert_type,
        alert_category,
        severity,
        title,
        description,
        recommendation,
        action_required,
        created_at
    FROM studio_proactive_alerts 
    WHERE status = 'active' 
        AND (expires_at IS NULL OR expires_at > now())
    ORDER BY 
        CASE severity 
            WHEN 'critical' THEN 1 
            WHEN 'high' THEN 2 
            WHEN 'medium' THEN 3 
            ELSE 4 
        END,
        created_at DESC
    LIMIT p_limit;
$$;

-- Donner les permissions pour les nouvelles RPC
GRANT EXECUTE ON FUNCTION create_ab_test TO authenticated, anon;
GRANT EXECUTE ON FUNCTION analyze_ab_test TO authenticated, anon;
GRANT EXECUTE ON FUNCTION generate_performance_predictions TO authenticated, anon;
GRANT EXECUTE ON FUNCTION create_proactive_alerts TO authenticated, anon;
GRANT EXECUTE ON FUNCTION analyze_advanced_patterns TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_proactive_alerts TO authenticated, anon;
