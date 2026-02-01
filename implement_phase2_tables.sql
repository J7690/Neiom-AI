-- Extension des tables pour Phase 2 : Intelligence Avancée
-- Tables pour A/B testing, prédictions, alertes proactives

-- Table pour les A/B tests automatiques
CREATE TABLE IF NOT EXISTS studio_ab_tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    test_name TEXT NOT NULL,
    test_type TEXT NOT NULL CHECK (test_type IN ('format', 'timing', 'content', 'cta')),
    variant_a JSONB NOT NULL DEFAULT '{}'::jsonb,
    variant_b JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused')),
    start_date TIMESTAMPTZ DEFAULT now(),
    end_date TIMESTAMPTZ,
    sample_size_a INTEGER DEFAULT 0,
    sample_size_b INTEGER DEFAULT 0,
    conversion_rate_a NUMERIC DEFAULT 0,
    conversion_rate_b NUMERIC DEFAULT 0,
    confidence_level NUMERIC DEFAULT 0.95,
    winner TEXT CHECK (winner IN ('variant_a', 'variant_b', 'inconclusive')),
    statistical_significance BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les prédictions de performance
CREATE TABLE IF NOT EXISTS studio_performance_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prediction_type TEXT NOT NULL CHECK (prediction_type IN ('engagement', 'reach', 'conversion', 'timing')),
    prediction_model TEXT NOT NULL DEFAULT 'linear_regression',
    input_features JSONB NOT NULL DEFAULT '{}'::jsonb,
    predicted_value NUMERIC NOT NULL,
    confidence_interval_lower NUMERIC,
    confidence_interval_upper NUMERIC,
    prediction_date TIMESTAMPTZ NOT NULL,
    actual_value NUMERIC,
    accuracy_score NUMERIC,
    model_version TEXT DEFAULT '1.0',
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '7 days')
);

-- Table pour les alertes proactives intelligentes
CREATE TABLE IF NOT EXISTS studio_proactive_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type TEXT NOT NULL,
    alert_category TEXT NOT NULL CHECK (alert_category IN ('opportunity', 'risk', 'optimization', 'trend')),
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    recommendation TEXT,
    action_required BOOLEAN DEFAULT false,
    auto_executable BOOLEAN DEFAULT false,
    trigger_conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
    context_data JSONB DEFAULT '{}'::jsonb,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'dismissed', 'executed')),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    executed_at TIMESTAMPTZ
);

-- Table pour le learning continu et optimisation
CREATE TABLE IF NOT EXISTS studio_learning_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insight_type TEXT NOT NULL CHECK (insight_type IN ('pattern', 'correlation', 'anomaly', 'trend')),
    insight_title TEXT NOT NULL,
    insight_description TEXT NOT NULL,
    confidence_score NUMERIC CHECK (confidence_score >= 0 AND confidence_score <= 1),
    impact_score NUMERIC CHECK (impact_score >= 0 AND impact_score <= 1),
    data_source TEXT NOT NULL,
    time_period TEXT,
    actionable_recommendation TEXT,
    implemented BOOLEAN DEFAULT false,
    implementation_result JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les cohortes de contenu
CREATE TABLE IF NOT EXISTS studio_content_cohorts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cohort_name TEXT NOT NULL,
    cohort_type TEXT NOT NULL CHECK (cohort_type IN ('time_based', 'topic_based', 'audience_based', 'format_based')),
    criteria JSONB NOT NULL DEFAULT '{}'::jsonb,
    content_ids TEXT[] DEFAULT '{}',
    performance_metrics JSONB DEFAULT '{}'::jsonb,
    benchmark_metrics JSONB DEFAULT '{}'::jsonb,
    size INTEGER DEFAULT 0,
    avg_engagement_rate NUMERIC DEFAULT 0,
    avg_conversion_rate NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les scores de qualité de contenu
CREATE TABLE IF NOT EXISTS studio_content_quality_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id TEXT NOT NULL,
    content_type TEXT NOT NULL,
    quality_score NUMERIC CHECK (quality_score >= 0 AND quality_score <= 100),
    readability_score NUMERIC CHECK (readability_score >= 0 AND readability_score <= 100),
    engagement_prediction NUMERIC CHECK (engagement_prediction >= 0 AND engagement_prediction <= 100),
    conversion_prediction NUMERIC CHECK (conversion_prediction >= 0 AND conversion_prediction <= 100),
    optimization_suggestions TEXT[],
    scoring_factors JSONB DEFAULT '{}'::jsonb,
    last_scored_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS studio_ab_tests_status_idx ON studio_ab_tests(status);
CREATE INDEX IF NOT EXISTS studio_ab_tests_type_idx ON studio_ab_tests(test_type);
CREATE INDEX IF NOT EXISTS studio_ab_tests_dates_idx ON studio_ab_tests(start_date, end_date);

CREATE INDEX IF NOT EXISTS studio_performance_predictions_type_idx ON studio_performance_predictions(prediction_type);
CREATE INDEX IF NOT EXISTS studio_performance_predictions_date_idx ON studio_performance_predictions(prediction_date);
CREATE INDEX IF NOT EXISTS studio_performance_predictions_expires_idx ON studio_performance_predictions(expires_at);

CREATE INDEX IF NOT EXISTS studio_proactive_alerts_status_idx ON studio_proactive_alerts(status);
CREATE INDEX IF NOT EXISTS studio_proactive_alerts_category_idx ON studio_proactive_alerts(alert_category);
CREATE INDEX IF NOT EXISTS studio_proactive_alerts_severity_idx ON studio_proactive_alerts(severity);
CREATE INDEX IF NOT EXISTS studio_proactive_alerts_created_idx ON studio_proactive_alerts(created_at DESC);

CREATE INDEX IF NOT EXISTS studio_learning_insights_type_idx ON studio_learning_insights(insight_type);
CREATE INDEX IF NOT EXISTS studio_learning_insights_confidence_idx ON studio_learning_insights(confidence_score DESC);
CREATE INDEX IF NOT EXISTS studio_learning_insights_impact_idx ON studio_learning_insights(impact_score DESC);

CREATE INDEX IF NOT EXISTS studio_content_cohorts_type_idx ON studio_content_cohorts(cohort_type);
CREATE INDEX IF NOT EXISTS studio_content_cohorts_performance_idx ON studio_content_cohorts(avg_engagement_rate DESC);

CREATE INDEX IF NOT EXISTS studio_content_quality_scores_content_idx ON studio_content_quality_scores(content_id);
CREATE INDEX IF NOT EXISTS studio_content_quality_scores_quality_idx ON studio_content_quality_scores(quality_score DESC);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer les triggers
DROP TRIGGER IF EXISTS set_studio_ab_tests_updated_at ON studio_ab_tests;
CREATE TRIGGER set_studio_ab_tests_updated_at
    BEFORE UPDATE ON studio_ab_tests
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_learning_insights_updated_at ON studio_learning_insights;
CREATE TRIGGER set_studio_learning_insights_updated_at
    BEFORE UPDATE ON studio_learning_insights
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_content_cohorts_updated_at ON studio_content_cohorts;
CREATE TRIGGER set_studio_content_cohorts_updated_at
    BEFORE UPDATE ON studio_content_cohorts
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Activer RLS
ALTER TABLE studio_ab_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_performance_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_proactive_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_learning_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_content_cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_content_quality_scores ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view AB tests" ON studio_ab_tests
    FOR SELECT USING (true);

CREATE POLICY "Users can manage AB tests" ON studio_ab_tests
    FOR ALL USING (true);

CREATE POLICY "Users can view performance predictions" ON studio_performance_predictions
    FOR SELECT USING (true);

CREATE POLICY "Users can manage performance predictions" ON studio_performance_predictions
    FOR ALL USING (true);

CREATE POLICY "Users can view proactive alerts" ON studio_proactive_alerts
    FOR SELECT USING (true);

CREATE POLICY "Users can manage proactive alerts" ON studio_proactive_alerts
    FOR ALL USING (true);

CREATE POLICY "Users can view learning insights" ON studio_learning_insights
    FOR SELECT USING (true);

CREATE POLICY "Users can manage learning insights" ON studio_learning_insights
    FOR ALL USING (true);

CREATE POLICY "Users can view content cohorts" ON studio_content_cohorts
    FOR SELECT USING (true);

CREATE POLICY "Users can manage content cohorts" ON studio_content_cohorts
    FOR ALL USING (true);

CREATE POLICY "Users can view content quality scores" ON studio_content_quality_scores
    FOR SELECT USING (true);

CREATE POLICY "Users can manage content quality scores" ON studio_content_quality_scores
    FOR ALL USING (true);

-- Donner les permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_ab_tests TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_performance_predictions TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_proactive_alerts TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_learning_insights TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_content_cohorts TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_content_quality_scores TO authenticated, anon;
