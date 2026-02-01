-- TEST D'EXÉCUTION RÉELLE des fonctions Facebook

-- Test 1: Exécuter la fonction get_facebook_posts
SELECT 'TEST EXECUTION' as test_type,
       'get_facebook_posts' as function_name,
       'EXECUTING NOW' as status;

-- Test réel de la fonction
SELECT * FROM get_facebook_posts(5, 0);

-- Test 2: Exécuter la fonction get_facebook_post_comments
SELECT 'TEST EXECUTION' as test_type,
       'get_facebook_post_comments' as function_name,
       'EXECUTING NOW' as status;

-- Test réel avec un post_id fictif pour voir si la fonction s'exécute sans erreur
SELECT * FROM get_facebook_post_comments('test_post_12345', 10);

-- Test 3: Exécuter la fonction get_facebook_insights
SELECT 'TEST EXECUTION' as test_type,
       'get_facebook_insights' as function_name,
       'EXECUTING NOW' as status;

-- Test réel de la fonction insights
SELECT * FROM get_facebook_insights('week', NULL);

-- Test 4: Vérifier les tables sociales de base
SELECT 'TEST EXECUTION' as test_type,
       'list_social_channels' as function_name,
       'EXECUTING NOW' as status;

-- Test réel de la fonction sociale
SELECT * FROM list_social_channels() LIMIT 3;
