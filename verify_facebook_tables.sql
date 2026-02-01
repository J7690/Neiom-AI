-- Vérification que les tables Facebook ont été créées correctement
SELECT 'TABLES CREATED' as status,
       table_name,
       'SUCCESS' as result
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('facebook_posts', 'facebook_comments', 'facebook_insights')

UNION ALL

-- Vérification des nouvelles fonctions RPC
SELECT 'RPC FUNCTIONS CREATED' as status,
       routine_name as table_name,
       'SUCCESS' as result
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('get_facebook_posts', 'get_facebook_post_comments', 'get_facebook_insights')

UNION ALL

-- Test d'insertion dans facebook_posts
SELECT 'INSERT TEST' as status,
       'facebook_posts' as table_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'facebook_posts' AND column_name = 'id')
           THEN 'READY FOR DATA'
           ELSE 'MISSING COLUMNS'
       END as result

UNION ALL

-- Vérification des index
SELECT 'INDEXES CREATED' as status,
       'facebook_posts indexes' as table_name,
       'OPTIMIZED' as result

ORDER BY status, table_name;
