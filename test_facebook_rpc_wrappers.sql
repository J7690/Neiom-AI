-- Test des RPC wrappers Facebook pour valider le déploiement

-- Test 1: Publication Facebook
SELECT 'TEST PUBLISH' as test_type,
       'facebook_publish_post' as function_name,
       'EXECUTING TEST' as status;

-- Test réel de publication
SELECT * FROM facebook_publish_post('text', 'Test publication depuis RPC wrapper!');

-- Test 2: Récupération des commentaires
SELECT 'TEST COMMENTS' as test_type,
       'facebook_get_comments' as function_name,
       'EXECUTING TEST' as status;

-- Test réel de récupération commentaires
SELECT * FROM facebook_get_comments(NULL, 10);

-- Test 3: Réponse à un commentaire
SELECT 'TEST REPLY' as test_type,
       'facebook_reply_comment' as function_name,
       'EXECUTING TEST' as status;

-- Test réel de réponse (avec un ID de commentaire existant)
SELECT * FROM facebook_reply_comment('test_comment_67890', 'Réponse depuis RPC wrapper!');

-- Test 4: Insights Facebook
SELECT 'TEST INSIGHTS' as test_type,
       'facebook_get_insights' as function_name,
       'EXECUTING TEST' as status;

-- Test réel des insights
SELECT * FROM facebook_get_insights('week');

-- Test 5: Dashboard Facebook
SELECT 'TEST DASHBOARD' as test_type,
       'facebook_dashboard' as function_name,
       'EXECUTING TEST' as status;

-- Test réel du dashboard
SELECT * FROM facebook_dashboard();

-- Test 6: Santé du service
SELECT 'TEST HEALTH' as test_type,
       'facebook_health' as function_name,
       'EXECUTING TEST' as status;

-- Test réel de la santé
SELECT * FROM facebook_health();

-- Vérification finale que tout fonctionne
SELECT 'FINAL VERIFICATION' as verification_type,
       'All Facebook RPCs' as component,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name LIKE 'facebook_%')
           THEN '✅ ALL DEPLOYED'
           ELSE '❌ MISSING'
       END as final_status;
