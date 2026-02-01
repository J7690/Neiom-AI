-- Audit ciblé pour l'implémentation marketing décisionnelle
-- Vérification de l'état actuel avant implémentation

-- 1. Vérifier les tables marketing créées précédemment
SELECT 'MARKETING TABLES' as audit_type,
       table_name,
       CASE 
           WHEN table_name IN ('studio_marketing_recommendations', 'studio_facebook_prepared_posts', 'studio_marketing_alerts', 'studio_marketing_objectives', 'studio_performance_patterns', 'studio_analysis_cycles')
           THEN '✅ MARKETING TABLE EXISTS'
           ELSE 'OTHER TABLE'
       END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('studio_marketing_recommendations', 'studio_facebook_prepared_posts', 'studio_marketing_alerts', 'studio_marketing_objectives', 'studio_performance_patterns', 'studio_analysis_cycles')
ORDER BY table_name;

-- 2. Vérifier les RPC marketing existantes
SELECT 'MARKETING RPCS' as audit_type,
       routine_name,
       CASE 
           WHEN routine_name LIKE '%marketing%' OR routine_name LIKE '%recommendation%' OR routine_name LIKE '%pattern%'
           THEN '✅ MARKETING RPC EXISTS'
           ELSE 'OTHER RPC'
       END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (routine_name LIKE '%marketing%' OR routine_name LIKE '%recommendation%' OR routine_name LIKE '%pattern%')
ORDER BY routine_name;

-- 3. Vérifier les données dans les tables marketing
SELECT 'MARKETING DATA' as audit_type,
       'studio_marketing_objectives' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_marketing_objectives

UNION ALL

SELECT 'MARKETING DATA' as audit_type,
       'studio_marketing_recommendations' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_marketing_recommendations

UNION ALL

SELECT 'MARKETING DATA' as audit_type,
       'studio_facebook_prepared_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as data_status
FROM studio_facebook_prepared_posts;

-- 4. Vérifier les RPC existantes qui pourraient être réutilisées
SELECT 'EXISTING RPCS' as audit_type,
       routine_name,
       routine_type,
       '✅ REUSABLE' as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('list_social_channels', 'upsert_social_channel', 'get_report_weekly', 'get_dashboard_overview', 'list_alerts', 'ack_alert', 'run_alert_rules')
ORDER BY routine_name;

-- 5. Vérifier l'intégration Facebook existante
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

-- 6. État de préparation pour l'implémentation
SELECT 'IMPLEMENTATION READINESS' as audit_type,
       'Tables Marketing' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'studio_marketing_recommendations')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'IMPLEMENTATION READINESS' as audit_type,
       'RPC Marketing' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name LIKE '%marketing%')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'IMPLEMENTATION READINESS' as audit_type,
       'Facebook Integration' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name LIKE 'facebook_%')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'IMPLEMENTATION READINESS' as audit_type,
       'Flutter Services' as component,
       '✅ EXISTING' as status;
