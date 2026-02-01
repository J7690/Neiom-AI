-- Extension des tables pour Phase 5 : Intelligence Prédictive Avancée
-- Tables pour machine learning avancé, prédictions multi-modèles, intelligence temporelle

-- Table pour les modèles de machine learning avancés
CREATE TABLE IF NOT EXISTS studio_ml_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    model_type TEXT NOT NULL CHECK (model_type IN ('neural_network', 'random_forest', 'gradient_boosting', 'svm', 'ensemble', 'deep_learning')),
    model_version TEXT DEFAULT '1.0',
    model_algorithm TEXT NOT NULL,
    model_parameters JSONB DEFAULT '{}'::jsonb,
    training_data_size INTEGER DEFAULT 0,
    validation_data_size INTEGER DEFAULT 0,
    training_accuracy NUMERIC CHECK (training_accuracy >= 0 AND training_accuracy <= 1),
    validation_accuracy NUMERIC CHECK (validation_accuracy >= 0 AND validation_accuracy <= 1),
    test_accuracy NUMERIC CHECK (test_accuracy >= 0 AND test_accuracy <= 1),
    cross_validation_score NUMERIC CHECK (cross_validation_score >= 0 AND cross_validation_score <= 1),
    feature_importance JSONB DEFAULT '{}'::jsonb,
    model_metadata JSONB DEFAULT '{}'::jsonb,
    training_history JSONB DEFAULT '[]'::jsonb,
    model_status TEXT DEFAULT 'training' CHECK (model_status IN ('training', 'ready', 'deployed', 'deprecated', 'failed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    last_trained_at TIMESTAMPTZ,
    deployed_at TIMESTAMPTZ
);

-- Table pour les prédictions multi-modèles
CREATE TABLE IF NOT EXISTS studio_multi_model_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prediction_id TEXT UNIQUE NOT NULL,
    prediction_type TEXT NOT NULL CHECK (prediction_type IN ('engagement', 'reach', 'conversion', 'viral_coefficient', 'optimal_timing', 'content_performance', 'audience_behavior')),
    prediction_horizon TEXT DEFAULT '7_days',
    ensemble_method TEXT DEFAULT 'weighted_average' CHECK (ensemble_method IN ('weighted_average', 'majority_vote', 'stacking', 'blending')),
    participating_models TEXT[] DEFAULT '{}',
    model_predictions JSONB DEFAULT '{}'::jsonb,
    model_weights JSONB DEFAULT '{}'::jsonb,
    ensemble_prediction NUMERIC NOT NULL,
    confidence_interval_lower NUMERIC,
    confidence_interval_upper NUMERIC,
    prediction_confidence NUMERIC CHECK (prediction_confidence >= 0 AND prediction_confidence <= 1),
    prediction_accuracy NUMERIC CHECK (prediction_accuracy >= 0 AND prediction_accuracy <= 1),
    actual_value NUMERIC,
    accuracy_calculated_at TIMESTAMPTZ,
    prediction_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '7 days')
);

-- Table pour les prédictions temps réel
CREATE TABLE IF NOT EXISTS studio_real_time_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prediction_id TEXT UNIQUE NOT NULL,
    prediction_type TEXT NOT NULL,
    prediction_source TEXT NOT NULL CHECK (prediction_source IN ('stream', 'batch', 'api', 'webhook')),
    input_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    prediction_result NUMERIC NOT NULL,
    prediction_confidence NUMERIC CHECK (prediction_confidence >= 0 AND prediction_confidence <= 1),
    processing_time_ms INTEGER DEFAULT 0,
    model_used TEXT NOT NULL,
    prediction_context JSONB DEFAULT '{}'::jsonb,
    prediction_status TEXT DEFAULT 'processing' CHECK (prediction_status IN ('processing', 'completed', 'failed', 'timeout')),
    created_at TIMESTAMPTZ DEFAULT now(),
    processed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '1 hour')
);

-- Table pour l'optimisation prédictive
CREATE TABLE IF NOT EXISTS studio_predictive_optimization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    optimization_id TEXT UNIQUE NOT NULL,
    optimization_type TEXT NOT NULL CHECK (optimization_type IN ('content', 'timing', 'budget', 'audience', 'channel')),
    optimization_goal TEXT NOT NULL CHECK (optimization_goal IN ('maximize_engagement', 'maximize_reach', 'maximize_conversions', 'minimize_cost', 'maximize_roi')),
    prediction_based BOOLEAN DEFAULT true,
    optimization_model TEXT NOT NULL,
    current_performance NUMERIC DEFAULT 0,
    predicted_performance NUMERIC DEFAULT 0,
    optimization_actions JSONB DEFAULT '[]'::jsonb,
    expected_improvement NUMERIC DEFAULT 0,
    confidence_level NUMERIC CHECK (confidence_level >= 0 AND confidence_level <= 1),
    optimization_status TEXT DEFAULT 'pending' CHECK (optimization_status IN ('pending', 'in_progress', 'completed', 'failed')),
    actual_improvement NUMERIC DEFAULT 0,
    roi_estimate NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days')
);

-- Table pour l'intelligence temporelle avancée
CREATE TABLE IF NOT EXISTS studio_temporal_intelligence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    temporal_analysis_id TEXT UNIQUE NOT NULL,
    analysis_type TEXT NOT NULL CHECK (analysis_type IN ('trend', 'seasonality', 'anomaly', 'forecast', 'pattern', 'correlation')),
    time_granularity TEXT DEFAULT 'daily' CHECK (time_granularity IN ('hourly', 'daily', 'weekly', 'monthly')),
    time_series_data JSONB DEFAULT '[]'::jsonb,
    temporal_patterns JSONB DEFAULT '{}'::jsonb,
    seasonality_patterns JSONB DEFAULT '{}'::jsonb,
    anomaly_detection JSONB DEFAULT '{}'::jsonb,
    trend_analysis JSONB DEFAULT '{}'::jsonb,
    forecast_horizon INTEGER DEFAULT 7,
    forecast_values JSONB DEFAULT '[]'::jsonb,
    confidence_intervals JSONB DEFAULT '[]'::jsonb,
    temporal_confidence NUMERIC CHECK (temporal_confidence >= 0 AND temporal_confidence <= 1),
    analysis_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '14 days')
);

-- Table pour les features de machine learning
CREATE TABLE IF NOT EXISTS studio_ml_features (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_name TEXT NOT NULL,
    feature_type TEXT NOT NULL CHECK (feature_type IN ('numerical', 'categorical', 'text', 'image', 'time_series', 'derived')),
    feature_category TEXT NOT NULL CHECK (feature_category IN ('content', 'audience', 'timing', 'historical', 'external', 'behavioral')),
    feature_description TEXT,
    data_type TEXT NOT NULL,
    feature_importance NUMERIC CHECK (feature_importance >= 0 AND feature_importance <= 1),
    feature_correlation JSONB DEFAULT '{}'::jsonb,
    feature_statistics JSONB DEFAULT '{}'::jsonb,
    feature_engineering JSONB DEFAULT '{}'::jsonb,
    feature_status TEXT DEFAULT 'active' CHECK (feature_status IN ('active', 'inactive', 'deprecated', 'experimental')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les datasets d'entraînement
CREATE TABLE IF NOT EXISTS studio_training_datasets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dataset_name TEXT NOT NULL,
    dataset_type TEXT NOT NULL CHECK (dataset_type IN ('training', 'validation', 'test', 'production')),
    dataset_source TEXT NOT NULL,
    data_size INTEGER DEFAULT 0,
    feature_count INTEGER DEFAULT 0,
    target_variable TEXT NOT NULL,
    data_quality_score NUMERIC CHECK (data_quality_score >= 0 AND data_quality_score <= 1),
    missing_data_percentage NUMERIC DEFAULT 0,
    outlier_percentage NUMERIC DEFAULT 0,
    data_distribution JSONB DEFAULT '{}'::jsonb,
    preprocessing_steps JSONB DEFAULT '[]'::jsonb,
    dataset_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '90 days')
);

-- Table pour les métriques de performance prédictive
CREATE TABLE IF NOT EXISTS studio_predictive_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_type TEXT NOT NULL CHECK (metric_type IN ('accuracy', 'precision', 'recall', 'f1_score', 'auc_roc', 'mse', 'rmse', 'mae', 'r2_score')),
    model_id TEXT NOT NULL,
    metric_value NUMERIC NOT NULL,
    metric_category TEXT NOT NULL CHECK (metric_category IN ('training', 'validation', 'test', 'production')),
    calculation_method TEXT DEFAULT 'standard',
    metric_metadata JSONB DEFAULT '{}'::jsonb,
    benchmark_value NUMERIC DEFAULT 0,
    improvement_percentage NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days')
);

-- Table pour les alertes prédictives
CREATE TABLE IF NOT EXISTS studio_predictive_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id TEXT UNIQUE NOT NULL,
    alert_type TEXT NOT NULL CHECK (alert_type IN ('model_degradation', 'prediction_anomaly', 'performance_drop', 'data_drift', 'concept_drift', 'accuracy_decline')),
    alert_severity TEXT DEFAULT 'medium' CHECK (alert_severity IN ('low', 'medium', 'high', 'critical')),
    alert_title TEXT NOT NULL,
    alert_description TEXT NOT NULL,
    alert_recommendation TEXT,
    affected_model TEXT NOT NULL,
    current_metric_value NUMERIC,
    threshold_value NUMERIC,
    deviation_percentage NUMERIC DEFAULT 0,
    alert_context JSONB DEFAULT '{}'::jsonb,
    alert_status TEXT DEFAULT 'active' CHECK (alert_status IN ('active', 'acknowledged', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ
);

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS studio_ml_models_status_idx ON studio_ml_models(model_status);
CREATE INDEX IF NOT EXISTS studio_ml_models_type_idx ON studio_ml_models(model_type);
CREATE INDEX IF NOT EXISTS studio_ml_models_accuracy_idx ON studio_ml_models(validation_accuracy DESC);
CREATE INDEX IF NOT EXISTS studio_multi_model_predictions_type_idx ON studio_multi_model_predictions(prediction_type);
CREATE INDEX IF NOT EXISTS studio_multi_model_predictions_confidence_idx ON studio_multi_model_predictions(prediction_confidence DESC);
CREATE INDEX IF NOT EXISTS studio_real_time_predictions_status_idx ON studio_real_time_predictions(prediction_status);
CREATE INDEX IF NOT EXISTS studio_real_time_predictions_created_idx ON studio_real_time_predictions(created_at DESC);
CREATE INDEX IF NOT EXISTS studio_predictive_optimization_type_idx ON studio_predictive_optimization(optimization_type);
CREATE INDEX IF NOT EXISTS studio_predictive_optimization_status_idx ON studio_predictive_optimization(optimization_status);
CREATE INDEX IF NOT EXISTS studio_temporal_intelligence_type_idx ON studio_temporal_intelligence(analysis_type);
CREATE INDEX IF NOT EXISTS studio_temporal_intelligence_confidence_idx ON studio_temporal_intelligence(temporal_confidence DESC);
CREATE INDEX IF NOT EXISTS studio_ml_features_type_idx ON studio_ml_features(feature_type);
CREATE INDEX IF NOT EXISTS studio_ml_features_importance_idx ON studio_ml_features(feature_importance DESC);
CREATE INDEX IF NOT EXISTS studio_training_datasets_type_idx ON studio_training_datasets(dataset_type);
CREATE INDEX IF NOT EXISTS studio_predictive_metrics_type_idx ON studio_predictive_metrics(metric_type);
CREATE INDEX IF NOT EXISTS studio_predictive_alerts_status_idx ON studio_predictive_alerts(alert_status);
CREATE INDEX IF NOT EXISTS studio_predictive_alerts_severity_idx ON studio_predictive_alerts(alert_severity DESC);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer les triggers
DROP TRIGGER IF EXISTS set_studio_ml_models_updated_at ON studio_ml_models;
CREATE TRIGGER set_studio_ml_models_updated_at
    BEFORE UPDATE ON studio_ml_models
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_predictive_optimization_updated_at ON studio_predictive_optimization;
CREATE TRIGGER set_studio_predictive_optimization_updated_at
    BEFORE UPDATE ON studio_predictive_optimization
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_temporal_intelligence_updated_at ON studio_temporal_intelligence;
CREATE TRIGGER set_studio_temporal_intelligence_updated_at
    BEFORE UPDATE ON studio_temporal_intelligence
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_ml_features_updated_at ON studio_ml_features;
CREATE TRIGGER set_studio_ml_features_updated_at
    BEFORE UPDATE ON studio_ml_features
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_training_datasets_updated_at ON studio_training_datasets;
CREATE TRIGGER set_studio_training_datasets_updated_at
    BEFORE UPDATE ON studio_training_datasets
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Activer RLS
ALTER TABLE studio_ml_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_multi_model_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_real_time_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_predictive_optimization ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_temporal_intelligence ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_ml_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_training_datasets ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_predictive_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_predictive_alerts ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view ML models" ON studio_ml_models
    FOR SELECT USING (true);

CREATE POLICY "Users can manage ML models" ON studio_ml_models
    FOR ALL USING (true);

CREATE POLICY "Users can view multi-model predictions" ON studio_multi_model_predictions
    FOR SELECT USING (true);

CREATE POLICY "Users can manage multi-model predictions" ON studio_multi_model_predictions
    FOR ALL USING (true);

CREATE POLICY "Users can view real-time predictions" ON studio_real_time_predictions
    FOR SELECT USING (true);

CREATE POLICY "Users can manage real-time predictions" ON studio_real_time_predictions
    FOR ALL USING (true);

CREATE POLICY "Users can view predictive optimization" ON studio_predictive_optimization
    FOR SELECT USING (true);

CREATE POLICY "Users can manage predictive optimization" ON studio_predictive_optimization
    FOR ALL USING (true);

CREATE POLICY "Users can view temporal intelligence" ON studio_temporal_intelligence
    FOR SELECT USING (true);

CREATE POLICY "Users can manage temporal intelligence" ON studio_temporal_intelligence
    FOR ALL USING (true);

CREATE POLICY "Users can view ML features" ON studio_ml_features
    FOR SELECT USING (true);

CREATE POLICY "Users can manage ML features" ON studio_ml_features
    FOR ALL USING (true);

CREATE POLICY "Users can view training datasets" ON studio_training_datasets
    FOR SELECT USING (true);

CREATE POLICY "Users can manage training datasets" ON studio_training_datasets
    FOR ALL USING (true);

CREATE POLICY "Users can view predictive metrics" ON studio_predictive_metrics
    FOR SELECT USING (true);

CREATE POLICY "Users can manage predictive metrics" ON studio_predictive_metrics
    FOR ALL USING (true);

CREATE POLICY "Users can view predictive alerts" ON studio_predictive_alerts
    FOR SELECT USING (true);

CREATE POLICY "Users can manage predictive alerts" ON studio_predictive_alerts
    FOR ALL USING (true);

-- Donner les permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_ml_models TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_multi_model_predictions TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_real_time_predictions TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_predictive_optimization TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_temporal_intelligence TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_ml_features TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_training_datasets TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_predictive_metrics TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_predictive_alerts TO authenticated, anon;
