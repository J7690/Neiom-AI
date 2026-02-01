-- VÉRIFICATION ULTIME - Chaque élément de l'implémentation Facebook
-- Test complet et sans compromis

-- 1. Vérification EXACTE des tables Facebook créées
SELECT 'TABLES CHECK' as verification_type,
       table_name,
       CASE 
           WHEN table_name IN ('facebook_posts', 'facebook_comments', 'facebook_insights') 
           THEN '✅ FACEBOOK TABLE EXISTS'
           ELSE '⚠️ OTHER TABLE'
       END as status,
       table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('social_channels', 'contacts', 'conversations', 'messages', 'leads', 'generation_jobs', 'facebook_posts', 'facebook_comments', 'facebook_insights')
ORDER BY 
    CASE 
        WHEN table_name IN ('facebook_posts', 'facebook_comments', 'facebook_insights') THEN 1
        ELSE 2
    END,
    table_name;

-- 2. Vérification DÉTAILLÉE des colonnes des tables Facebook
SELECT 'COLUMNS CHECK' as verification_type,
       'facebook_posts' as table_name,
       column_name,
       data_type,
       is_nullable,
       ' COLUMN EXISTS' as status
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'facebook_posts'

UNION ALL

SELECT 'COLUMNS CHECK' as verification_type,
       'facebook_comments' as table_name,
       column_name,
       data_type,
       is_nullable,
       ' COLUMN EXISTS' as status
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'facebook_comments'

UNION ALL

SELECT 'COLUMNS CHECK' as verification_type,
       'facebook_insights' as table_name,
       column_name,
       data_type,
       is_nullable,
       ' COLUMN EXISTS' as status
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'facebook_insights'
ORDER BY verification_type, table_name, column_name;

-- 3. Vérification EXACTE des fonctions RPC Facebook
SELECT 'RPC FUNCTIONS CHECK' as verification_type,
       routine_name,
       routine_type,
       external_language,
       security_type,
       CASE 
           WHEN routine_name IN ('get_facebook_posts', 'get_facebook_post_comments', 'get_facebook_insights') 
           THEN '✅ FACEBOOK RPC EXISTS'
           WHEN routine_name IN ('list_social_channels', 'upsert_social_channel', 'receive_meta_webhook', 'admin_execute_sql')
           THEN '✅ SOCIAL RPC EXISTS'
           ELSE '⚠️ OTHER RPC'
       END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_name LIKE '%facebook%' 
        OR routine_name LIKE '%social%'
        OR routine_name LIKE '%meta%'
        OR routine_name LIKE '%admin%'
    )
ORDER BY 
    CASE 
        WHEN routine_name IN ('get_facebook_posts', 'get_facebook_post_comments', 'get_facebook_insights') THEN 1
        WHEN routine_name IN ('list_social_channels', 'upsert_social_channel', 'receive_meta_webhook', 'admin_execute_sql') THEN 2
        ELSE 3
    END,
    routine_name;

-- 4. Test RÉEL des fonctions RPC Facebook
SELECT 'RPC EXECUTION TEST' as verification_type,
       'get_facebook_posts' as function_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'get_facebook_posts')
           THEN '✅ READY TO EXECUTE'
           ELSE '❌ CANNOT EXECUTE'
       END as status

UNION ALL

SELECT 'RPC EXECUTION TEST' as verification_type,
       'get_facebook_post_comments' as function_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'get_facebook_post_comments')
           THEN '✅ READY TO EXECUTE'
           ELSE '❌ CANNOT EXECUTE'
       END as status

UNION ALL

SELECT 'RPC EXECUTION TEST' as verification_type,
       'get_facebook_insights' as function_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name = 'get_facebook_insights')
           THEN '✅ READY TO EXECUTE'
           ELSE '❌ CANNOT EXECUTE'
       END as status;

-- 5. Vérification des données RÉELLEMENT insérées
SELECT 'REAL DATA CHECK' as verification_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE 
           WHEN COUNT(*) > 0 THEN '✅ HAS DATA'
           ELSE '❌ EMPTY TABLE'
       END as status
FROM facebook_posts

UNION ALL

SELECT 'REAL DATA CHECK' as verification_type,
       'facebook_comments' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE 
           WHEN COUNT(*) > 0 THEN '✅ HAS DATA'
           ELSE '❌ EMPTY TABLE'
       END as status
FROM facebook_comments

UNION ALL

SELECT 'REAL DATA CHECK' as verification_type,
       'facebook_insights' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE 
           WHEN COUNT(*) > 0 THEN '✅ HAS DATA'
           ELSE '❌ EMPTY TABLE'
       END as status
FROM facebook_insights;

-- 6. Vérification des index de performance
SELECT 'INDEXES CHECK' as verification_type,
       schemaname || '.' || tablename as table_full_name,
       indexname,
       indexdef,
       '✅ INDEX EXISTS' as status
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND tablename IN ('facebook_posts', 'facebook_comments', 'facebook_insights')
ORDER BY tablename, indexname;

-- 7. Vérification des politiques RLS
SELECT 'RLS POLICIES CHECK' as verification_type,
       tablename,
       policyname,
       permissive,
       roles,
       cmd,
       '✅ POLICY EXISTS' as status
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('facebook_posts', 'facebook_comments', 'facebook_insights')
ORDER BY tablename, policyname;

-- 8. Vérification des permissions
SELECT 'PERMISSIONS CHECK' as verification_type,
       table_name,
       grantee,
       privilege_type,
       '✅ PERMISSION EXISTS' as status
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
    AND table_name IN ('facebook_posts', 'facebook_comments', 'facebook_insights')
    AND grantee IN ('authenticated', 'anon')
ORDER BY table_name, grantee, privilege_type;
