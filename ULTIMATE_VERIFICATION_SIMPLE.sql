-- VÉRIFICATION ULTIME SIMPLE - Chaque élément critique

-- 1. Tables Facebook existent-elles VRAIMENT ?
SELECT 'TABLES EXIST' as check_type,
       table_name,
       CASE 
           WHEN table_name IN ('facebook_posts', 'facebook_comments', 'facebook_insights') 
           THEN '✅ FACEBOOK TABLE'
           ELSE 'OTHER TABLE'
       END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('facebook_posts', 'facebook_comments', 'facebook_insights')
ORDER BY table_name;

-- 2. Fonctions RPC Facebook existent-elles VRAIMENT ?
SELECT 'RPC FUNCTIONS EXIST' as check_type,
       routine_name,
       CASE 
           WHEN routine_name IN ('get_facebook_posts', 'get_facebook_post_comments', 'get_facebook_insights') 
           THEN '✅ FACEBOOK RPC'
           ELSE 'OTHER RPC'
       END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('get_facebook_posts', 'get_facebook_post_comments', 'get_facebook_insights')
ORDER BY routine_name;

-- 3. Y a-t-il des données RÉELLES dans les tables ?
SELECT count(*) as facebook_posts_count,
       CASE WHEN count(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as posts_status
FROM facebook_posts;

SELECT count(*) as facebook_comments_count,
       CASE WHEN count(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as comments_status
FROM facebook_comments;

SELECT count(*) as facebook_insights_count,
       CASE WHEN count(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as insights_status
FROM facebook_insights;

-- 4. Les RPC sociales de base fonctionnent-elles ?
SELECT routine_name,
       '✅ EXISTS' as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('list_social_channels', 'upsert_social_channel', 'receive_meta_webhook', 'admin_execute_sql')
ORDER BY routine_name;

-- 5. Les tables sociales de base existent-elles ?
SELECT table_name,
       '✅ EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('social_channels', 'contacts', 'conversations', 'messages', 'leads')
ORDER BY table_name;
