-- CONFIRMATION FINALE - Vérification ultime de chaque composant

-- 1. Confirmation des tables Facebook avec leurs colonnes exactes
SELECT 'FACEBOOK POSTS TABLE' as confirmation,
       column_name,
       data_type,
       is_nullable,
       CASE WHEN column_name IS NOT NULL THEN '✅ COLUMN EXISTS' ELSE '❌ MISSING' END as status
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'facebook_posts'
ORDER BY ordinal_position;

-- 2. Confirmation des données réelles dans chaque table
SELECT 'FACEBOOK POSTS DATA' as confirmation,
       COUNT(*)::TEXT as total_records,
       CASE WHEN COUNT(*) > 0 THEN '✅ DATA EXISTS' ELSE '❌ NO DATA' END as data_status,
       MIN(created_at)::TEXT as first_record,
       MAX(created_at)::TEXT as last_record
FROM facebook_posts;

SELECT 'FACEBOOK COMMENTS DATA' as confirmation,
       COUNT(*)::TEXT as total_records,
       CASE WHEN COUNT(*) > 0 THEN '✅ DATA EXISTS' ELSE '❌ NO DATA' END as data_status,
       MIN(created_at)::TEXT as first_record,
       MAX(created_at)::TEXT as last_record
FROM facebook_comments;

SELECT 'FACEBOOK INSIGHTS DATA' as confirmation,
       COUNT(*)::TEXT as total_records,
       CASE WHEN COUNT(*) > 0 THEN '✅ DATA EXISTS' ELSE '❌ NO DATA' END as data_status,
       MIN(retrieved_at)::TEXT as first_record,
       MAX(retrieved_at)::TEXT as last_record
FROM facebook_insights;

-- 3. Confirmation des fonctions RPC avec leur type de retour
SELECT 'FACEBOOK RPC FUNCTIONS' as confirmation,
       routine_name,
       routine_type,
       external_language,
       security_type,
       CASE WHEN routine_name IS NOT NULL THEN '✅ FUNCTION READY' ELSE '❌ MISSING' END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('get_facebook_posts', 'get_facebook_post_comments', 'get_facebook_insights')
ORDER BY routine_name;

-- 4. Confirmation des tables sociales existantes
SELECT 'SOCIAL TABLES' as confirmation,
       table_name,
       table_type,
       CASE WHEN table_name IS NOT NULL THEN '✅ TABLE EXISTS' ELSE '❌ MISSING' END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('social_channels', 'contacts', 'conversations', 'messages', 'leads')
ORDER BY table_name;

-- 5. Confirmation des RPC sociales existantes
SELECT 'SOCIAL RPC FUNCTIONS' as confirmation,
       routine_name,
       routine_type,
       CASE WHEN routine_name IS NOT NULL THEN '✅ FUNCTION READY' ELSE '❌ MISSING' END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('list_social_channels', 'upsert_social_channel', 'receive_meta_webhook', 'admin_execute_sql')
ORDER BY routine_name;
