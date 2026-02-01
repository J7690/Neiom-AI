-- Test simple des RPC wrappers Facebook

-- Test 1: Vérifier que les RPC Facebook existent
SELECT 'RPC EXISTENCE CHECK' as test_type,
       routine_name,
       '✅ EXISTS' as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name LIKE 'facebook_%'
ORDER BY routine_name;

-- Test 2: Test de publication simple
SELECT 'PUBLISH TEST' as test_type,
       'facebook_publish_post' as function_name,
       'TESTING NOW' as status;

-- Exécuter la publication
SELECT * FROM facebook_publish_post('text', 'Test RPC wrapper publication!');

-- Test 3: Test des insights
SELECT 'INSIGHTS TEST' as test_type,
       'facebook_get_insights' as function_name,
       'TESTING NOW' as status;

-- Exécuter les insights
SELECT * FROM facebook_get_insights('week');

-- Test 4: Test du dashboard
SELECT 'DASHBOARD TEST' as test_type,
       'facebook_dashboard' as function_name,
       'TESTING NOW' as status;

-- Exécuter le dashboard
SELECT * FROM facebook_dashboard();

-- Test 5: Test de santé
SELECT 'HEALTH TEST' as test_type,
       'facebook_health' as function_name,
       'TESTING NOW' as status;

-- Exécuter le test de santé
SELECT * FROM facebook_health();

-- Test 6: Vérification des données créées
SELECT 'DATA VERIFICATION' as test_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as status
FROM facebook_posts

UNION ALL

SELECT 'DATA VERIFICATION' as test_type,
       'facebook_comments' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as status
FROM facebook_comments;
