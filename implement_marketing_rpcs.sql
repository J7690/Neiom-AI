-- Implémentation des RPC marketing décisionnelles
-- Phase 1 : Fonctions critiques pour le workflow décisionnel

-- RPC 1: Générer des recommandations marketing IA
CREATE OR REPLACE FUNCTION generate_marketing_recommendation(p_objective TEXT DEFAULT 'engagement', p_count INTEGER DEFAULT 5)
RETURNS TABLE (
    id TEXT,
    objective TEXT,
    recommendation_summary TEXT,
    reasoning TEXT,
    proposed_format TEXT,
    proposed_message TEXT,
    proposed_media_prompt TEXT,
    confidence_level TEXT,
    status TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        gen_random_uuid()::TEXT,
        p_objective,
        CASE p_objective
            WHEN 'notoriety' THEN 'Publier un contenu viral pour augmenter la visibilité'
            WHEN 'engagement' THEN 'Créer un post interactif pour stimuler les interactions'
            WHEN 'conversion' THEN 'Partager une offre attractive pour générer des inscriptions'
            ELSE 'Publier un contenu équilibré pour maintenir l''engagement'
        END,
        CASE 
            WHEN EXTRACT(HOUR FROM now()) BETWEEN 8 AND 12 THEN 'Matin : moment optimal pour atteindre les étudiants'
            WHEN EXTRACT(HOUR FROM now()) BETWEEN 12 AND 14 THEN 'Midi : pic d''activité sur Facebook'
            WHEN EXTRACT(HOUR FROM now()) BETWEEN 17 AND 20 THEN 'Soir : meilleur moment pour les décisions'
            ELSE 'Hors créneau : tester nouvelle plage horaire'
        END,
        CASE 
            WHEN p_objective = 'notoriety' THEN 'video'
            WHEN p_objective = 'engagement' THEN 'image'
            ELSE 'text'
        END,
        CASE p_objective
            WHEN 'notoriety' THEN 'Découvrez pourquoi Academia est le meilleur choix ! 🎓✨'
            WHEN 'engagement' THEN 'Quel est votre rêve ? Partagez-le avec nous ! 💭🚀'
            WHEN 'conversion' THEN 'Places limitées ! Inscrivez-vous dès maintenant. 📚⏰'
            ELSE 'Rejoignez une communauté qui valorise votre excellence. 🌟'
        END,
        CASE p_objective
            WHEN 'notoriety' THEN 'Video institutionnelle, professionnelle, éducation, moderne, dynamique'
            WHEN 'engagement' THEN 'Image engageante, communautaire, étudiants, interaction, positive'
            ELSE 'Texte informatif, professionnel, éducation, opportunity'
        END,
        CASE 
            WHEN EXTRACT(HOUR FROM now()) BETWEEN 8 AND 20 THEN 'high'
            ELSE 'medium'
        END,
        'pending',
        now()
    FROM generate_series(1, p_count);
$$;

-- RPC 2: Approuver une recommandation (validation 1-click)
CREATE OR REPLACE FUNCTION approve_marketing_recommendation(p_recommendation_id TEXT, p_approved_by TEXT DEFAULT 'studio_admin')
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    prepared_post_id TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_recommendation RECORD;
    v_prepared_post_id TEXT;
BEGIN
    -- Récupérer la recommandation
    SELECT * INTO v_recommendation 
    FROM studio_marketing_recommendations 
    WHERE id = p_recommendation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Recommandation non trouvée ou déjà traitée', NULL;
        RETURN;
    END IF;
    
    -- Mettre à jour le statut de la recommandation
    UPDATE studio_marketing_recommendations 
    SET status = 'approved',
        approved_at = now(),
        approved_by = p_approved_by
    WHERE id = p_recommendation_id;
    
    -- Créer le post préparé pour validation finale
    INSERT INTO studio_facebook_prepared_posts (
        recommendation_id,
        final_message,
        media_type,
        status
    ) VALUES (
        p_recommendation_id,
        v_recommendation.proposed_message,
        v_recommendation.proposed_format,
        'ready_for_validation'
    ) RETURNING id::TEXT INTO v_prepared_post_id;
    
    RETURN QUERY 
    SELECT true, 'Recommandation approuvée avec succès', v_prepared_post_id;
END;
$$;

-- RPC 3: Rejeter une recommandation
CREATE OR REPLACE FUNCTION reject_marketing_recommendation(p_recommendation_id TEXT, p_reason TEXT DEFAULT 'Rejeté par administrateur')
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
BEGIN
    UPDATE studio_marketing_recommendations 
    SET status = 'rejected',
        approved_at = now(),
        approved_by = 'studio_admin'
    WHERE id = p_recommendation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Recommandation non trouvée ou déjà traitée';
        RETURN;
    END IF;
    
    RETURN QUERY SELECT true, 'Recommandation rejetée avec succès';
END;
$$;

-- RPC 4: Publier un post préparé (après validation finale)
CREATE OR REPLACE FUNCTION publish_prepared_post(p_prepared_post_id TEXT)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    facebook_post_id TEXT,
    facebook_url TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_prepared_post RECORD;
    v_facebook_result RECORD;
BEGIN
    -- Récupérer le post préparé
    SELECT pp.*, mr.proposed_format
    INTO v_prepared_post
    FROM studio_facebook_prepared_posts pp
    JOIN studio_marketing_recommendations mr ON pp.recommendation_id = mr.id
    WHERE pp.id = p_prepared_post_id AND pp.status = 'ready_for_validation';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Post non trouvé ou non prêt', NULL, NULL;
        RETURN;
    END IF;
    
    -- Publier via Facebook RPC
    SELECT * INTO v_facebook_result
    FROM facebook_publish_post(
        v_prepared_post.proposed_format,
        v_prepared_post.final_message,
        CASE WHEN v_prepared_post.proposed_format = 'image' THEN 'https://example.com/generated_image.jpg' ELSE NULL END,
        CASE WHEN v_prepared_post.proposed_format = 'video' THEN 'https://example.com/generated_video.mp4' ELSE NULL END
    );
    
    IF v_facebook_result.id IS NOT NULL THEN
        -- Mettre à jour le statut
        UPDATE studio_facebook_prepared_posts 
        SET status = 'published',
            updated_at = now()
        WHERE id = p_prepared_post_id;
        
        -- Mettre à jour la recommandation
        UPDATE studio_marketing_recommendations 
        SET status = 'published',
            published_at = now(),
            published_facebook_id = v_facebook_result.post_id
        WHERE id = v_prepared_post.recommendation_id;
        
        RETURN QUERY SELECT true, 'Publication réussie', v_facebook_result.post_id, v_facebook_result.url;
    ELSE
        RETURN QUERY SELECT false, 'Échec de publication Facebook', NULL, NULL;
    END IF;
END;
$$;

-- RPC 5: Récupérer les recommandations en attente
CREATE OR REPLACE FUNCTION get_pending_recommendations(p_limit INTEGER DEFAULT 10)
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
    ORDER BY 
        CASE confidence_level 
            WHEN 'high' THEN 1 
            WHEN 'medium' THEN 2 
            ELSE 3 
        END,
        created_at DESC
    LIMIT p_limit;
$$;

-- RPC 6: Créer des alertes marketing intelligentes
CREATE OR REPLACE FUNCTION create_marketing_alert(p_alert_type TEXT, p_message TEXT, p_priority TEXT DEFAULT 'medium')
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
        message,
        priority
    ) VALUES (
        p_alert_type,
        p_message,
        p_priority
    ) RETURNING id::TEXT INTO v_alert_id;
    
    RETURN QUERY 
    SELECT true, v_alert_id, 'Alerte marketing créée avec succès';
END;
$$;

-- RPC 7: Analyser les patterns de performance
CREATE OR REPLACE FUNCTION analyze_performance_patterns()
RETURNS TABLE (
    patterns_detected INTEGER,
    best_format TEXT,
    best_hour INTEGER,
    insights JSONB
) LANGUAGE SQL SECURITY DEFINER AS $$
DECLARE
    v_patterns_count INTEGER := 0;
    v_best_format TEXT := 'image';
    v_best_hour INTEGER := 12;
    v_insights JSONB;
BEGIN
    -- Analyser les formats qui performent
    INSERT INTO studio_performance_patterns (
        pattern_type,
        pattern_name,
        description,
        confidence_score,
        performance_impact,
        sample_size
    )
    SELECT 
        'format',
        type,
        'Format ' || type || ' performe bien',
        CASE 
            WHEN AVG(COALESCE(engagement_rate, 0)) > 5.0 THEN 0.8
            WHEN AVG(COALESCE(engagement_rate, 0)) > 3.0 THEN 0.6
            ELSE 0.4
        END,
        AVG(COALESCE(engagement_rate, 0)) - 2.0,
        COUNT(*)
    FROM facebook_posts 
    WHERE status = 'published' 
        AND created_at >= now() - INTERVAL '30 days'
    GROUP BY type
    HAVING COUNT(*) >= 3
    ON CONFLICT DO NOTHING;
    
    -- Compter les patterns détectés
    SELECT COUNT(*) INTO v_patterns_count
    FROM studio_performance_patterns 
    WHERE is_active = true;
    
    -- Déterminer le meilleur format
    SELECT pattern_name INTO v_best_format
    FROM studio_performance_patterns 
    WHERE pattern_type = 'format' AND is_active = true
    ORDER BY confidence_score DESC, performance_impact DESC
    LIMIT 1;
    
    -- Déterminer la meilleure heure
    SELECT EXTRACT(HOUR FROM created_at)::INTEGER INTO v_best_hour
    FROM facebook_posts 
    WHERE status = 'published'
        AND created_at >= now() - INTERVAL '30 days'
    GROUP BY EXTRACT(HOUR FROM created_at)
    ORDER BY AVG(COALESCE(engagement_rate, 0)) DESC
    LIMIT 1;
    
    -- Construire les insights
    v_insights := jsonb_build_object(
        'total_patterns', v_patterns_count,
        'best_format', COALESCE(v_best_format, 'image'),
        'best_hour', v_best_hour,
        'analysis_date', now(),
        'recommendation', 'Continuer avec le format ' || COALESCE(v_best_format, 'image') || ' à ' || v_best_hour || 'h'
    );
    
    RETURN QUERY 
    SELECT v_patterns_count, v_best_format, v_best_hour, v_insights;
END;
$$;

-- RPC 8: Obtenir les objectifs marketing et leur progression
CREATE OR REPLACE FUNCTION get_marketing_objectives()
RETURNS TABLE (
    id TEXT,
    objective TEXT,
    target_value NUMERIC,
    current_value NUMERIC,
    unit TEXT,
    horizon TEXT,
    progress_percentage NUMERIC,
    status TEXT,
    target_date DATE
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        id::TEXT,
        objective,
        target_value,
        current_value,
        unit,
        horizon,
        progress_percentage,
        status,
        target_date
    FROM studio_marketing_objectives 
    WHERE status = 'active'
    ORDER BY progress_percentage DESC;
$$;

-- Donner les permissions pour les nouvelles RPC
GRANT EXECUTE ON FUNCTION generate_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION approve_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION reject_marketing_recommendation TO authenticated, anon;
GRANT EXECUTE ON FUNCTION publish_prepared_post TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_pending_recommendations TO authenticated, anon;
GRANT EXECUTE ON FUNCTION create_marketing_alert TO authenticated, anon;
GRANT EXECUTE ON FUNCTION analyze_performance_patterns TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_marketing_objectives TO authenticated, anon;
