-- Création des RPC wrappers pour Facebook
-- Objectif mis à jour : utiliser la véritable Edge Function facebook/publish
-- pour publier sur Facebook, tout en continuant à stocker les posts dans
-- la table facebook_posts côté Supabase.

-- RPC pour publier sur Facebook en appelant l'Edge Function facebook/publish
CREATE OR REPLACE FUNCTION facebook_publish_post(
  p_type TEXT,
  p_message TEXT,
  p_image_url TEXT DEFAULT NULL,
  p_video_url TEXT DEFAULT NULL
)
RETURNS TABLE (
    id TEXT,
    type TEXT,
    status TEXT,
    url TEXT,
    post_id TEXT,
    error TEXT
) LANGUAGE PLPGSQL
SECURITY DEFINER AS $$
DECLARE
    v_supabase_url TEXT;
    v_anon_key TEXT;
    v_endpoint TEXT;
    v_payload JSONB;
    v_request_id BIGINT;
    v_collect_status TEXT;
    v_collect_message TEXT;
    v_status INT;
    v_body_text TEXT;
    v_body JSONB;
    v_row_id UUID;
    v_effective_type TEXT;
    v_effective_status TEXT;
    v_effective_url TEXT;
    v_effective_post_id TEXT;
    v_error TEXT;
BEGIN
    -- Récupérer la configuration nécessaire depuis app_settings
    SELECT value INTO v_supabase_url
    FROM public.app_settings
    WHERE key = 'SUPABASE_URL';

    SELECT value INTO v_anon_key
    FROM public.app_settings
    WHERE key = 'SUPABASE_ANON_KEY';

    IF v_supabase_url IS NULL OR v_anon_key IS NULL THEN
      RETURN QUERY
      SELECT
        NULL::TEXT,
        COALESCE(p_type, 'unknown')::TEXT,
        'failed'::TEXT,
        NULL::TEXT,
        NULL::TEXT,
        'SUPABASE_URL ou SUPABASE_ANON_KEY manquant dans app_settings'::TEXT;
      RETURN;
    END IF;

    v_endpoint := rtrim(v_supabase_url, '/') || '/functions/v1/facebook/publish';

    -- Construire le payload JSON envoyé à la fonction Edge
    v_payload := jsonb_build_object(
      'type', p_type,
      'message', p_message
    );

    IF p_image_url IS NOT NULL AND length(trim(p_image_url)) > 0 THEN
      v_payload := v_payload || jsonb_build_object('imageUrl', p_image_url);
    END IF;

    IF p_video_url IS NOT NULL AND length(trim(p_video_url)) > 0 THEN
      v_payload := v_payload || jsonb_build_object('videoUrl', p_video_url);
    END IF;

    -- Appel HTTP vers l'Edge Function facebook/publish
    -- Vérifier d'abord que l'extension pg_net / schéma net est disponible
    IF to_regnamespace('net') IS NULL THEN
      v_error := 'Extension pg_net / schéma net non disponible : impossible d''appeler facebook/publish depuis SQL.';
      RETURN QUERY
      SELECT
        NULL::TEXT,
        COALESCE(p_type, 'unknown')::TEXT,
        'failed'::TEXT,
        NULL::TEXT,
        NULL::TEXT,
        v_error;
      RETURN;
    END IF;

    BEGIN
      -- 1) Créer la requête HTTP POST JSON et obtenir un request_id
      SELECT net.http_post(
        url := v_endpoint,
        body := v_payload,
        params := '{}'::jsonb,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'apikey', v_anon_key,
          'Authorization', 'Bearer ' || v_anon_key
        ),
        timeout_milliseconds := 10000
      )
      INTO v_request_id;

      -- 2) Récupérer la réponse HTTP associée à ce request_id
      SELECT r.status,
             r.message,
             (r.response).status_code,
             (r.response).body
      INTO v_collect_status,
           v_collect_message,
           v_status,
           v_body_text
      FROM net.http_collect_response(v_request_id, async := false) AS r;

      -- Si pg_net signale une erreur (pas de SUCCESS), on renvoie un échec clair
      IF v_collect_status IS DISTINCT FROM 'SUCCESS' THEN
        v_error := format(
          'Erreur pg_net: status=%s, message=%s',
          COALESCE(v_collect_status, 'null'),
          COALESCE(v_collect_message, 'null')
        );

        RETURN QUERY
        SELECT
          NULL::TEXT,
          COALESCE(p_type, 'unknown')::TEXT,
          'failed'::TEXT,
          NULL::TEXT,
          NULL::TEXT,
          v_error;
        RETURN;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        v_error := format('Erreur lors de l''appel facebook/publish: %s', SQLERRM);
        RETURN QUERY
        SELECT
          NULL::TEXT,
          COALESCE(p_type, 'unknown')::TEXT,
          'failed'::TEXT,
          NULL::TEXT,
          NULL::TEXT,
          v_error;
        RETURN;
    END;

    IF v_status >= 400 OR v_body_text IS NULL THEN
      v_error := format('HTTP error %s lors de l''appel facebook/publish', v_status);

      RETURN QUERY
      SELECT
        NULL::TEXT,
        COALESCE(p_type, 'unknown')::TEXT,
        'failed'::TEXT,
        NULL::TEXT,
        NULL::TEXT,
        v_error;
      RETURN;
    END IF;

    v_body := COALESCE(v_body_text::JSONB, '{}'::JSONB);

    v_effective_type := COALESCE(v_body->>'type', p_type);
    v_effective_status := COALESCE(v_body->>'status', 'failed');
    v_effective_url := v_body->>'url';
    v_effective_post_id := COALESCE(v_body->>'postId', v_body->>'id');
    v_error := v_body->>'error';

    -- Enregistrer dans la table facebook_posts si un id est présent
    IF COALESCE(v_body->>'id', '') <> '' THEN
      INSERT INTO facebook_posts (
        type,
        message,
        image_url,
        video_url,
        status,
        facebook_post_id,
        facebook_url
      ) VALUES (
        v_effective_type,
        p_message,
        p_image_url,
        p_video_url,
        v_effective_status,
        v_effective_post_id,
        v_effective_url
      ) RETURNING facebook_posts.id INTO v_row_id;
    ELSE
      v_row_id := NULL;
    END IF;

    RETURN QUERY
    SELECT
      COALESCE(v_body->>'id', COALESCE(v_row_id::TEXT, '')),
      COALESCE(v_effective_type, 'unknown'),
      v_effective_status,
      v_effective_url,
      v_effective_post_id,
      v_error;
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
    service_timestamp TIMESTAMPTZ,
    service TEXT,
    version TEXT
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        'healthy' as status,
        now() as service_timestamp,
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
