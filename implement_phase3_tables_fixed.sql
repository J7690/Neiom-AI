-- Extension des tables pour Phase 3 : Excellence Opérationnelle (version corrigée)
-- Tables pour optimisation automatique, ROI tracking, intelligence collective

-- Table pour l'optimisation automatique des campagnes
CREATE TABLE IF NOT EXISTS studio_campaign_optimization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_name TEXT NOT NULL,
    optimization_type TEXT NOT NULL CHECK (optimization_type IN ('timing', 'content', 'budget', 'targeting')),
    current_performance JSONB DEFAULT '{}'::jsonb,
    optimization_rules JSONB DEFAULT '{}'::jsonb,
    auto_optimization_enabled BOOLEAN DEFAULT true,
    optimization_frequency TEXT DEFAULT 'daily',
    last_optimization_at TIMESTAMPTZ,
    next_optimization_at TIMESTAMPTZ,
    optimization_history JSONB DEFAULT '[]'::jsonb,
    performance_improvement NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour le tracking ROI des campagnes
CREATE TABLE IF NOT EXISTS studio_roi_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id TEXT,
    campaign_name TEXT NOT NULL,
    investment_amount NUMERIC NOT NULL,
    investment_currency TEXT DEFAULT 'XOF',
    investment_date TIMESTAMPTZ NOT NULL,
    returns_amount NUMERIC DEFAULT 0,
    returns_currency TEXT DEFAULT 'XOF',
    returns_date TIMESTAMPTZ,
    roi_percentage NUMERIC DEFAULT 0,
    roi_category TEXT CHECK (roi_category IN ('positive', 'neutral', 'negative')),
    attribution_model TEXT DEFAULT 'last_click',
    conversion_value NUMERIC DEFAULT 0,
    conversion_count INTEGER DEFAULT 0,
    cost_per_conversion NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour l'intelligence collective des agents IA
CREATE TABLE IF NOT EXISTS studio_collective_intelligence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    intelligence_type TEXT NOT NULL CHECK (intelligence_type IN ('pattern', 'recommendation', 'prediction', 'optimization')),
    source_agent TEXT NOT NULL CHECK (source_agent IN ('marketing', 'support', 'analytics', 'content')),
    intelligence_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    confidence_score NUMERIC CHECK (confidence_score >= 0 AND confidence_score <= 1),
    impact_score NUMERIC CHECK (impact_score >= 0 AND impact_score <= 1),
    shared_with_agents TEXT[] DEFAULT '{}',
    applied_by_agents TEXT[] DEFAULT '{}',
    validation_status TEXT DEFAULT 'pending',
    validation_results JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days')
);

-- Table pour le budget optimisation automatique
CREATE TABLE IF NOT EXISTS studio_budget_optimization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id TEXT,
    total_budget NUMERIC NOT NULL,
    allocated_budget NUMERIC NOT NULL,
    spent_budget NUMERIC DEFAULT 0,
    remaining_budget NUMERIC DEFAULT 0,
    budget_currency TEXT DEFAULT 'XOF',
    optimization_strategy TEXT DEFAULT 'performance_based',
    channel_allocations JSONB DEFAULT '{}'::jsonb,
    performance_metrics JSONB DEFAULT '{}'::jsonb,
    auto_reallocation_enabled BOOLEAN DEFAULT true,
    reallocation_threshold NUMERIC DEFAULT 0.1,
    last_reallocation_at TIMESTAMPTZ,
    next_reallocation_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les prédictions avancées de performance
CREATE TABLE IF NOT EXISTS studio_advanced_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prediction_model TEXT NOT NULL DEFAULT 'ensemble',
    prediction_type TEXT NOT NULL CHECK (prediction_type IN ('engagement', 'reach', 'conversion', 'viral_coefficient', 'optimal_timing')),
    prediction_horizon TEXT DEFAULT '7_days',
    input_features JSONB NOT NULL DEFAULT '{}'::jsonb,
    model_parameters JSONB DEFAULT '{}'::jsonb,
    predicted_value NUMERIC NOT NULL,
    confidence_interval_lower NUMERIC,
    confidence_interval_upper NUMERIC,
    prediction_accuracy NUMERIC DEFAULT 0,
    actual_value NUMERIC,
    accuracy_calculated_at TIMESTAMPTZ,
    model_version TEXT DEFAULT '1.0',
    training_data_size INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '7 days')
);

-- Table pour les cohortes de performance avancées
CREATE TABLE IF NOT EXISTS studio_performance_cohorts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cohort_name TEXT NOT NULL,
    cohort_type TEXT NOT NULL CHECK (cohort_type IN ('time_based', 'content_based', 'audience_based', 'channel_based')),
    cohort_definition JSONB NOT NULL DEFAULT '{}'::jsonb,
    member_ids TEXT[] DEFAULT '{}',
    baseline_metrics JSONB DEFAULT '{}'::jsonb,
    current_metrics JSONB DEFAULT '{}'::jsonb,
    performance_delta NUMERIC DEFAULT 0,
    cohort_size INTEGER DEFAULT 0,
    retention_rate NUMERIC DEFAULT 0,
    engagement_rate NUMERIC DEFAULT 0,
    conversion_rate NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les scores de qualité avancés
CREATE TABLE IF NOT EXISTS studio_advanced_quality_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id TEXT NOT NULL,
    content_type TEXT NOT NULL,
    overall_score NUMERIC CHECK (overall_score >= 0 AND overall_score <= 100),
    readability_score NUMERIC CHECK (readability_score >= 0 AND readability_score <= 100),
    engagement_prediction NUMERIC CHECK (engagement_prediction >= 0 AND engagement_prediction <= 100),
    conversion_prediction NUMERIC CHECK (conversion_prediction >= 0 AND conversion_prediction <= 100),
    viral_potential NUMERIC CHECK (viral_potential >= 0 AND viral_potential <= 100),
    brand_alignment NUMERIC CHECK (brand_alignment >= 0 AND brand_alignment <= 100),
    seo_optimization NUMERIC CHECK (seo_optimization >= 0 AND seo_optimization <= 100),
    scoring_factors JSONB DEFAULT '{}'::jsonb,
    improvement_suggestions TEXT[] DEFAULT '{}',
    benchmark_comparison JSONB DEFAULT '{}'::jsonb,
    last_scored_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les alertes d'optimisation proactive
CREATE TABLE IF NOT EXISTS studio_optimization_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type TEXT NOT NULL,
    alert_category TEXT NOT NULL CHECK (alert_category IN ('optimization', 'opportunity', 'risk', 'trend')),
    severity TEXT DEFAULT 'medium',
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    recommendation TEXT,
    auto_executable BOOLEAN DEFAULT false,
    execution_result JSONB DEFAULT '{}'::jsonb,
    impact_potential NUMERIC CHECK (impact_potential >= 0 AND impact_potential <= 100),
    implementation_cost NUMERIC DEFAULT 0,
    roi_estimate NUMERIC DEFAULT 0,
    trigger_conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
    context_data JSONB DEFAULT '{}'::jsonb,
    status TEXT DEFAULT 'active',
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    executed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS studio_campaign_optimization_status_idx ON studio_campaign_optimization(auto_optimization_enabled);
CREATE INDEX IF NOT EXISTS studio_roi_tracking_campaign_idx ON studio_roi_tracking(campaign_id);
CREATE INDEX IF NOT EXISTS studio_collective_intelligence_type_idx ON studio_collective_intelligence(intelligence_type);
CREATE INDEX IF NOT EXISTS studio_budget_optimization_campaign_idx ON studio_budget_optimization(campaign_id);
CREATE INDEX IF NOT EXISTS studio_advanced_predictions_type_idx ON studio_advanced_predictions(prediction_type);
CREATE INDEX IF NOT EXISTS studio_performance_cohorts_type_idx ON studio_performance_cohorts(cohort_type);
CREATE INDEX IF NOT EXISTS studio_advanced_quality_scores_overall_idx ON studio_advanced_quality_scores(overall_score DESC);
CREATE INDEX IF NOT EXISTS studio_optimization_alerts_status_idx ON studio_optimization_alerts(status);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer les triggers
DROP TRIGGER IF EXISTS set_studio_campaign_optimization_updated_at ON studio_campaign_optimization;
CREATE TRIGGER set_studio_campaign_optimization_updated_at
    BEFORE UPDATE ON studio_campaign_optimization
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_roi_tracking_updated_at ON studio_roi_tracking;
CREATE TRIGGER set_studio_roi_tracking_updated_at
    BEFORE UPDATE ON studio_roi_tracking
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_budget_optimization_updated_at ON studio_budget_optimization;
CREATE TRIGGER set_studio_budget_optimization_updated_at
    BEFORE UPDATE ON studio_budget_optimization
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_performance_cohorts_updated_at ON studio_performance_cohorts;
CREATE TRIGGER set_studio_performance_cohorts_updated_at
    BEFORE UPDATE ON studio_performance_cohorts
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_advanced_quality_scores_updated_at ON studio_advanced_quality_scores;
CREATE TRIGGER set_studio_advanced_quality_scores_updated_at
    BEFORE UPDATE ON studio_advanced_quality_scores
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Activer RLS
ALTER TABLE studio_campaign_optimization ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_roi_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_collective_intelligence ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_budget_optimization ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_advanced_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_performance_cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_advanced_quality_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_optimization_alerts ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view campaign optimization" ON studio_campaign_optimization
    FOR SELECT USING (true);

CREATE POLICY "Users can manage campaign optimization" ON studio_campaign_optimization
    FOR ALL USING (true);

CREATE POLICY "Users can view ROI tracking" ON studio_roi_tracking
    FOR SELECT USING (true);

CREATE POLICY "Users can manage ROI tracking" ON studio_roi_tracking
    FOR ALL USING (true);

CREATE POLICY "Users can view collective intelligence" ON studio_collective_intelligence
    FOR SELECT USING (true);

CREATE POLICY "Users can manage collective intelligence" ON studio_collective_intelligence
    FOR ALL USING (true);

CREATE POLICY "Users can view budget optimization" ON studio_budget_optimization
    FOR SELECT USING (true);

CREATE POLICY "Users can manage budget optimization" ON studio_budget_optimization
    FOR ALL USING (true);

CREATE POLICY "Users can view advanced predictions" ON studio_advanced_predictions
    FOR SELECT USING (true);

CREATE POLICY "Users can manage advanced predictions" ON studio_advanced_predictions
    FOR ALL USING (true);

CREATE POLICY "Users can view performance cohorts" ON studio_performance_cohorts
    FOR SELECT USING (true);

CREATE POLICY "Users can manage performance cohorts" ON studio_performance_cohorts
    FOR ALL USING (true);

CREATE POLICY "Users can view advanced quality scores" ON studio_advanced_quality_scores
    FOR SELECT USING (true);

CREATE POLICY "Users can manage advanced quality scores" ON studio_advanced_quality_scores
    FOR ALL USING (true);

CREATE POLICY "Users can view optimization alerts" ON studio_optimization_alerts
    FOR SELECT USING (true);

CREATE POLICY "Users can manage optimization alerts" ON studio_optimization_alerts
    FOR ALL USING (true);

-- Donner les permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_campaign_optimization TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_roi_tracking TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_collective_intelligence TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_budget_optimization TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_advanced_predictions TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_performance_cohorts TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_advanced_quality_scores TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_optimization_alerts TO authenticated, anon;
