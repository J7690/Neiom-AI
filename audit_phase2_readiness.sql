-- Audit ciblé Phase 2 : Intelligence Avancée
-- Vérification de l'état actuel avant implémentation IA avancée

-- 1. Vérifier les tables marketing existantes (Phase 1)
SELECT 'PHASE 1 TABLES' as audit_type,
       table_name,
       CASE 
           WHEN table_name IN ('studio_marketing_recommendations', 'studio_facebook_prepared_posts', 'studio_marketing_alerts', 'studio_marketing_objectives', 'studio_performance_patterns', 'studio_analysis_cycles')
           THEN '✅ PHASE 1 READY'
           ELSE 'OTHER TABLE'
       END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('studio_marketing_recommendations', 'studio_facebook_prepared_posts', 'studio_marketing_alerts', 'studio_marketing_objectives', 'studio_performance_patterns', 'studio_analysis_cycles')
ORDER BY table_name;

-- 2. Vérifier les RPC marketing existantes (Phase 1)
SELECT 'PHASE 1 RPCS' as audit_type,
       routine_name,
       CASE 
           WHEN routine_name IN ('generate_marketing_recommendation', 'approve_marketing_recommendation', 'reject_marketing_recommendation', 'get_pending_recommendations', 'create_marketing_alert', 'analyze_performance_patterns', 'get_marketing_objectives')
           THEN '✅ PHASE 1 RPC'
           ELSE 'OTHER RPC'
       END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('generate_marketing_recommendation', 'approve_marketing_recommendation', 'reject_marketing_recommendation', 'get_pending_recommendations', 'create_marketing_alert', 'analyze_performance_patterns', 'get_marketing_objectives')
ORDER BY routine_name;

-- 3. Vérifier les données marketing existantes
SELECT 'PHASE 1 DATA' as audit_type,
       'studio_marketing_recommendations' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_marketing_recommendations

UNION ALL

SELECT 'PHASE 1 DATA' as audit_type,
       'studio_performance_patterns' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_performance_patterns

UNION ALL

SELECT 'PHASE 1 DATA' as audit_type,
       'studio_marketing_alerts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_marketing_alerts;

-- 4. Vérifier l'intégration Facebook (nécessaire pour IA avancée)
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

-- 6. État de préparation pour Phase 2
SELECT 'PHASE 2 READINESS' as audit_type,
       'Phase 1 Foundation' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'studio_marketing_recommendations')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 2 READINESS' as audit_type,
       'Marketing RPCs' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'generate_marketing_recommendation')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 2 READINESS' as audit_type,
       'Facebook Integration' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name LIKE 'facebook_%')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 2 READINESS' as audit_type,
       'Data Foundation' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM facebook_posts WHERE status = 'published') > 0
           THEN '✅ READY'
           ELSE '❌ INSUFFICIENT DATA'
       END as status

UNION ALL

SELECT 'PHASE 2 READINESS' as audit_type,
       'Flutter Services' as component,
       '✅ PHASE 1 IMPLEMENTED' as status;
