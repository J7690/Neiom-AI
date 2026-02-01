-- Création des tables Facebook spécifiques pour compléter l'implémentation
-- Exécuter avec: python tools/admin_sql.py create_facebook_tables.sql

-- Table pour stocker les publications Facebook
CREATE TABLE IF NOT EXISTS facebook_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL CHECK (type IN ('text', 'image', 'video')),
    message TEXT NOT NULL,
    image_url TEXT,
    video_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'published', 'failed')),
    facebook_post_id TEXT,
    facebook_url TEXT,
    error_message TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS facebook_posts_status_idx ON facebook_posts(status);
CREATE INDEX IF NOT EXISTS facebook_posts_created_at_idx ON facebook_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS facebook_posts_facebook_post_id_idx ON facebook_posts(facebook_post_id) WHERE facebook_post_id IS NOT NULL;

-- Table pour stocker les commentaires Facebook
CREATE TABLE IF NOT EXISTS facebook_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facebook_post_id TEXT NOT NULL,
    facebook_comment_id TEXT NOT NULL,
    message TEXT NOT NULL,
    from_name TEXT,
    from_id TEXT,
    created_time TIMESTAMPTZ,
    like_count INTEGER DEFAULT 0,
    user_likes BOOLEAN DEFAULT false,
    can_reply BOOLEAN DEFAULT false,
    auto_reply_enabled BOOLEAN DEFAULT false,
    auto_reply_message TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index pour les commentaires
CREATE INDEX IF NOT EXISTS facebook_comments_post_id_idx ON facebook_comments(facebook_post_id);
CREATE INDEX IF NOT EXISTS facebook_comments_created_time_idx ON facebook_comments(created_time DESC);
CREATE UNIQUE INDEX IF NOT EXISTS facebook_comments_facebook_id_idx ON facebook_comments(facebook_comment_id);

-- Table pour stocker les insights/analytics Facebook
CREATE TABLE IF NOT EXISTS facebook_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name TEXT NOT NULL,
    period TEXT NOT NULL,
    value NUMERIC,
    end_time TIMESTAMPTZ,
    title TEXT,
    description TEXT,
    retrieved_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index pour les insights
CREATE INDEX IF NOT EXISTS facebook_insights_metric_period_idx ON facebook_insights(metric_name, period);
CREATE INDEX IF NOT EXISTS facebook_insights_retrieved_at_idx ON facebook_insights(retrieved_at DESC);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger aux tables qui l'ont besoin
DROP TRIGGER IF EXISTS set_facebook_posts_updated_at ON facebook_posts;
CREATE TRIGGER set_facebook_posts_updated_at
    BEFORE UPDATE ON facebook_posts
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Activer RLS sur les nouvelles tables
ALTER TABLE facebook_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE facebook_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE facebook_insights ENABLE ROW LEVEL SECURITY;

-- Politiques RLS (basiques - à affiner selon les besoins)
CREATE POLICY "Users can view their own facebook_posts" ON facebook_posts
    FOR SELECT USING (true);

CREATE POLICY "Users can insert facebook_posts" ON facebook_posts
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own facebook_posts" ON facebook_posts
    FOR UPDATE USING (true);

CREATE POLICY "Users can view facebook_comments" ON facebook_comments
    FOR SELECT USING (true);

CREATE POLICY "Users can insert facebook_comments" ON facebook_comments
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update facebook_comments" ON facebook_comments
    FOR UPDATE USING (true);

CREATE POLICY "Users can view facebook_insights" ON facebook_insights
    FOR SELECT USING (true);

CREATE POLICY "Users can insert facebook_insights" ON facebook_insights
    FOR INSERT WITH CHECK (true);

-- Donner les permissions nécessaires
GRANT SELECT, INSERT, UPDATE, DELETE ON facebook_posts TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON facebook_comments TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON facebook_insights TO authenticated, anon;

-- Fonctions RPC pour Facebook
CREATE OR REPLACE FUNCTION get_facebook_posts(p_limit INTEGER DEFAULT 50, p_offset INTEGER DEFAULT 0)
RETURNS TABLE (
    id UUID,
    type TEXT,
    message TEXT,
    image_url TEXT,
    video_url TEXT,
    status TEXT,
    facebook_post_id TEXT,
    facebook_url TEXT,
    error_message TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        fp.id,
        fp.type,
        fp.message,
        fp.image_url,
        fp.video_url,
        fp.status,
        fp.facebook_post_id,
        fp.facebook_url,
        fp.error_message,
        fp.created_at,
        fp.updated_at
    FROM facebook_posts fp
    ORDER BY fp.created_at DESC
    LIMIT p_limit OFFSET p_offset;
$$;

CREATE OR REPLACE FUNCTION get_facebook_post_comments(p_facebook_post_id TEXT, p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    id UUID,
    facebook_comment_id TEXT,
    message TEXT,
    from_name TEXT,
    from_id TEXT,
    created_time TIMESTAMPTZ,
    like_count INTEGER,
    user_likes BOOLEAN,
    can_reply BOOLEAN,
    auto_reply_enabled BOOLEAN,
    created_at TIMESTAMPTZ
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        fc.id,
        fc.facebook_comment_id,
        fc.message,
        fc.from_name,
        fc.from_id,
        fc.created_time,
        fc.like_count,
        fc.user_likes,
        fc.can_reply,
        fc.auto_reply_enabled,
        fc.created_at
    FROM facebook_comments fc
    WHERE fc.facebook_post_id = p_facebook_post_id
    ORDER BY fc.created_time ASC
    LIMIT p_limit;
$$;

CREATE OR REPLACE FUNCTION get_facebook_insights(p_period TEXT DEFAULT 'week', p_metric_name TEXT DEFAULT NULL)
RETURNS TABLE (
    metric_name TEXT,
    period TEXT,
    value NUMERIC,
    end_time TIMESTAMPTZ,
    title TEXT,
    description TEXT,
    retrieved_at TIMESTAMPTZ
) LANGUAGE SQL SECURITY DEFINER AS $$
    SELECT 
        fi.metric_name,
        fi.period,
        fi.value,
        fi.end_time,
        fi.title,
        fi.description,
        fi.retrieved_at
    FROM facebook_insights fi
    WHERE (p_period IS NULL OR fi.period = p_period)
      AND (p_metric_name IS NULL OR fi.metric_name = p_metric_name)
      AND fi.retrieved_at >= now() - INTERVAL '30 days'
    ORDER BY fi.retrieved_at DESC;
$$;

-- Donner les permissions pour les nouvelles fonctions RPC
GRANT EXECUTE ON FUNCTION get_facebook_posts TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_facebook_post_comments TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_facebook_insights TO authenticated, anon;
