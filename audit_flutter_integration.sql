-- Audit Facebook - Vérification de l'intégration avec Flutter
-- Test des RPC que le service Flutter va appeler

-- Test si les RPC utilisées par le service Flutter existent
SELECT 'FLUTTER INTEGRATION' as integration_type,
       'list_social_channels' as rpc_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'list_social_channels')
           THEN 'READY FOR FLUTTER'
           ELSE 'MISSING - FLUTTER WILL FAIL'
       END as status

UNION ALL

SELECT 'FLUTTER INTEGRATION' as integration_type,
       'upsert_social_channel' as rpc_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'upsert_social_channel')
           THEN 'READY FOR FLUTTER'
           ELSE 'MISSING - FLUTTER WILL FAIL'
       END as status

UNION ALL

SELECT 'FLUTTER INTEGRATION' as integration_type,
       'get_report_weekly' as rpc_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'get_report_weekly')
           THEN 'READY FOR FLUTTER'
           ELSE 'MISSING - FLUTTER WILL FAIL'
       END as status

UNION ALL

SELECT 'FLUTTER INTEGRATION' as integration_type,
       'get_dashboard_overview' as rpc_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'get_dashboard_overview')
           THEN 'READY FOR FLUTTER'
           ELSE 'MISSING - FLUTTER WILL FAIL'
       END as status

UNION ALL

-- Vérification des tables que Flutter va utiliser
SELECT 'FLUTTER TABLES' as integration_type,
       'social_channels' as table_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'social_channels')
           THEN 'READY FOR FLUTTER'
           ELSE 'MISSING - FLUTTER WILL FAIL'
       END as status

UNION ALL

SELECT 'FLUTTER TABLES' as integration_type,
       'contacts' as table_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'contacts')
           THEN 'READY FOR FLUTTER'
           ELSE 'MISSING - FLUTTER WILL FAIL'
       END as status

UNION ALL

SELECT 'FLUTTER TABLES' as integration_type,
       'conversations' as table_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'conversations')
           THEN 'READY FOR FLUTTER'
           ELSE 'MISSING - FLUTTER WILL FAIL'
       END as status

UNION ALL

SELECT 'FLUTTER TABLES' as integration_type,
       'messages' as table_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'messages')
           THEN 'READY FOR FLUTTER'
           ELSE 'MISSING - FLUTTER WILL FAIL'
       END as status;
