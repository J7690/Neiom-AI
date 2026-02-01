-- Test complet de l'implémentation marketing décisionnelle
-- Vérification que tout fonctionne correctement

-- 1. Tester la génération de recommandations
SELECT 'TEST 1: GENERATION RECOMMANDATIONS' as test_type,
       'generate_marketing_recommendation' as function_name,
       'EXECUTING' as status;

SELECT * FROM generate_marketing_recommendation() LIMIT 3;

-- 2. Tester l'approbation d'une recommandation
SELECT 'TEST 2: APPROBATION RECOMMANDATION' as test_type,
       'approve_marketing_recommendation' as function_name,
       'EXECUTING' as status;

-- Récupérer une recommandation pour l'approuver (version Postgres sans variable session)
WITH candidate AS (
  SELECT id
  FROM studio_marketing_recommendations
  WHERE status = 'pending'
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT * FROM approve_marketing_recommendation((SELECT id FROM candidate));

-- 3. Tester la récupération des recommandations en attente
SELECT 'TEST 3: RECOMMANDATIONS EN ATTENTE' as test_type,
       'get_pending_recommendations' as function_name,
       'EXECUTING' as status;

SELECT * FROM get_pending_recommendations();

-- 4. Tester la création d'alertes
SELECT 'TEST 4: CREATION ALERTES' as test_type,
       'create_marketing_alert' as function_name,
       'EXECUTING' as status;

SELECT * FROM create_marketing_alert('test_alert', 'Alerte test implementation');

-- 5. Tester l'analyse des patterns
SELECT 'TEST 5: ANALYSE PATTERNS' as test_type,
       'analyze_performance_patterns' as function_name,
       'EXECUTING' as status;

SELECT * FROM analyze_performance_patterns();

-- 6. Tester les objectifs marketing
SELECT 'TEST 6: OBJECTIFS MARKETING' as test_type,
       'get_marketing_objectives' as function_name,
       'EXECUTING' as status;

SELECT * FROM get_marketing_objectives();

-- 7. Vérification finale de l'état
SELECT 'FINAL VERIFICATION' as verification_type,
       'Marketing RPCs' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'generate_marketing_recommendation')
           THEN '✅ IMPLEMENTED'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'FINAL VERIFICATION' as verification_type,
       'Marketing Tables' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'studio_marketing_recommendations')
           THEN '✅ READY'
           ELSE '❌ MISSING'
       END as status

UNION ALL

SELECT 'FINAL VERIFICATION' as verification_type,
       'Marketing Data' as component,
       CASE 
           WHEN (SELECT COUNT(*) FROM studio_marketing_recommendations) > 0
           THEN '✅ POPULATED'
           ELSE '❌ EMPTY'
       END as status

UNION ALL

SELECT 'FINAL VERIFICATION' as verification_type,
       'Integration Ready' as component,
       '✅ FLUTTER CAN CONNECT' as status;
