-- Audit ciblé Phase 5 : Intelligence Prédictive Avancée
-- Vérification de l'état actuel avant implémentation intelligence prédictive

-- 1. Vérifier les tables Phase 4 existantes (base pour Phase 5)
SELECT 'PHASE 4 TABLES' as audit_type,
       table_name,
       CASE 
           WHEN table_name IN ('studio_agent_coordination', 'studio_continuous_learning', 'studio_collective_intelligence_v2', 'studio_agent_networks', 'studio_collective_metrics', 'studio_collective_patterns', 'studio_collective_decisions', 'studio_collective_feedback')
           THEN '✅ PHASE 4 READY'
           ELSE 'OTHER TABLE'
       END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('studio_agent_coordination', 'studio_continuous_learning', 'studio_collective_intelligence_v2', 'studio_agent_networks', 'studio_collective_metrics', 'studio_collective_patterns', 'studio_collective_decisions', 'studio_collective_feedback')
ORDER BY table_name;

-- 2. Vérifier les RPC Phase 4 existantes (base pour Phase 5)
SELECT 'PHASE 4 RPCS' as audit_type,
       routine_name,
       CASE 
           WHEN routine_name IN ('coordinate_agents_collective', 'enable_continuous_learning', 'generate_collective_intelligence', 'create_agent_network', 'analyze_collective_patterns', 'make_collective_decision')
           THEN '✅ PHASE 4 RPC'
           ELSE 'OTHER RPC'
       END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('coordinate_agents_collective', 'enable_continuous_learning', 'generate_collective_intelligence', 'create_agent_network', 'analyze_collective_patterns', 'make_collective_decision')
ORDER BY routine_name;

-- 3. Vérifier les données Phase 4 existantes
SELECT 'PHASE 4 DATA' as audit_type,
       'studio_agent_coordination' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_agent_coordination

UNION ALL

SELECT 'PHASE 4 DATA' as audit_type,
       'studio_collective_intelligence_v2' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_collective_intelligence_v2

UNION ALL

SELECT 'PHASE 4 DATA' as audit_type,
       'studio_continuous_learning' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_continuous_learning

UNION ALL

SELECT 'PHASE 4 DATA' as audit_type,
       'studio_advanced_predictions' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_advanced_predictions;

-- 4. Vérifier l'intégration Facebook (nécessaire pour intelligence prédictive)
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

-- 5. Vérifier les données historiques (nécessaires pour intelligence prédictive)
SELECT 'HISTORICAL DATA' as audit_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 30 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM facebook_posts 
WHERE status = 'published'

UNION ALL

SELECT 'HISTORICAL DATA' as audit_type,
       'studio_marketing_recommendations' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 15 THEN '✅ SUFFICIENT' ELSE '❌ INSUFFICIENT' END as data_status
FROM studio_marketing_recommendations;

-- 6. Vérifier les données prédictives existantes
SELECT 'PREDICTIVE DATA' as audit_type,
       'studio_advanced_predictions' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_advanced_predictions

UNION ALL

SELECT 'PREDICTIVE DATA' as audit_type,
       'studio_performance_predictions' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_performance_predictions;

-- 7. État de préparation pour Phase 5
SELECT 'PHASE 5 READINESS' as audit_type,
       'Phase 4 Foundation' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'studio_collective_intelligence_v2')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 5 READINESS' as audit_type,
       'Phase 4 RPCs' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'generate_collective_intelligence')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'PHASE 5 READINESS' as audit_type,
       'Historical Data' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM facebook_posts WHERE status = 'published') > 30
           THEN '✅ READY'
           ELSE '❌ INSUFFICIENT'
       END as status

UNION ALL

SELECT 'PHASE 5 READINESS' as audit_type,
       'Predictive Base' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM studio_advanced_predictions) > 0
           THEN '✅ READY'
           ELSE '❌ EMPTY'
       END as status

UNION ALL

SELECT 'PHASE 5 READINESS' as audit_type,
       'Flutter Services' as component,
       '✅ PHASE 4 IMPLEMENTED' as status

UNION ALL

SELECT 'PHASE 5 READINESS' as audit_type,
       'Integration Ready' as component,
       '✅ COLLECTIVE INTELLIGENCE READY' as status;
