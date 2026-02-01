-- Création des RPC wrappers pour simuler les Edge Functions Facebook
-- Ces RPC permettent à Flutter d'appeler les fonctionnalités Facebook sans Edge Functions

-- RPC pour publier sur Facebook (simule l'Edge Function)
CREATE OR REPLACE FUNCTION facebook_publish_post(p_type TEXT, p_message TEXT, p_image_url TEXT DEFAULT NULL, p_video_url TEXT DEFAULT NULL)
RETURNS TABLE (
    id TEXT,
    type TEXT,
    status TEXT,
    url TEXT,
    post_id TEXT,
    error TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
DECLARE
    v_post_id UUID;
    v_facebook_url TEXT;
BEGIN
    -- Insérer dans la table facebook_posts
    INSERT INTO facebook_posts (
        type, 
        message, 
        image_url, 
        video_url, 
        status, 
        facebook_post_id, 
        facebook_url
    ) VALUES (
        p_type,
        p_message,
        p_image_url,
        p_video_url,
        'published',
        'fb_' || gen_random_uuid()::TEXT,
        'https://facebook.com/' || gen_random_uuid()::TEXT
    ) RETURNING id INTO v_post_id;
    
    -- Construire l'URL Facebook
    v_facebook_url := 'https://facebook.com/fb_' || v_post_id::TEXT;
    
    -- Mettre à jour l'URL
    UPDATE facebook_posts 
    SET facebook_url = v_facebook_url 
    WHERE id = v_post_id;
    
    -- Retourner le résultat
    RETURN QUERY
    SELECT 
        v_post_id::TEXT,
        p_type,
        'published',
        v_facebook_url,
        'fb_' || v_post_id::TEXT,
        NULL::TEXT;
END;
$$;

-- RPC pour récupérer les commentaires (simule l'Edge Function)
CREATE OR REPLACE FUNCTION facebook_get_comments(p_facebook_post_id TEXT DEFAULT NULL, p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    id TEXT,
    message TEXT,
    created_time TIMESTAMPTZ,
    from_name TEXT,
    from_id TEXT,
    like_count INTEGER,
    can_reply BOOLEAN
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        fc.id::TEXT,
        fc.message,
        fc.created_time,
        fc.from_name,
        fc.from_id,
        fc.like_count,
        fc.can_reply
    FROM facebook_comments fc
    WHERE (p_facebook_post_id IS NULL OR fc.facebook_post_id = p_facebook_post_id)
    ORDER BY fc.created_time DESC
    LIMIT p_limit;
$$;

-- RPC pour répondre à un commentaire (simule l'Edge Function)
CREATE OR REPLACE FUNCTION facebook_reply_comment(p_comment_id TEXT, p_message TEXT)
RETURNS TABLE (
    success BOOLEAN,
    comment_id TEXT,
    error TEXT
) LANGUAGE PLPGSQL SECURITY DEFINER AS $$
BEGIN
    -- Insérer la réponse comme nouveau commentaire
    INSERT INTO facebook_comments (
        facebook_post_id,
        facebook_comment_id,
        message,
        from_name,
        from_id,
        created_time,
        can_reply,
        auto_reply_enabled
    ) VALUES (
        (SELECT facebook_post_id FROM facebook_comments WHERE facebook_comment_id = p_comment_id),
        'reply_' || gen_random_uuid()::TEXT,
        p_message,
        'Nexiom Studio',
        'studio_bot',
        now(),
        false,
        false
    );
    
    RETURN QUERY
    SELECT 
        true,
        p_comment_id,
        NULL::TEXT;
END;
$$;

-- RPC pour les insights Facebook (simule l'Edge Function)
CREATE OR REPLACE FUNCTION facebook_get_insights(p_period TEXT DEFAULT 'week')
RETURNS TABLE (
    total_followers INTEGER,
    weekly_impressions INTEGER,
    weekly_engagements INTEGER,
    engagement_rate NUMERIC
) LANGUAGE SQL SECURITY DEFINER AS $$
    -- Simuler les insights avec des données réelles si disponibles
    SELECT 
        COALESCE((SELECT COUNT(*)::INTEGER FROM social_channels WHERE channel_type = 'facebook' AND status = 'active'), 1000) as total_followers,
        COALESCE((SELECT COUNT(*)::INTEGER * 25 FROM facebook_posts WHERE created_at >= now() - INTERVAL '7 days'), 2500) as weekly_impressions,
        COALESCE((SELECT COUNT(*)::INTEGER * 5 FROM facebook_comments WHERE created_at >= now() - INTERVAL '7 days'), 150) as weekly_engagements,
        CASE 
            WHEN (SELECT COUNT(*) FROM facebook_posts WHERE created_at >= now() - INTERVAL '7 days') > 0
            THEN ROUND((SELECT COUNT(*)::NUMERIC * 5.0 FROM facebook_comments WHERE created_at >= now() - INTERVAL '7 days') / (SELECT COUNT(*)::NUMERIC * 25.0 FROM facebook_posts WHERE created_at >= now() - INTERVAL '7 days') * 100, 2)
            ELSE 6.0
        END as engagement_rate;
$$;

-- RPC pour le dashboard Facebook (simule l'Edge Function)
CREATE OR REPLACE FUNCTION facebook_dashboard()
RETURNS TABLE (
    total_followers INTEGER,
    weekly_impressions INTEGER,
    weekly_engagements INTEGER,
    engagement_rate NUMERIC
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT * FROM facebook_get_insights('week');
$$;

-- RPC pour la santé du service (simule l'Edge Function)
CREATE OR REPLACE FUNCTION facebook_health()
RETURNS TABLE (
    status TEXT,
    timestamp TIMESTAMPTZ,
    service TEXT,
    version TEXT
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        'healthy' as status,
        now() as timestamp,
        'facebook-studio-api' as service,
        '1.0.0' as version;
$$;

-- Donner les permissions pour les nouvelles RPC
GRANT EXECUTE ON FUNCTION facebook_publish_post TO authenticated, anon;
GRANT EXECUTE ON FUNCTION facebook_get_comments TO authenticated, anon;
GRANT EXECUTE ON FUNCTION facebook_reply_comment TO authenticated, anon;
GRANT EXECUTE ON FUNCTION facebook_get_insights TO authenticated, anon;
GRANT EXECUTE ON FUNCTION facebook_dashboard TO authenticated, anon;
GRANT EXECUTE ON FUNCTION facebook_health TO authenticated, anon;
