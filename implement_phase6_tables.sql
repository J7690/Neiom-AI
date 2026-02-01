-- Extension des tables pour Phase 6 : Intelligence Cognitive Avancée
-- Tables pour cognitive computing, NLP, computer vision, speech recognition

-- Table pour les modèles de Natural Language Processing (NLP)
CREATE TABLE IF NOT EXISTS studio_nlp_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    model_type TEXT NOT NULL CHECK (model_type IN ('sentiment_analysis', 'text_classification', 'named_entity_recognition', 'topic_modeling', 'language_detection', 'text_summarization', 'question_answering')),
    model_algorithm TEXT NOT NULL,
    model_version TEXT DEFAULT '1.0',
    training_language TEXT DEFAULT 'fr',
    vocabulary_size INTEGER DEFAULT 0,
    embedding_dimension INTEGER DEFAULT 0,
    model_accuracy NUMERIC CHECK (model_accuracy >= 0 AND model_accuracy <= 1),
    f1_score NUMERIC CHECK (f1_score >= 0 AND f1_score <= 1),
    precision_score NUMERIC CHECK (precision_score >= 0 AND precision_score <= 1),
    recall_score NUMERIC CHECK (recall_score >= 0 AND recall_score <= 1),
    model_parameters JSONB DEFAULT '{}'::jsonb,
    training_data_size INTEGER DEFAULT 0,
    model_metadata JSONB DEFAULT '{}'::jsonb,
    model_status TEXT DEFAULT 'training' CHECK (model_status IN ('training', 'ready', 'deployed', 'deprecated', 'failed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    last_trained_at TIMESTAMPTZ,
    deployed_at TIMESTAMPTZ
);

-- Table pour les analyses de texte et sentiment
CREATE TABLE IF NOT EXISTS studio_text_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id TEXT UNIQUE NOT NULL,
    text_content TEXT NOT NULL,
    text_source TEXT NOT NULL CHECK (text_source IN ('facebook_post', 'facebook_comment', 'twitter', 'instagram', 'manual_input')),
    text_language TEXT DEFAULT 'fr',
    text_length INTEGER DEFAULT 0,
    sentiment_score NUMERIC CHECK (sentiment_score >= -1 AND sentiment_score <= 1),
    sentiment_label TEXT CHECK (sentiment_label IN ('positive', 'negative', 'neutral', 'mixed')),
    sentiment_confidence NUMERIC CHECK (sentiment_confidence >= 0 AND sentiment_confidence <= 1),
    emotion_scores JSONB DEFAULT '{}'::jsonb,
    key_phrases TEXT[] DEFAULT '{}',
    named_entities JSONB DEFAULT '{}'::jsonb,
    topics JSONB DEFAULT '{}'::jsonb,
    text_complexity NUMERIC CHECK (text_complexity >= 0 AND text_complexity <= 1),
    readability_score NUMERIC CHECK (readability_score >= 0 AND readability_score <= 100),
    analysis_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les modèles de Computer Vision
CREATE TABLE IF NOT EXISTS studio_vision_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    model_type TEXT NOT NULL CHECK (model_type IN ('object_detection', 'image_classification', 'face_recognition', 'scene_analysis', 'text_extraction', 'image_segmentation', 'style_transfer')),
    model_algorithm TEXT NOT NULL,
    model_version TEXT DEFAULT '1.0',
    input_resolution JSONB DEFAULT '{"width": 224, "height": 224}'::jsonb,
    model_accuracy NUMERIC CHECK (model_accuracy >= 0 AND model_accuracy <= 1),
    mean_average_precision NUMERIC CHECK (mean_average_precision >= 0 AND mean_average_precision <= 1),
    inference_time_ms INTEGER DEFAULT 0,
    model_size_mb NUMERIC DEFAULT 0,
    supported_formats TEXT[] DEFAULT ARRAY['jpg', 'jpeg', 'png', 'webp'],
    classes_detected TEXT[] DEFAULT '{}',
    model_parameters JSONB DEFAULT '{}'::jsonb,
    training_data_size INTEGER DEFAULT 0,
    model_metadata JSONB DEFAULT '{}'::jsonb,
    model_status TEXT DEFAULT 'training' CHECK (model_status IN ('training', 'ready', 'deployed', 'deprecated', 'failed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    last_trained_at TIMESTAMPTZ,
    deployed_at TIMESTAMPTZ
);

-- Table pour les analyses d'images et vidéos
CREATE TABLE IF NOT EXISTS studio_vision_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id TEXT UNIQUE NOT NULL,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    media_url TEXT NOT NULL,
    media_source TEXT NOT NULL CHECK (media_source IN ('facebook_post', 'instagram', 'twitter', 'manual_upload')),
    analysis_type TEXT NOT NULL CHECK (analysis_type IN ('object_detection', 'scene_analysis', 'face_recognition', 'text_extraction', 'quality_assessment')),
    detected_objects JSONB DEFAULT '[]'::jsonb,
    scene_description TEXT,
    faces_detected JSONB DEFAULT '[]'::jsonb,
    extracted_text TEXT,
    visual_features JSONB DEFAULT '{}'::jsonb,
    quality_metrics JSONB DEFAULT '{}'::jsonb,
    aesthetic_score NUMERIC CHECK (aesthetic_score >= 0 AND aesthetic_score <= 10),
    engagement_prediction NUMERIC CHECK (engagement_prediction >= 0 AND engagement_prediction <= 1),
    analysis_confidence NUMERIC CHECK (analysis_confidence >= 0 AND analysis_confidence <= 1),
    processing_time_ms INTEGER DEFAULT 0,
    analysis_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour les modèles de Speech Recognition
CREATE TABLE IF NOT EXISTS studio_speech_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    model_type TEXT NOT NULL CHECK (model_type IN ('speech_to_text', 'text_to_speech', 'speaker_identification', 'emotion_recognition', 'language_identification')),
    model_algorithm TEXT NOT NULL,
    model_version TEXT DEFAULT '1.0',
    supported_languages TEXT[] DEFAULT ARRAY['fr', 'en', 'es', 'de', 'it'],
    sample_rate INTEGER DEFAULT 16000,
    model_accuracy NUMERIC CHECK (model_accuracy >= 0 AND model_accuracy <= 1),
    word_error_rate NUMERIC CHECK (word_error_rate >= 0 AND word_error_rate <= 1),
    inference_time_ms INTEGER DEFAULT 0,
    model_size_mb NUMERIC DEFAULT 0,
    audio_formats TEXT[] DEFAULT ARRAY['wav', 'mp3', 'flac', 'ogg'],
    vocabulary_size INTEGER DEFAULT 0,
    model_parameters JSONB DEFAULT '{}'::jsonb,
    training_data_hours INTEGER DEFAULT 0,
    model_metadata JSONB DEFAULT '{}'::jsonb,
    model_status TEXT DEFAULT 'training' CHECK (model_status IN ('training', 'ready', 'deployed', 'deprecated', 'failed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    last_trained_at TIMESTAMPTZ,
    deployed_at TIMESTAMPTZ
);

-- Table pour les analyses audio et speech
CREATE TABLE IF NOT EXISTS studio_audio_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id TEXT UNIQUE NOT NULL,
    audio_url TEXT NOT NULL,
    audio_source TEXT NOT NULL CHECK (audio_source IN ('facebook_video', 'instagram_reel', 'twitter_audio', 'manual_upload')),
    audio_duration_ms INTEGER DEFAULT 0,
    audio_format TEXT NOT NULL,
    sample_rate INTEGER DEFAULT 16000,
    analysis_type TEXT NOT NULL CHECK (analysis_type IN ('speech_to_text', 'emotion_recognition', 'speaker_identification', 'audio_classification', 'background_noise')),
    transcribed_text TEXT,
    detected_language TEXT,
    speaker_info JSONB DEFAULT '{}'::jsonb,
    emotion_scores JSONB DEFAULT '{}'::jsonb,
    audio_features JSONB DEFAULT '{}'::jsonb,
    background_noise_level NUMERIC CHECK (background_noise_level >= 0 AND background_noise_level <= 1),
    speech_clarity NUMERIC CHECK (speech_clarity >= 0 AND speech_clarity <= 1),
    transcription_confidence NUMERIC CHECK (transcription_confidence >= 0 AND transcription_confidence <= 1),
    processing_time_ms INTEGER DEFAULT 0,
    analysis_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table pour le raisonnement cognitif avancé
CREATE TABLE IF NOT EXISTS studio_cognitive_reasoning (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reasoning_id TEXT UNIQUE NOT NULL,
    reasoning_type TEXT NOT NULL CHECK (reasoning_type IN ('logical', 'causal', 'analogical', 'deductive', 'inductive', 'abductive')),
    reasoning_context TEXT NOT NULL,
    input_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    reasoning_rules JSONB DEFAULT '{}'::jsonb,
    reasoning_steps JSONB DEFAULT '[]'::jsonb,
    intermediate_conclusions JSONB DEFAULT '{}'::jsonb,
    final_conclusion TEXT,
    confidence_level NUMERIC CHECK (confidence_level >= 0 AND confidence_level <= 1),
    reasoning_confidence NUMERIC CHECK (reasoning_confidence >= 0 AND reasoning_confidence <= 1),
    logical_consistency NUMERIC CHECK (logical_consistency >= 0 AND logical_consistency <= 1),
    evidence_strength NUMERIC CHECK (evidence_strength >= 0 AND evidence_strength <= 1),
    reasoning_metadata JSONB DEFAULT '{}'::jsonb,
    reasoning_status TEXT DEFAULT 'processing' CHECK (reasoning_status IN ('processing', 'completed', 'failed', 'inconclusive')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ
);

-- Table pour les insights cognitifs émergents
CREATE TABLE IF NOT EXISTS studio_cognitive_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insight_id TEXT UNIQUE NOT NULL,
    insight_type TEXT NOT NULL CHECK (insight_type IN ('pattern', 'anomaly', 'correlation', 'causation', 'prediction', 'recommendation')),
    insight_source TEXT NOT NULL CHECK (insight_source IN ('nlp', 'vision', 'speech', 'reasoning', 'multimodal')),
    insight_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    insight_description TEXT NOT NULL,
    insight_confidence NUMERIC CHECK (insight_confidence >= 0 AND insight_confidence <= 1),
    insight_value NUMERIC CHECK (insight_value >= 0 AND insight_value <= 100),
    supporting_evidence JSONB DEFAULT '{}'::jsonb,
    related_insights TEXT[] DEFAULT '{}',
    insight_impact TEXT CHECK (insight_impact IN ('low', 'medium', 'high', 'critical')),
    actionability_score NUMERIC CHECK (actionability_score >= 0 AND actionability_score <= 1),
    insight_metadata JSONB DEFAULT '{}'::jsonb,
    insight_status TEXT DEFAULT 'emerging' CHECK (insight_status IN ('emerging', 'validated', 'implemented', 'dismissed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days')
);

-- Table pour les modèles multimodaux
CREATE TABLE IF NOT EXISTS studio_multimodal_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_name TEXT NOT NULL,
    model_type TEXT NOT NULL CHECK (model_type IN ('vision_language', 'audio_visual', 'text_speech_vision', 'multimodal_reasoning')),
    model_algorithm TEXT NOT NULL,
    model_version TEXT DEFAULT '1.0',
    supported_modalities TEXT[] DEFAULT ARRAY['text', 'image', 'audio', 'video'],
    fusion_strategy TEXT DEFAULT 'late_fusion' CHECK (fusion_strategy IN ('early_fusion', 'late_fusion', 'hybrid_fusion', 'attention_based')),
    model_accuracy NUMERIC CHECK (model_accuracy >= 0 AND model_accuracy <= 1),
    cross_modal_performance JSONB DEFAULT '{}'::jsonb,
    inference_time_ms INTEGER DEFAULT 0,
    model_size_mb NUMERIC DEFAULT 0,
    model_parameters JSONB DEFAULT '{}'::jsonb,
    training_data_size INTEGER DEFAULT 0,
    model_metadata JSONB DEFAULT '{}'::jsonb,
    model_status TEXT DEFAULT 'training' CHECK (model_status IN ('training', 'ready', 'deployed', 'deprecated', 'failed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    last_trained_at TIMESTAMPTZ,
    deployed_at TIMESTAMPTZ
);

-- Table pour les analyses multimodales
CREATE TABLE IF NOT EXISTS studio_multimodal_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id TEXT UNIQUE NOT NULL,
    content_type TEXT NOT NULL CHECK (content_type IN ('post_with_image', 'video_with_audio', 'text_with_speech', 'multimedia_content')),
    text_content TEXT,
    image_url TEXT,
    audio_url TEXT,
    video_url TEXT,
    analysis_types TEXT[] DEFAULT '{}',
    modal_features JSONB DEFAULT '{}'::jsonb,
    cross_modal_insights JSONB DEFAULT '{}'::jsonb,
    unified_understanding TEXT,
    engagement_prediction NUMERIC CHECK (engagement_prediction >= 0 AND engagement_prediction <= 1),
    content_quality_score NUMERIC CHECK (content_quality_score >= 0 AND content_quality_score <= 10),
    multimodal_confidence NUMERIC CHECK (multimodal_confidence >= 0 AND multimodal_confidence <= 1),
    processing_time_ms INTEGER DEFAULT 0,
    analysis_metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS studio_nlp_models_status_idx ON studio_nlp_models(model_status);
CREATE INDEX IF NOT EXISTS studio_nlp_models_type_idx ON studio_nlp_models(model_type);
CREATE INDEX IF NOT EXISTS studio_text_analytics_sentiment_idx ON studio_text_analytics(sentiment_score);
CREATE INDEX IF NOT EXISTS studio_text_analytics_source_idx ON studio_text_analytics(text_source);
CREATE INDEX IF NOT EXISTS studio_vision_models_status_idx ON studio_vision_models(model_status);
CREATE INDEX IF NOT EXISTS studio_vision_models_type_idx ON studio_vision_models(model_type);
CREATE INDEX IF NOT EXISTS studio_vision_analytics_type_idx ON studio_vision_analytics(analysis_type);
CREATE INDEX IF NOT EXISTS studio_vision_analytics_source_idx ON studio_vision_analytics(media_source);
CREATE INDEX IF NOT EXISTS studio_speech_models_status_idx ON studio_speech_models(model_status);
CREATE INDEX IF NOT EXISTS studio_speech_models_type_idx ON studio_speech_models(model_type);
CREATE INDEX IF NOT EXISTS studio_audio_analytics_type_idx ON studio_audio_analytics(analysis_type);
CREATE INDEX IF NOT EXISTS studio_audio_analytics_source_idx ON studio_audio_analytics(audio_source);
CREATE INDEX IF NOT EXISTS studio_cognitive_reasoning_type_idx ON studio_cognitive_reasoning(reasoning_type);
CREATE INDEX IF NOT EXISTS studio_cognitive_reasoning_status_idx ON studio_cognitive_reasoning(reasoning_status);
CREATE INDEX IF NOT EXISTS studio_cognitive_insights_type_idx ON studio_cognitive_insights(insight_type);
CREATE INDEX IF NOT EXISTS studio_cognitive_insights_impact_idx ON studio_cognitive_insights(insight_impact DESC);
CREATE INDEX IF NOT EXISTS studio_multimodal_models_status_idx ON studio_multimodal_models(model_status);
CREATE INDEX IF NOT EXISTS studio_multimodal_analytics_type_idx ON studio_multimodal_analytics(content_type);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer les triggers
DROP TRIGGER IF EXISTS set_studio_nlp_models_updated_at ON studio_nlp_models;
CREATE TRIGGER set_studio_nlp_models_updated_at
    BEFORE UPDATE ON studio_nlp_models
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_text_analytics_updated_at ON studio_text_analytics;
CREATE TRIGGER set_studio_text_analytics_updated_at
    BEFORE UPDATE ON studio_text_analytics
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_vision_models_updated_at ON studio_vision_models;
CREATE TRIGGER set_studio_vision_models_updated_at
    BEFORE UPDATE ON studio_vision_models
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_vision_analytics_updated_at ON studio_vision_analytics;
CREATE TRIGGER set_studio_vision_analytics_updated_at
    BEFORE UPDATE ON studio_vision_analytics
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_speech_models_updated_at ON studio_speech_models;
CREATE TRIGGER set_studio_speech_models_updated_at
    BEFORE UPDATE ON studio_speech_models
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_audio_analytics_updated_at ON studio_audio_analytics;
CREATE TRIGGER set_studio_audio_analytics_updated_at
    BEFORE UPDATE ON studio_audio_analytics
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_cognitive_reasoning_updated_at ON studio_cognitive_reasoning;
CREATE TRIGGER set_studio_cognitive_reasoning_updated_at
    BEFORE UPDATE ON studio_cognitive_reasoning
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_cognitive_insights_updated_at ON studio_cognitive_insights;
CREATE TRIGGER set_studio_cognitive_insights_updated_at
    BEFORE UPDATE ON studio_cognitive_insights
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_multimodal_models_updated_at ON studio_multimodal_models;
CREATE TRIGGER set_studio_multimodal_models_updated_at
    BEFORE UPDATE ON studio_multimodal_models
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_studio_multimodal_analytics_updated_at ON studio_multimodal_analytics;
CREATE TRIGGER set_studio_multimodal_analytics_updated_at
    BEFORE UPDATE ON studio_multimodal_analytics
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Activer RLS
ALTER TABLE studio_nlp_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_text_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_vision_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_vision_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_speech_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_audio_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_cognitive_reasoning ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_cognitive_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_multimodal_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE studio_multimodal_analytics ENABLE ROW LEVEL SECURITY;

-- Politiques RLS
CREATE POLICY "Users can view NLP models" ON studio_nlp_models
    FOR SELECT USING (true);

CREATE POLICY "Users can manage NLP models" ON studio_nlp_models
    FOR ALL USING (true);

CREATE POLICY "Users can view text analytics" ON studio_text_analytics
    FOR SELECT USING (true);

CREATE POLICY "Users can manage text analytics" ON studio_text_analytics
    FOR ALL USING (true);

CREATE POLICY "Users can view vision models" ON studio_vision_models
    FOR SELECT USING (true);

CREATE POLICY "Users can manage vision models" ON studio_vision_models
    FOR ALL USING (true);

CREATE POLICY "Users can view vision analytics" ON studio_vision_analytics
    FOR SELECT USING (true);

CREATE POLICY "Users can manage vision analytics" ON studio_vision_analytics
    FOR ALL USING (true);

CREATE POLICY "Users can view speech models" ON studio_speech_models
    FOR SELECT USING (true);

CREATE POLICY "Users can manage speech models" ON studio_speech_models
    FOR ALL USING (true);

CREATE POLICY "Users can view audio analytics" ON studio_audio_analytics
    FOR SELECT USING (true);

CREATE POLICY "Users can manage audio analytics" ON studio_audio_analytics
    FOR ALL USING (true);

CREATE POLICY "Users can view cognitive reasoning" ON studio_cognitive_reasoning
    FOR SELECT USING (true);

CREATE POLICY "Users can manage cognitive reasoning" ON studio_cognitive_reasoning
    FOR ALL USING (true);

CREATE POLICY "Users can view cognitive insights" ON studio_cognitive_insights
    FOR SELECT USING (true);

CREATE POLICY "Users can manage cognitive insights" ON studio_cognitive_insights
    FOR ALL USING (true);

CREATE POLICY "Users can view multimodal models" ON studio_multimodal_models
    FOR SELECT USING (true);

CREATE POLICY "Users can manage multimodal models" ON studio_multimodal_models
    FOR ALL USING (true);

CREATE POLICY "Users can view multimodal analytics" ON studio_multimodal_analytics
    FOR SELECT USING (true);

CREATE POLICY "Users can manage multimodal analytics" ON studio_multimodal_analytics
    FOR ALL USING (true);

-- Donner les permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_nlp_models TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_text_analytics TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_vision_models TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_vision_analytics TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_speech_models TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_audio_analytics TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_cognitive_reasoning TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_cognitive_insights TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_multimodal_models TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON studio_multimodal_analytics TO authenticated, anon;
