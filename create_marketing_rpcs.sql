-- Création des RPC pour l'architecture décisionnelle marketing
-- Exécuter avec: python tools/admin_sql.py create_marketing_rpcs.sql

-- RPC pour générer des recommandations marketing
CREATE OR REPLACE FUNCTION generate_marketing_recommendation(p_objective TEXT DEFAULT NULL, p_count INTEGER DEFAULT 5)
RETURNS TABLE (
    id UUID,
    objective TEXT,
    recommendation_summary TEXT,
    reasoning TEXT,
    proposed_format TEXT,
    proposed_message TEXT,
    proposed_media_prompt TEXT,
    confidence_level TEXT,
    status TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_current_hour INTEGER := EXTRACT(HOUR FROM now());
    v_current_day TEXT := TO_CHAR(now(), 'Day');
    v_best_format TEXT;
    v_best_timing TEXT;
BEGIN
    -- Analyser les patterns existants pour déterminer le meilleur format
    SELECT COALESCE(pattern_name, 'image') INTO v_best_format
    FROM studio_performance_patterns 
    WHERE pattern_type = 'format' AND is_active = true
    ORDER BY confidence_score DESC, performance_impact DESC
    LIMIT 1;
    
    -- Si pas de pattern, utiliser 'image' par défaut
    IF v_best_format IS NULL THEN
        v_best_format := 'image';
    END IF;
    
    -- Générer les recommandations basées sur l'analyse
    RETURN QUERY
    SELECT 
        gen_random_uuid() as id,
        COALESCE(p_objective, 'engagement') as objective,
        CASE 
            WHEN v_best_format = 'video' THEN 'Créer une vidéo éducative courte aujourd''hui'
            WHEN v_best_format = 'image' THEN 'Publier un visuel attractif avec message engageant'
            ELSE 'Partager un message textuel percutant'
        END as recommendation_summary,
        CASE 
            WHEN v_current_hour BETWEEN 8 AND 12 THEN 'Matin : moment optimal pour engagement'
            WHEN v_current_hour BETWEEN 12 AND 14 THEN 'Midi : pic d''activité sur Facebook'
            WHEN v_current_hour BETWEEN 17 AND 20 THEN 'Soir : meilleur moment pour notoriété'
            ELSE 'Hors créneau habituel : tester nouvelle plage horaire'
        END as reasoning,
        v_best_format as proposed_format,
        CASE 
            WHEN v_best_format = 'video' THEN 'Découvrez nos formations de manière dynamique !'
            WHEN v_best_format = 'image' THEN 'Votre avenir commence ici. #Education #Excellence'
            ELSE 'Rejoignez la meilleure institution éducative du Burkina Faso'
        END as proposed_message,
        CASE 
            WHEN v_best_format = 'video' THEN 'Video éducative, institutionnelle, professionnelle, dynamique'
            WHEN v_best_format = 'image' THEN 'Image institutionnelle, professionnelle, éducation, moderne'
            ELSE 'Texte percutant, éducation, avenir, excellence'
        END as proposed_media_prompt,
        CASE 
            WHEN v_current_hour BETWEEN 8 AND 20 THEN 'high'
            ELSE 'medium'
        END as confidence_level,
        'pending' as status,
        now() as created_at
    FROM generate_series(1, p_count);
END;
$$;

-- RPC pour approuver une recommandation
CREATE OR REPLACE FUNCTION approve_marketing_recommendation(p_recommendation_id UUID, p_approved_by TEXT DEFAULT 'studio_admin')
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    prepared_post_id UUID
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_recommendation RECORD;
    v_prepared_post_id UUID;
BEGIN
    -- Récupérer la recommandation
    SELECT * INTO v_recommendation 
    FROM studio_marketing_recommendations 
    WHERE id = p_recommendation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Recommandation non trouvée ou déjà traitée', NULL::UUID;
        RETURN;
    END IF;
    
    -- Mettre à jour le statut de la recommandation
    UPDATE studio_marketing_recommendations 
    SET status = 'approved',
        approved_at = now(),
        approved_by = p_approved_by
    WHERE id = p_recommendation_id;
    
    -- Créer le post préparé
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
    ) RETURNING id INTO v_prepared_post_id;
    
    RETURN QUERY 
    SELECT true, 'Recommandation approuvée avec succès', v_prepared_post_id;
END;
$$;

-- RPC pour rejeter une recommandation
CREATE OR REPLACE FUNCTION reject_marketing_recommendation(p_recommendation_id UUID, p_reason TEXT DEFAULT 'Rejeté par administrateur')
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
BEGIN
    UPDATE studio_marketing_recommendations 
    SET status = 'rejected',
        approved_at = now(),
        approved_by = 'studio_admin',
        metadata = jsonb_set(metadata, '{"rejection_reason"}', to_jsonb(p_reason))
    WHERE id = p_recommendation_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Recommandation non trouvée ou déjà traitée';
        RETURN;
    END IF;
    
    RETURN QUERY SELECT true, 'Recommandation rejetée avec succès';
END;
$$;

-- RPC pour publier un post préparé
CREATE OR REPLACE FUNCTION publish_prepared_post(p_prepared_post_id UUID)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    facebook_post_id TEXT,
    facebook_url TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_prepared_post RECORD;
    v_facebook_result RECORD;
    v_facebook_post_id TEXT;
    v_facebook_url TEXT;
BEGIN
    -- Récupérer le post préparé
    SELECT pp.*, mr.proposed_format, mr.proposed_media_prompt
    INTO v_prepared_post
    FROM studio_facebook_prepared_posts pp
    JOIN studio_marketing_recommendations mr ON pp.recommendation_id = mr.id
    WHERE pp.id = p_prepared_post_id AND pp.status = 'approved';
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Post non trouvé ou non approuvé', NULL, NULL;
        RETURN;
    END IF;
    
    -- Simuler la publication via Facebook RPC
    SELECT * INTO v_facebook_result
    FROM facebook_publish_post(
        v_prepared_post.proposed_format,
        v_prepared_post.final_message,
        CASE WHEN v_prepared_post.proposed_format = 'image' THEN 'https://example.com/generated_image.jpg' ELSE NULL END,
        CASE WHEN v_prepared_post.proposed_format = 'video' THEN 'https://example.com/generated_video.mp4' ELSE NULL END
    );
    
    IF v_facebook_result.id IS NOT NULL THEN
        v_facebook_post_id := v_facebook_result.post_id;
        v_facebook_url := v_facebook_result.url;
        
        -- Mettre à jour le statut
        UPDATE studio_facebook_prepared_posts 
        SET status = 'published',
            updated_at = now()
        WHERE id = p_prepared_post_id;
        
        -- Mettre à jour la recommandation
        UPDATE studio_marketing_recommendations 
        SET status = 'published',
            published_at = now(),
            published_facebook_id = v_facebook_post_id
        WHERE id = v_prepared_post.recommendation_id;
        
        RETURN QUERY SELECT true, 'Publication réussie', v_facebook_post_id, v_facebook_url;
    ELSE
        RETURN QUERY SELECT false, 'Échec de publication Facebook', NULL, NULL;
    END IF;
END;
$$;

-- RPC pour récupérer les recommandations en attente
CREATE OR REPLACE FUNCTION get_pending_recommendations(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    objective TEXT,
    recommendation_summary TEXT,
    reasoning TEXT,
    proposed_format TEXT,
    proposed_message TEXT,
    confidence_level TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        id,
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

-- RPC pour créer des alertes marketing
CREATE OR REPLACE FUNCTION create_marketing_alert(p_alert_type TEXT, p_message TEXT, p_priority TEXT DEFAULT 'medium')
RETURNS TABLE (
    success BOOLEAN,
    alert_id UUID,
    message TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_alert_id UUID;
BEGIN
    INSERT INTO studio_marketing_alerts (
        alert_type,
        message,
        priority
    ) VALUES (
        p_alert_type,
        p_message,
        p_priority
    ) RETURNING id INTO v_alert_id;
    
    RETURN QUERY 
    SELECT true, v_alert_id, 'Alerte créée avec succès';
END;
$$;

-- RPC pour analyser les patterns de performance
CREATE OR REPLACE FUNCTION analyze_performance_patterns()
RETURNS TABLE (
    patterns_detected INTEGER,
    best_format TEXT,
    best_timing_hour INTEGER,
    insights JSONB
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
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
            WHEN AVG(engagement_rate) > 5.0 THEN 0.8
            WHEN AVG(engagement_rate) > 3.0 THEN 0.6
            ELSE 0.4
        END,
        AVG(engagement_rate) - 2.0,
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
    ORDER BY AVG(engagement_rate) DESC
    LIMIT 1;
    
    -- Construire les insights
    v_insights := jsonb_build_object(
        'total_patterns', v_patterns_count,
        'best_format', v_best_format,
        'best_hour', v_best_hour,
        'analysis_date', now()
    );
    
    RETURN QUERY 
    SELECT v_patterns_count, v_best_format, v_best_hour, v_insights;
END;
$$;

-- RPC pour obtenir les objectifs marketing et leur progression
CREATE OR REPLACE FUNCTION get_marketing_objectives()
RETURNS TABLE (
    id UUID,
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
        id,
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

-- Donner les permissions pour les nouvelles RPC (signatures explicites pour éviter toute ambiguïté)
GRANT EXECUTE ON FUNCTION generate_marketing_recommendation(TEXT, INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION approve_marketing_recommendation(UUID, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION reject_marketing_recommendation(UUID, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION publish_prepared_post(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_pending_recommendations(INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION create_marketing_alert(TEXT, TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION analyze_performance_patterns() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_marketing_objectives() TO authenticated, anon;
