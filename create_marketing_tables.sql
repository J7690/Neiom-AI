-- Création des tables marketing pour architecture décisionnelle
-- Exécuter avec: python tools/admin_sql.py create_marketing_tables.sql

-- Table centrale des recommandations marketing
CREATE TABLE IF NOT EXISTS studio_marketing_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    objective TEXT NOT NULL CHECK (objective IN ('notoriety', 'engagement', 'conversion')),
    recommendation_summary TEXT NOT NULL,
    reasoning TEXT,
    proposed_format TEXT CHECK (proposed_format IN ('text', 'image', 'video')),
    proposed_message TEXT,
    proposed_media_prompt TEXT,
    confidence_level TEXT CHECK (confidence_level IN ('low', 'medium', 'high')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'published', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT now(),
    approved_at TIMESTAMPTZ,
    approved_by TEXT,
    published_at TIMESTAMPTZ,
    published_facebook_id TEXT,
    performance_metrics JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Table des posts préparés pour validation
CREATE TABLE IF NOT EXISTS studio_facebook_prepared_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recommendation_id UUID REFERENCES studio_marketing_recommendations(id) ON DELETE CASCADE,
    final_message TEXT NOT NULL,
    media_url TEXT,
    media_type TEXT CHECK (media_type IN ('text', 'image', 'video')),
    media_generated BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'ready_for_validation' CHECK (status IN ('ready_for_validation', 'approved', 'rejected', 'published')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table des alertes marketing intelligentes
CREATE TABLE IF NOT EXISTS studio_marketing_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type TEXT NOT NULL,
    message TEXT NOT NULL,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'dismissed')),
    action_required BOOLEAN DEFAULT false,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Table des objectifs marketing avec tracking
CREATE TABLE IF NOT EXISTS studio_marketing_objectives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    objective TEXT NOT NULL,
    target_value NUMERIC NOT NULL,
    current_value NUMERIC DEFAULT 0,
    unit TEXT DEFAULT 'count',
    horizon TEXT CHECK (horizon IN ('short_term', 'medium_term', 'long_term')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused')),
    start_date DATE,
    target_date DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    progress_percentage NUMERIC GENERATED ALWAYS AS (
        CASE 
            WHEN target_value > 0 THEN ROUND((current_value / target_value) * 100, 2)
            ELSE 0
        END
    ) STORED
);

-- Table des patterns de performance détectés
CREATE TABLE IF NOT EXISTS studio_performance_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_type TEXT NOT NULL, -- 'timing', 'format', 'content', 'cta'
    pattern_name TEXT NOT NULL,
    description TEXT,
    confidence_score NUMERIC CHECK (confidence_score >= 0 AND confidence_score <= 1),
    performance_impact NUMERIC, -- % d'amélioration observée
    sample_size INTEGER DEFAULT 0,
    valid_from TIMESTAMPTZ DEFAULT now(),
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour le suivi des cycles d'analyse
CREATE TABLE IF NOT EXISTS studio_analysis_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cycle_date DATE NOT NULL,
    analysis_type TEXT DEFAULT 'daily',
    posts_analyzed INTEGER DEFAULT 0,
    recommendations_generated INTEGER DEFAULT 0,
    recommendations_approved INTEGER DEFAULT 0,
    recommendations_published INTEGER DEFAULT 0,
    performance_score NUMERIC,
    insights JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS studio_marketing_recommendations_status_idx ON studio_marketing_recommendations(status);
CREATE INDEX IF NOT EXISTS studio_marketing_recommendations_created_at_idx ON studio_marketing_recommendations(created_at DESC);
CREATE INDEX IF NOT EXISTS studio_marketing_recommendations_objective_idx ON studio_marketing_recommendations(objective);

CREATE INDEX IF NOT EXISTS studio_facebook_prepared_posts_status_idx ON studio_facebook_prepared_posts(status);
CREATE INDEX IF NOT EXISTS studio_facebook_prepared_posts_recommendation_id_idx ON studio_facebook_prepared_posts(recommendation_id);

CREATE INDEX IF NOT EXISTS studio_marketing_alerts_status_idx ON studio_marketing_alerts(status);
CREATE INDEX IF NOT EXISTS studio_marketing_alerts_priority_idx ON studio_marketing_alerts(priority);
CREATE INDEX IF NOT EXISTS studio_marketing_alerts_created_at_idx ON studio_marketing_alerts(created_at DESC);

CREATE INDEX IF NOT EXISTS studio_marketing_objectives_status_idx ON studio_marketing_objectives(status);
CREATE INDEX IF NOT EXISTS studio_marketing_objectives_horizon_idx ON studio_marketing_objectives(horizon);

CREATE INDEX IF NOT EXISTS studio_performance_patterns_active_idx ON studio_performance_patterns(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS studio_performance_patterns_type_idx ON studio_performance_patterns(pattern_type);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger
DROP TRIGGER IF EXISTS set_studio_facebook_prepared_posts_updated_at ON studio_facebook_prepared_posts;
CREATE TRIGGER set_studio_facebook_prepared_posts_updated_at
    BEFORE UPDATE ON studio_facebook_prepared_posts
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_marketing_objectives_updated_at ON studio_marketing_objectives;
CREATE TRIGGER set_studio_marketing_objectives_updated_at
    BEFORE UPDATE ON studio_marketing_objectives
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Activer RLS
ALTER TABLE studio_marketing_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_facebook_prepared_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_marketing_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_marketing_objectives ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_performance_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_analysis_cycles ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view marketing recommendations" ON studio_marketing_recommendations
    FOR SELECT USING (true);

CREATE POLICY "Users can insert marketing recommendations" ON studio_marketing_recommendations
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update marketing recommendations" ON studio_marketing_recommendations
    FOR UPDATE USING (true);

CREATE POLICY "Users can view prepared posts" ON studio_facebook_prepared_posts
    FOR SELECT USING (true);

CREATE POLICY "Users can manage prepared posts" ON studio_facebook_prepared_posts
    FOR ALL USING (true);

CREATE POLICY "Users can view marketing alerts" ON studio_marketing_alerts
    FOR SELECT USING (true);

CREATE POLICY "Users can manage marketing alerts" ON studio_marketing_alerts
    FOR ALL USING (true);

CREATE POLICY "Users can view marketing objectives" ON studio_marketing_objectives
    FOR SELECT USING (true);

CREATE POLICY "Users can manage marketing objectives" ON studio_marketing_objectives
    FOR ALL USING (true);

CREATE POLICY "Users can view performance patterns" ON studio_performance_patterns
    FOR SELECT USING (true);

CREATE POLICY "Users can manage performance patterns" ON studio_performance_patterns
    FOR ALL USING (true);

CREATE POLICY "Users can view analysis cycles" ON studio_analysis_cycles
    FOR SELECT USING (true);

CREATE POLICY "Users can insert analysis cycles" ON studio_analysis_cycles
    FOR INSERT WITH CHECK (true);

-- Donner les permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_marketing_recommendations TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_facebook_prepared_posts TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_marketing_alerts TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_marketing_objectives TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_performance_patterns TO authenticated, anon;
GRANT SELECT, INSERT ON studio_analysis_cycles TO authenticated, anon;
