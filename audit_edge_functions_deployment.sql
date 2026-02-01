-- Audit Facebook - Vérification si les Edge Functions sont déployées
-- Test simple d'appel à une fonction qui devrait exister
SELECT 'EDGE FUNCTIONS TEST' as test_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'admin_execute_sql')
           THEN 'admin_execute_sql EXISTS'
           ELSE 'admin_execute_sql MISSING'
       END as result

UNION ALL

-- Test si les tables sociales existent
SELECT 'SOCIAL TABLES' as test_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'social_channels')
           THEN 'social_channels EXISTS'
           ELSE 'social_channels MISSING'
       END as result

UNION ALL

SELECT 'SOCIAL TABLES' as test_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'contacts')
           THEN 'contacts EXISTS'
           ELSE 'contacts MISSING'
       END as result

UNION ALL

SELECT 'SOCIAL TABLES' as test_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'conversations')
           THEN 'conversations EXISTS'
           ELSE 'conversations MISSING'
       END as result

UNION ALL

-- Test si les RPC sociales existent
SELECT 'SOCIAL RPCS' as test_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'list_social_channels')
           THEN 'list_social_channels EXISTS'
           ELSE 'list_social_channels MISSING'
       END as result

UNION ALL

SELECT 'SOCIAL RPCS' as test_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'upsert_social_channel')
           THEN 'upsert_social_channel EXISTS'
           ELSE 'upsert_social_channel MISSING'
       END as result

UNION ALL

SELECT 'SOCIAL RPCS' as test_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'receive_meta_webhook')
           THEN 'receive_meta_webhook EXISTS'
           ELSE 'receive_meta_webhook MISSING'
       END as result;
