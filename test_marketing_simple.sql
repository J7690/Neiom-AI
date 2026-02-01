-- Test simple de l'implémentation marketing décisionnelle

-- 1. Tester la génération de recommandations
SELECT 'TEST GENERATION' as test_type,
       'generate_marketing_recommendation' as function_name,
       'EXECUTING' as status;

SELECT * FROM generate_marketing_recommendation() LIMIT 2;

-- 2. Tester la récupération des recommandations en attente
SELECT 'TEST PENDING' as test_type,
       'get_pending_recommendations' as function_name,
       'EXECUTING' as status;

SELECT * FROM get_pending_recommendations();

-- 3. Tester la création d'alertes
SELECT 'TEST ALERTS' as test_type,
       'create_marketing_alert' as function_name,
       'EXECUTING' as status;

SELECT * FROM create_marketing_alert('test', 'Alerte test');

-- 4. Vérification finale
SELECT 'VERIFICATION FINALE' as verification_type,
       'Marketing RPCs' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'generate_marketing_recommendation')
           THEN '✅ IMPLEMENTED'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'VERIFICATION FINALE' as verification_type,
       'Marketing Tables' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'studio_marketing_recommendations')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'VERIFICATION FINALE' as verification_type,
       'Marketing Data' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM studio_marketing_recommendations) > 0
           THEN '✅ POPULATED'
           ELSE '❌ EMPTY'
       END as status;
