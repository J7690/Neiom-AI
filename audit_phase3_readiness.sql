-- Audit ciblé Phase 3 : Excellence Opérationnelle
-- Vérification de l'état actuel avant implémentation excellence

-- 1. Vérifier les tables Phase 2 existantes (base pour Phase 3)
SELECT 'PHASE 2 TABLES' as audit_type,
       table_name,
       CASE 
           WHEN table_name IN ('studio_ab_tests', 'studio_performance_predictions', 'studio_proactive_alerts', 'studio_learning_insights', 'studio_content_cohorts', 'studio_content_quality_scores')
           THEN '✅ PHASE 2 READY'
           ELSE 'OTHER TABLE'
       END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('studio_ab_tests', 'studio_performance_predictions', 'studio_proactive_alerts', 'studio_learning_insights', 'studio_content_cohorts', 'studio_content_quality_scores')
ORDER BY table_name;

-- 2. Vérifier les RPC Phase 2 existantes (base pour Phase 3)
SELECT 'PHASE 2 RPCS' as audit_type,
       routine_name,
       CASE 
           WHEN routine_name IN ('create_ab_test', 'analyze_ab_test', 'generate_performance_predictions', 'create_proactive_alerts', 'analyze_advanced_patterns', 'get_proactive_alerts')
           THEN '✅ PHASE 2 RPC'
           ELSE 'OTHER RPC'
       END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('create_ab_test', 'analyze_ab_test', 'generate_performance_predictions', 'create_proactive_alerts', 'analyze_advanced_patterns', 'get_proactive_alerts')
ORDER BY routine_name;

-- 3. Vérifier les données Phase 2 existantes
SELECT 'PHASE 2 DATA' as audit_type,
       'studio_ab_tests' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_ab_tests

UNION ALL

SELECT 'PHASE 2 DATA' as audit_type,
       'studio_performance_predictions' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_performance_predictions

UNION ALL

SELECT 'PHASE 2 DATA' as audit_type,
       'studio_proactive_alerts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_proactive_alerts

UNION ALL

SELECT 'PHASE 2 DATA' as audit_type,
       'studio_learning_insights' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_learning_insights;

-- 4. Vérifier l'intégration Facebook (nécessaire pour excellence)
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

-- 5. Vérifier les RPC Facebook existantes
SELECT 'FACEBOOK RPCS' as audit_type,
       routine_name,
       '✅ FACEBOOK RPC' as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name LIKE 'facebook_%'
ORDER BY routine_name;

-- 6. Vérifier les données historiques (nécessaires pour excellence)
SELECT 'HISTORICAL DATA' as audit_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 10 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM facebook_posts 
WHERE status = 'published'

UNION ALL

SELECT 'HISTORICAL DATA' as audit_type,
       'studio_marketing_recommendations' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 5 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM studio_marketing_recommendations;

-- 7. État de préparation pour Phase 3
SELECT 'PHASE 3 READINESS' as audit_type,
       'Phase 2 Foundation' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'studio_ab_tests')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 3 READINESS' as audit_type,
       'Phase 2 RPCs' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'create_ab_test')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 3 READINESS' as audit_type,
       'Historical Data' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM facebook_posts WHERE status = 'published') > 10
           THEN '✅ READY'
           ELSE '❌ INSUFFICIENT'
       END as status

UNION ALL

SELECT 'PHASE 3 READINESS' as audit_type,
       'Flutter Services' as component,
       '✅ PHASE 2 IMPLEMENTED' as status

UNION ALL

SELECT 'PHASE 3 READINESS' as audit_type,
       'Intelligence Base' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM studio_learning_insights) > 0
           THEN '✅ READY'
           ELSE '❌ EMPTY'
       END as status;
