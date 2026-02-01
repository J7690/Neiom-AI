-- Implémentation RPC marketing minimaliste
-- Version sans paramètres TEXT pour éviter les erreurs de syntaxe

-- RPC 1: Générer des recommandations marketing
CREATE OR REPLACE FUNCTION generate_marketing_recommendation()
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
        'engagement',
        'Créer un post interactif pour stimuler les interactions',
        'Moment optimal pour engagement sur Facebook',
        'image',
        'Quel est votre rêve ? Partagez-le avec nous ! 💭🚀',
        'high',
        'pending'
    FROM generate_series(1, 5);
$$;

-- RPC 2: Approuver une recommandation
CREATE OR REPLACE FUNCTION approve_marketing_recommendation(p_recommendation_id TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    prepared_post_id TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_prepared_post_id TEXT;
BEGIN
    UPDATE studio_marketing_recommendations 
    SET status = 'approved',
        approved_at = now()
    WHERE id = p_recommendation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Recommandation non trouvée', NULL;
        RETURN;
    END IF;
    
    INSERT INTO studio_facebook_prepared_posts (
        recommendation_id,
        final_message,
        media_type,
        status
    ) VALUES (
        p_recommendation_id,
        'Quel est votre rêve ? Partagez-le avec nous ! 💭🚀',
        'image',
        'ready_for_validation'
    ) RETURNING id::TEXT INTO v_prepared_post_id;
    
    RETURN QUERY 
    SELECT true, 'Recommandation approuvée', v_prepared_post_id;
END;
$$;

-- RPC 3: Rejeter une recommandation
CREATE OR REPLACE FUNCTION reject_marketing_recommendation(p_recommendation_id TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
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

-- RPC 4: Récupérer les recommandations en attente
CREATE OR REPLACE FUNCTION get_pending_recommendations()
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
    LIMIT 10;
$$;

-- RPC 5: Créer des alertes marketing
CREATE OR REPLACE FUNCTION create_marketing_alert(p_alert_type TEXT, p_message TEXT)
RETURNS TABLE (
    success BOOLEAN,
    alert_id TEXT,
    message TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
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

-- Donner les permissions
GRANT EXECUTE ON FUNCTION generate_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION approve_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION reject_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_pending_recommendations TO authenticated, anon;
GRANT EXECUTE ON FUNCTION create_marketing_alert TO authenticated, anon;
