-- RPC Intelligence Avancée Phase 2
-- Fonctions pour A/B testing, prédictions, alertes proactives

-- RPC 1: Créer et lancer un A/B test automatique
CREATE OR REPLACE FUNCTION create_ab_test(p_test_name TEXT, p_test_type TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    test_id TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_test_id TEXT;
    v_variant_a JSONB;
    v_variant_b JSONB;
BEGIN
    -- Créer les variantes selon le type de test
    CASE p_test_type
        WHEN 'format' THEN
            v_variant_a := jsonb_build_object('format', 'image', 'style', 'professional');
            v_variant_b := jsonb_build_object('format', 'video', 'style', 'dynamic');
        WHEN 'timing' THEN
            v_variant_a := jsonb_build_object('hour', 9, 'day', 'weekday');
            v_variant_b := jsonb_build_object('hour', 18, 'day', 'weekday');
        WHEN 'content' THEN
            v_variant_a := jsonb_build_object('tone', 'professional', 'cta', 'learn_more');
            v_variant_b := jsonb_build_object('tone', 'casual', 'cta', 'join_now');
        ELSE
            v_variant_a := jsonb_build_object('default', 'variant_a');
            v_variant_b := jsonb_build_object('default', 'variant_b');
    END CASE;
    
    -- Insérer le test A/B
    INSERT INTO studio_ab_tests (
        test_name,
        test_type,
        variant_a,
        variant_b,
        end_date
    ) VALUES (
        p_test_name,
        p_test_type,
        v_variant_a,
        v_variant_b,
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
    confidence_level NUMERIC,
    recommendation TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_test RECORD;
    v_significance BOOLEAN;
    v_winner TEXT;
BEGIN
    -- Récupérer les données du test
    SELECT * INTO v_test
    FROM studio_ab_tests 
    WHERE id = p_test_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Test A/B non trouvé', NULL, NULL, NULL;
        RETURN;
    END IF;
    
    -- Calculer la significativité statistique (simplifié)
    v_significance := (v_test.sample_size_a > 10 AND v_test.sample_size_b > 10) 
                     AND ABS(v_test.conversion_rate_a - v_test.conversion_rate_b) > 0.05;
    
    -- Déterminer le gagnant
    IF v_significance THEN
        IF v_test.conversion_rate_a > v_test.conversion_rate_b THEN
            v_winner := 'variant_a';
        ELSE
            v_winner := 'variant_b';
        END IF;
    ELSE
        v_winner := 'inconclusive';
    END IF;
    
    -- Mettre à jour le test
    UPDATE studio_ab_tests 
    SET winner = v_winner,
        statistical_significance = v_significance,
        status = CASE 
            WHEN v_significance THEN 'completed'
            ELSE 'active'
        END
    WHERE id = p_test_id;
    
    RETURN QUERY 
    SELECT true, 
           'Analyse A/B test terminée',
           v_winner,
           v_test.confidence_level,
           CASE 
               WHEN v_significance AND v_winner != 'inconclusive' 
               THEN 'Continuer avec le variant ' || v_winner
               ELSE 'Prolonger le test ou réessayer avec des variantes différentes'
           END;
END;
$$;

-- RPC 3: Générer des prédictions de performance
CREATE OR REPLACE FUNCTION generate_performance_predictions(p_prediction_type TEXT, p_days_ahead INTEGER DEFAULT 7)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    predictions JSONB
) LANGUAGE SQL SECURITY DEFINER AS $$
DECLARE
    v_predictions JSONB := '[]'::jsonb;
    v_avg_engagement NUMERIC := 0;
    v_trend_factor NUMERIC := 1.0;
BEGIN
    -- Calculer l'engagement moyen actuel
    SELECT AVG(COALESCE(engagement_rate, 0)) INTO v_avg_engagement
    FROM facebook_posts 
    WHERE status = 'published' 
        AND created_at >= now() - INTERVAL '30 days';
    
    -- Calculer le facteur de tendance (simplifié)
    SELECT CASE 
        WHEN COUNT(*) >= 3 THEN 
            1.0 + (AVG(COALESCE(engagement_rate, 0)) / v_avg_engagement - 1.0) * 0.1
        ELSE 1.0
    END INTO v_trend_factor
    FROM facebook_posts 
    WHERE status = 'published'
        AND created_at >= now() - INTERVAL '7 days';
    
    -- Générer les prédictions pour les prochains jours
    SELECT jsonb_agg(
        jsonb_build_object(
            'date', (now() + (n || ' days')::INTERVAL)::DATE,
            'predicted_value', v_avg_engagement * v_trend_factor * (1 + (n * 0.02)),
            'confidence_lower', v_avg_engagement * v_trend_factor * 0.8,
            'confidence_upper', v_avg_engagement * v_trend_factor * 1.2,
            'confidence_level', 0.85
        )
    ) INTO v_predictions
    FROM generate_series(1, p_days_ahead) n;
    
    -- Insérer les prédictions en base
    INSERT INTO studio_performance_predictions (
        prediction_type,
        predicted_value,
        confidence_interval_lower,
        confidence_interval_upper,
        prediction_date,
        input_features
    )
    SELECT 
        p_prediction_type,
        (v_avg_engagement * v_trend_factor * (1 + (n * 0.02))),
        (v_avg_engagement * v_trend_factor * 0.8),
        (v_avg_engagement * v_trend_factor * 1.2),
        (now() + (n || ' days')::INTERVAL),
        jsonb_build_object('avg_engagement', v_avg_engagement, 'trend_factor', v_trend_factor)
    FROM generate_series(1, p_days_ahead) n;
    
    RETURN QUERY 
    SELECT true, 'Prédictions générées avec succès', v_predictions;
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
    v_best_format TEXT := 'image';
BEGIN
    -- Calculer l'engagement moyen récent
    SELECT AVG(COALESCE(engagement_rate, 0)) INTO v_avg_engagement
    FROM facebook_posts 
    WHERE status = 'published' 
        AND created_at >= now() - INTERVAL '7 days';
    
    -- Déterminer le meilleur format
    SELECT type INTO v_best_format
    FROM facebook_posts 
    WHERE status = 'published'
        AND created_at >= now() - INTERVAL '30 days'
    GROUP BY type
    ORDER BY AVG(COALESCE(engagement_rate, 0)) DESC
    LIMIT 1;
    
    -- Alerte d'opportunité : Meilleur moment pour publier
    IF v_current_hour BETWEEN 8 AND 10 OR v_current_hour BETWEEN 17 AND 19 THEN
        INSERT INTO studio_proactive_alerts (
            alert_type,
            alert_category,
            severity,
            title,
            description,
            recommendation,
            action_required,
            auto_executable,
            trigger_conditions
        ) VALUES (
            'optimal_timing',
            'opportunity',
            'high',
            'Moment optimal pour publication',
            'L''heure actuelle est idéale pour maximiser l''engagement',
            'Publier maintenant avec le format ' || v_best_format || ' pour maximiser la visibilité',
            true,
            false,
            jsonb_build_object('hour', v_current_hour, 'engagement_avg', v_avg_engagement)
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
            action_required,
            auto_executable,
            trigger_conditions
        ) VALUES (
            'low_engagement',
            'optimization',
            'medium',
            'Baisse d''engagement détectée',
            'L''engagement moyen est de ' || ROUND(v_avg_engagement, 2) || '%, en dessous de l''objectif',
            'Tester de nouveaux formats ou ajuster les heures de publication',
            true,
            false,
            jsonb_build_object('engagement_avg', v_avg_engagement, 'threshold', 3.0)
        );
        
        v_alerts_created := v_alerts_created + 1;
    END IF;
    
    -- Alerte de tendance : Format performant identifié
    IF v_best_format != 'image' THEN
        INSERT INTO studio_proactive_alerts (
            alert_type,
            alert_category,
            severity,
            title,
            description,
            recommendation,
            action_required,
            auto_executable,
            trigger_conditions
        ) VALUES (
            'format_opportunity',
            'trend',
            'low',
            'Format ' || v_best_format || ' performe bien',
            'Le format ' || v_best_format || ' montre de meilleures performances récentes',
            'Augmenter la proportion de contenus ' || v_best_format || ' dans la stratégie',
            false,
            false,
            jsonb_build_object('best_format', v_best_format, 'performance_avg', v_avg_engagement)
        );
        
        v_alerts_created := v_alerts_created + 1;
    END IF;
    
    RETURN QUERY 
    SELECT true, 'Alertes proactives créées avec succès', v_alerts_created;
END;
$$;

-- RPC 5: Analyser les patterns avancés
CREATE OR REPLACE FUNCTION analyze_advanced_patterns()
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    insights JSONB
) LANGUAGE SQL SECURITY DEFINER AS $$
DECLARE
    v_insights JSONB := '[]'::jsonb;
    v_hourly_performance JSONB := '[]'::jsonb;
    v_format_performance JSONB := '[]'::jsonb;
    v_weekly_trend NUMERIC := 0;
BEGIN
    -- Analyser les performances par heure
    SELECT jsonb_agg(
        jsonb_build_object(
            'hour', EXTRACT(HOUR FROM created_at),
            'avg_engagement', AVG(COALESCE(engagement_rate, 0)),
            'post_count', COUNT(*),
            'optimal', AVG(COALESCE(engagement_rate, 0)) > (
                SELECT AVG(COALESCE(engagement_rate, 0))
                FROM facebook_posts 
                WHERE status = 'published' 
                    AND created_at >= now() - INTERVAL '30 days'
            )
        )
    ) INTO v_hourly_performance
    FROM facebook_posts 
    WHERE status = 'published'
        AND created_at >= now() - INTERVAL '30 days'
    GROUP BY EXTRACT(HOUR FROM created_at);
    
    -- Analyser les performances par format
    SELECT jsonb_agg(
        jsonb_build_object(
            'format', type,
            'avg_engagement', AVG(COALESCE(engagement_rate, 0)),
            'post_count', COUNT(*),
            'performance_score', AVG(COALESCE(engagement_rate, 0)) * COUNT(*) / 10
        )
    ) INTO v_format_performance
    FROM facebook_posts 
    WHERE status = 'published'
        AND created_at >= now() - INTERVAL '30 days'
    GROUP BY type;
    
    -- Calculer la tendance hebdomadaire
    SELECT (
        AVG(COALESCE(engagement_rate, 0)) - 
        LAG(AVG(COALESCE(engagement_rate, 0))) OVER (ORDER BY DATE_TRUNC('week', created_at))
    ) INTO v_weekly_trend
    FROM facebook_posts 
    WHERE status = 'published'
        AND created_at >= now() - INTERVAL '60 days'
    GROUP BY DATE_TRUNC('week', created_at)
    ORDER BY DATE_TRUNC('week', created_at)
    LIMIT 1;
    
    -- Construire les insights complets
    v_insights := jsonb_build_object(
        'hourly_performance', v_hourly_performance,
        'format_performance', v_format_performance,
        'weekly_trend', v_weekly_trend,
        'recommendations', jsonb_build_array(
            'Publier principalement aux heures avec le plus haut engagement',
            'Augmenter l''utilisation des formats les plus performants',
            CASE WHEN v_weekly_trend > 0 THEN 'Continuer la stratégie actuelle' ELSE 'Ajuster la stratégie' END
        ),
        'analysis_date', now()
    );
    
    -- Insérer les insights dans la table d'apprentissage
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
        'Patterns de performance par heure et format analysés',
        0.85,
        0.9,
        'Optimiser les heures de publication et les formats de contenu'
    );
    
    RETURN QUERY 
    SELECT true, 'Analyse patterns avancée terminée', v_insights;
END;
$$;

-- RPC 6: Obtenir les alertes proactives actives
CREATE OR REPLACE FUNCTION get_proactive_alerts(p_limit INTEGER DEFAULT 10)
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
