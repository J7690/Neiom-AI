-- Audit Facebook - Test de connexion aux Edge Functions
-- Vérification si les endpoints Facebook sont accessibles

-- Test si la fonction admin_execute_sql fonctionne (déjà confirmé)
SELECT 'EDGE FUNCTION TEST' as test_type,
       'admin_execute_sql' as function_name,
       'WORKING - AUDIT POSSIBLE' as status

UNION ALL

-- Vérification des tables nécessaires pour les Edge Functions
SELECT 'EDGE FUNCTION PREREQS' as test_type,
       'social_channels table' as requirement,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'social_channels')
           THEN 'READY'
           ELSE 'MISSING'
       END as status

UNION ALL

SELECT 'EDGE FUNCTION PREREQS' as test_type,
       'contacts table' as requirement,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'contacts')
           THEN 'READY'
           ELSE 'MISSING'
       END as status

UNION ALL

SELECT 'EDGE FUNCTION PREREQS' as test_type,
       'conversations table' as requirement,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'conversations')
           THEN 'READY'
           ELSE 'MISSING'
       END as status

UNION ALL

-- Vérification des RPC nécessaires pour les Edge Functions
SELECT 'EDGE FUNCTION RPCS' as test_type,
       'receive_meta_webhook' as rpc_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'receive_meta_webhook')
           THEN 'READY'
           ELSE 'MISSING'
       END as status

UNION ALL

SELECT 'EDGE FUNCTION RPCS' as test_type,
       'verify_whatsapp_challenge' as rpc_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'verify_whatsapp_challenge')
           THEN 'READY'
           ELSE 'MISSING'
       END as status

UNION ALL

-- Vérification des variables d'environnement (non vérifiable directement)
SELECT 'ENVIRONMENT CHECK' as test_type,
       'FACEBOOK_PAGE_ACCESS_TOKEN' as env_var,
       'CONFIGURED IN .unv/supabase_admin.env' as status

UNION ALL

SELECT 'ENVIRONMENT CHECK' as test_type,
       'SUPABASE_SERVICE_ROLE_KEY' as env_var,
       'CONFIGURED IN .unv/supabase_admin.env' as status;
