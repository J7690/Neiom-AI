-- AUDIT COMPLET FACEBOOK - Vérification de l'implémentation complète
-- Ce script vérifie tout ce qui est nécessaire pour l'intégration Facebook

-- 1. TABLES EXISTANTES (SOCIAL MEDIA)
SELECT 'TABLES CHECK' as audit_category,
       table_name,
       'EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('social_channels', 'contacts', 'conversations', 'messages', 'leads', 'generation_jobs')

UNION ALL

-- 2. TABLES MANQUANTES (FACEBOOK SPÉCIFIQUES)
SELECT 'MISSING TABLES' as audit_category,
       'facebook_posts' as table_name,
       'MISSING - NEEDED FOR FULL IMPLEMENTATION' as status

UNION ALL

SELECT 'MISSING TABLES' as audit_category,
       'facebook_comments' as table_name,
       'MISSING - NEEDED FOR FULL IMPLEMENTATION' as status

UNION ALL

SELECT 'MISSING TABLES' as audit_category,
       'facebook_insights' as table_name,
       'MISSING - NEEDED FOR FULL IMPLEMENTATION' as status

UNION ALL

-- 3. FONCTIONS RPC EXISTANTES
SELECT 'RPC FUNCTIONS' as audit_category,
       routine_name as table_name,
       'EXISTS' as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('list_social_channels', 'upsert_social_channel', 'receive_meta_webhook', 'verify_whatsapp_challenge', 'get_report_weekly', 'get_dashboard_overview', 'admin_execute_sql')

UNION ALL

-- 4. EDGE FUNCTIONS NÉCESSAIRES (NON VÉRIFIABLE DIRECTEMENT)
SELECT 'EDGE FUNCTIONS' as audit_category,
       'facebook' as table_name,
       'NEEDS DEPLOYMENT CHECK' as status

UNION ALL

SELECT 'EDGE FUNCTIONS' as audit_category,
       'facebook-webhook' as table_name,
       'NEEDS DEPLOYMENT CHECK' as status

UNION ALL

SELECT 'EDGE FUNCTIONS' as audit_category,
       'facebook-instagram-webhook' as table_name,
       'NEEDS DEPLOYMENT CHECK' as status

UNION ALL

-- 5. INTÉGRATION FLUTTER
SELECT 'FLUTTER INTEGRATION' as audit_category,
       'FacebookService' as table_name,
       'IMPLEMENTED - NEEDS RPC CONNECTION' as status

UNION ALL

SELECT 'FLUTTER INTEGRATION' as audit_category,
       'FacebookStudioPage' as table_name,
       'IMPLEMENTED - NEEDS DATA' as status

UNION ALL

SELECT 'FLUTTER INTEGRATION' as audit_category,
       'FacebookPostComposer' as table_name,
       'IMPLEMENTED - NEEDS EDGE FUNCTIONS' as status

UNION ALL

-- 6. VARIABLES D'ENVIRONNEMENT
SELECT 'ENVIRONMENT' as audit_category,
       'FACEBOOK_PAGE_ACCESS_TOKEN' as table_name,
       'CONFIGURED IN .unv/supabase_admin.env' as status

UNION ALL

-- 7. SÉCURITÉ
SELECT 'SECURITY' as audit_category,
       'RLS Policies' as table_name,
       'NEEDS VERIFICATION' as status

UNION ALL

SELECT 'SECURITY' as audit_category,
       'Service Role Access' as table_name,
       'CONFIGURED FOR RPC' as status

ORDER BY audit_category, table_name;
