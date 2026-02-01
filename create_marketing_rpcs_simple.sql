-- Création des RPC simples pour l'architecture décisionnelle marketing
-- Exécuter avec: python tools/admin_sql.py create_marketing_rpcs_simple.sql

-- RPC pour générer des recommandations marketing
CREATE OR REPLACE FUNCTION generate_marketing_recommendation(p_objective TEXT, p_count INTEGER)
RETURNS TABLE (
    id TEXT,
    objective TEXT,
    recommendation_summary TEXT,
    reasoning TEXT,
    proposed_format TEXT,
    proposed_message TEXT,
    confidence_level TEXT,
    status TEXT
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        gen_random_uuid()::TEXT,
        COALESCE(p_objective, 'engagement'),
        'Publier un visuel attractif avec message engageant',
        'Moment optimal pour engagement sur Facebook',
        'image',
        'Votre avenir commence ici. #Education #Excellence',
        'high',
        'pending'
    FROM generate_series(1, COALESCE(p_count, 5));
$$;

-- RPC pour approuver une recommandation
CREATE OR REPLACE FUNCTION approve_marketing_recommendation(p_recommendation_id TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    prepared_post_id TEXT
) LANGUAGE SQL SECURITY DEFINER AS $$
DECLARE
    v_prepared_post_id TEXT;
BEGIN
    -- Mettre à jour le statut de la recommandation
    UPDATE studio_marketing_recommendations 
    SET status = 'approved',
        approved_at = now()
    WHERE id = p_recommendation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Recommandation non trouvée', NULL;
        RETURN;
    END IF;
    
    -- Créer le post préparé
    INSERT INTO studio_facebook_prepared_posts (
        recommendation_id,
        final_message,
        media_type,
        status
    ) VALUES (
        p_recommendation_id,
        'Votre avenir commence ici. #Education #Excellence',
        'image',
        'ready_for_validation'
    ) RETURNING id::TEXT INTO v_prepared_post_id;
    
    RETURN QUERY 
    SELECT true, 'Recommandation approuvée', v_prepared_post_id;
END;
$$;

-- RPC pour rejeter une recommandation
CREATE OR REPLACE FUNCTION reject_marketing_recommendation(p_recommendation_id TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) LANGUAGE SQL SECURITY DEFINER AS $$
BEGIN
    UPDATE studio_marketing_recommendations 
    SET status = 'rejected',
        approved_at = now()
    WHERE id = p_recommendation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Recommandation non trouvée';
        RETURN;
    END IF;
    
    RETURN QUERY SELECT true, 'Recommandation rejetée';
END;
$$;

-- RPC pour récupérer les recommandations en attente
CREATE OR REPLACE FUNCTION get_pending_recommendations(p_limit INTEGER)
RETURNS TABLE (
    id TEXT,
    objective TEXT,
    recommendation_summary TEXT,
    reasoning TEXT,
    proposed_format TEXT,
    proposed_message TEXT,
    confidence_level TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        id::TEXT,
        objective,
        recommendation_summary,
        reasoning,
        proposed_format,
        proposed_message,
        confidence_level,
        created_at
    FROM studio_marketing_recommendations 
    WHERE status = 'pending'
    ORDER BY created_at DESC
    LIMIT COALESCE(p_limit, 10);
$$;

-- RPC pour créer des alertes marketing
CREATE OR REPLACE FUNCTION create_marketing_alert(p_alert_type TEXT, p_message TEXT)
RETURNS TABLE (
    success BOOLEAN,
    alert_id TEXT,
    message TEXT
) LANGUAGE SQL SECURITY DEFINER AS $$
DECLARE
    v_alert_id TEXT;
BEGIN
    INSERT INTO studio_marketing_alerts (
        alert_type,
        message
    ) VALUES (
        p_alert_type,
        p_message
    ) RETURNING id::TEXT INTO v_alert_id;
    
    RETURN QUERY 
    SELECT true, v_alert_id, 'Alerte créée';
END;
$$;

-- RPC pour analyser les patterns de performance
CREATE OR REPLACE FUNCTION analyze_performance_patterns()
RETURNS TABLE (
    patterns_detected INTEGER,
    best_format TEXT,
    insights JSONB
) LANGUAGE SQL SECURITY DEFINER AS $$
DECLARE
    v_patterns_count INTEGER := 0;
    v_best_format TEXT := 'image';
    v_insights JSONB;
BEGIN
    -- Compter les posts existants
    SELECT COUNT(*) INTO v_patterns_count
    FROM facebook_posts 
    WHERE status = 'published' 
        AND created_at >= now() - INTERVAL '30 days';
    
    -- Déterminer le meilleur format
    SELECT type INTO v_best_format
    FROM facebook_posts 
    WHERE status = 'published'
        AND created_at >= now() - INTERVAL '30 days'
    GROUP BY type
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    -- Construire les insights
    v_insights := jsonb_build_object(
        'total_patterns', v_patterns_count,
        'best_format', COALESCE(v_best_format, 'image'),
        'analysis_date', now()
    );
    
    RETURN QUERY 
    SELECT v_patterns_count, v_best_format, v_insights;
END;
$$;

-- RPC pour obtenir les objectifs marketing
CREATE OR REPLACE FUNCTION get_marketing_objectives()
RETURNS TABLE (
    id TEXT,
    objective TEXT,
    target_value NUMERIC,
    current_value NUMERIC,
    progress_percentage NUMERIC,
    status TEXT
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        id::TEXT,
        objective,
        target_value,
        current_value,
        progress_percentage,
        status
    FROM studio_marketing_objectives 
    WHERE status = 'active'
    ORDER BY progress_percentage DESC;
$$;

-- Donner les permissions pour les nouvelles RPC
GRANT EXECUTE ON FUNCTION generate_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION approve_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION reject_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_pending_recommendations TO authenticated, anon;
GRANT EXECUTE ON FUNCTION create_marketing_alert TO authenticated, anon;
GRANT EXECUTE ON FUNCTION analyze_performance_patterns TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_marketing_objectives TO authenticated, anon;
