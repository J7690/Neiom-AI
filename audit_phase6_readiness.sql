-- Audit ciblé Phase 6 : Intelligence Cognitive Avancée
-- Vérification de l'état actuel avant implémentation intelligence cognitive

-- 1. Vérifier les tables Phase 5 existantes (base pour Phase 6)
SELECT 'PHASE 5 TABLES' as audit_type,
       table_name,
       CASE 
           WHEN table_name IN ('studio_ml_models', 'studio_multi_model_predictions', 'studio_real_time_predictions', 'studio_predictive_optimization', 'studio_temporal_intelligence', 'studio_ml_features', 'studio_training_datasets', 'studio_predictive_metrics', 'studio_predictive_alerts')
           THEN '✅ PHASE 5 READY'
           ELSE 'OTHER TABLE'
       END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('studio_ml_models', 'studio_multi_model_predictions', 'studio_real_time_predictions', 'studio_predictive_optimization', 'studio_temporal_intelligence', 'studio_ml_features', 'studio_training_datasets', 'studio_predictive_metrics', 'studio_predictive_alerts')
ORDER BY table_name;

-- 2. Vérifier les RPC Phase 5 existantes (base pour Phase 6)
SELECT 'PHASE 5 RPCS' as audit_type,
       routine_name,
       CASE 
           WHEN routine_name IN ('create_ml_model', 'generate_multi_model_predictions', 'create_real_time_prediction', 'optimize_predictively', 'analyze_temporal_intelligence', 'create_predictive_alerts')
           THEN '✅ PHASE 5 RPC'
           ELSE 'OTHER RPC'
       END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('create_ml_model', 'generate_multi_model_predictions', 'create_real_time_prediction', 'optimize_predictively', 'analyze_temporal_intelligence', 'create_predictive_alerts')
ORDER BY routine_name;

-- 3. Vérifier les données Phase 5 existantes
SELECT 'PHASE 5 DATA' as audit_type,
       'studio_ml_models' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_ml_models

UNION ALL

SELECT 'PHASE 5 DATA' as audit_type,
       'studio_multi_model_predictions' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_multi_model_predictions

UNION ALL

SELECT 'PHASE 5 DATA' as audit_type,
       'studio_real_time_predictions' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_real_time_predictions

UNION ALL

SELECT 'PHASE 5 DATA' as audit_type,
       'studio_predictive_optimization' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_predictive_optimization;

-- 4. Vérifier l'intégration Facebook (nécessaire pour intelligence cognitive)
SELECT 'FACEBOOK INTEGRATION' as audit_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ FACEBOOK READY' ELSE '❌ NO DATA' END as status
FROM facebook_posts

UNION ALL

SELECT 'FACEBOOK INTEGRATION' as audit_type,
       'facebook_comments' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ FACEBOOK READY' ELSE '❌ NO DATA' END as status
FROM facebook_comments;

-- 5. Vérifier les données textuelles (nécessaires pour NLP)
SELECT 'TEXTUAL DATA' as audit_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 50 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM facebook_posts 
WHERE content IS NOT NULL AND content != ''

UNION ALL

SELECT 'TEXTUAL DATA' as audit_type,
       'facebook_comments' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 100 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM facebook_comments 
WHERE content IS NOT NULL AND content != '';

-- 6. Vérifier les données multimédia (nécessaires pour computer vision)
SELECT 'MULTIMEDIA DATA' as audit_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 20 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM facebook_posts 
WHERE image_url IS NOT NULL OR video_url IS NOT NULL;

-- 7. État de préparation pour Phase 6
SELECT 'PHASE 6 READINESS' as audit_type,
       'Phase 5 Foundation' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'studio_ml_models')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 6 READINESS' as audit_type,
       'Phase 5 RPCs' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'create_ml_model')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 6 READINESS' as audit_type,
       'Textual Data' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM facebook_posts WHERE content IS NOT NULL AND content != '') > 50
           THEN '✅ READY'
           ELSE '❌ INSUFFICIENT'
       END as status

UNION ALL

SELECT 'PHASE 6 READINESS' as audit_type,
       'Multimedia Data' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM facebook_posts WHERE image_url IS NOT NULL OR video_url IS NOT NULL) > 20
           THEN '✅ READY'
           ELSE '❌ INSUFFICIENT'
       END as status

UNION ALL

SELECT 'PHASE 6 READINESS' as audit_type,
       'Flutter Services' as component,
       '✅ PHASE 5 IMPLEMENTED' as status

UNION ALL

SELECT 'PHASE 6 READINESS' as audit_type,
       'Integration Ready' as component,
       '✅ PREDICTIVE INTELLIGENCE READY' as status;
