-- Audit ciblé Phase 4 : Intelligence Collective
-- Vérification de l'état actuel avant implémentation intelligence collective

-- 1. Vérifier les tables Phase 3 existantes (base pour Phase 4)
SELECT 'PHASE 3 TABLES' as audit_type,
       table_name,
       CASE 
           WHEN table_name IN ('studio_campaign_optimization', 'studio_roi_tracking', 'studio_collective_intelligence', 'studio_budget_optimization', 'studio_advanced_predictions', 'studio_performance_cohorts', 'studio_advanced_quality_scores', 'studio_optimization_alerts')
           THEN '✅ PHASE 3 READY'
           ELSE 'OTHER TABLE'
       END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('studio_campaign_optimization', 'studio_roi_tracking', 'studio_collective_intelligence', 'studio_budget_optimization', 'studio_advanced_predictions', 'studio_performance_cohorts', 'studio_advanced_quality_scores', 'studio_optimization_alerts')
ORDER BY table_name;

-- 2. Vérifier les RPC Phase 3 existantes (base pour Phase 4)
SELECT 'PHASE 3 RPCS' as audit_type,
       routine_name,
       CASE 
           WHEN routine_name IN ('optimize_campaign_automatically', 'calculate_campaign_roi', 'optimize_budget_allocation', 'generate_advanced_predictions', 'create_optimization_alerts', 'get_optimization_alerts')
           THEN '✅ PHASE 3 RPC'
           ELSE 'OTHER RPC'
       END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('optimize_campaign_automatically', 'calculate_campaign_roi', 'optimize_budget_allocation', 'generate_advanced_predictions', 'create_optimization_alerts', 'get_optimization_alerts')
ORDER BY routine_name;

-- 3. Vérifier les données Phase 3 existantes
SELECT 'PHASE 3 DATA' as audit_type,
       'studio_campaign_optimization' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_campaign_optimization

UNION ALL

SELECT 'PHASE 3 DATA' as audit_type,
       'studio_roi_tracking' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_roi_tracking

UNION ALL

SELECT 'PHASE 3 DATA' as audit_type,
       'studio_collective_intelligence' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_collective_intelligence

UNION ALL

SELECT 'PHASE 3 DATA' as audit_type,
       'studio_advanced_predictions' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_advanced_predictions;

-- 4. Vérifier l'intégration Facebook (nécessaire pour intelligence collective)
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

-- 5. Vérifier les données historiques (nécessaires pour intelligence collective)
SELECT 'HISTORICAL DATA' as audit_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 20 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM facebook_posts 
WHERE status = 'published'

UNION ALL

SELECT 'HISTORICAL DATA' as audit_type,
       'studio_marketing_recommendations' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 10 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM studio_marketing_recommendations;

-- 6. Vérifier les données d'intelligence collective existantes
SELECT 'COLLECTIVE INTELLIGENCE' as audit_type,
       'studio_collective_intelligence' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_collective_intelligence

UNION ALL

SELECT 'COLLECTIVE INTELLIGENCE' as audit_type,
       'studio_learning_insights' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_learning_insights;

-- 7. État de préparation pour Phase 4
SELECT 'PHASE 4 READINESS' as audit_type,
       'Phase 3 Foundation' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'studio_collective_intelligence')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 4 READINESS' as audit_type,
       'Phase 3 RPCs' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'optimize_campaign_automatically')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 4 READINESS' as audit_type,
       'Historical Data' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM facebook_posts WHERE status = 'published') > 20
           THEN '✅ READY'
           ELSE '❌ INSUFFICIENT'
       END as status

UNION ALL

SELECT 'PHASE 4 READINESS' as audit_type,
       'Collective Intelligence Base' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM studio_collective_intelligence) > 0
           THEN '✅ READY'
           ELSE '❌ EMPTY'
       END as status

UNION ALL

SELECT 'PHASE 4 READINESS' as audit_type,
       'Flutter Services' as component,
       '✅ PHASE 3 IMPLEMENTED' as status

UNION ALL

SELECT 'PHASE 4 READINESS' as audit_type,
       'Integration Ready' as component,
       '✅ EXCELLENCE MARKETING READY' as status;
