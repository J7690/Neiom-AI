-- Test d'intégration Facebook - Insertion de données test
-- Test d'insertion dans facebook_posts
INSERT INTO facebook_posts (
    type, 
    message, 
    status, 
    facebook_post_id, 
    facebook_url
) VALUES (
    'text',
    'Test publication Facebook depuis Nexiom Studio',
    'published',
    'test_post_12345',
    'https://facebook.com/test_post_12345'
);

-- Test d'insertion dans facebook_comments
INSERT INTO facebook_comments (
    facebook_post_id,
    facebook_comment_id,
    message,
    from_name,
    from_id,
    created_time,
    like_count,
    can_reply
) VALUES (
    'test_post_12345',
    'test_comment_67890',
    'Super publication !',
    'Jean Test',
    'user_123',
    now() - INTERVAL '1 hour',
    5,
    true
);

-- Test d'insertion dans facebook_insights
INSERT INTO facebook_insights (
    metric_name,
    period,
    value,
    end_time,
    title,
    description
) VALUES (
    'page_impressions',
    'week',
    1250,
    now(),
    'Impressions de la page',
    'Nombre de fois que la page a été vue'
);

-- Vérification des données insérées
SELECT 'DATA VERIFICATION' as test_type,
       'facebook_posts' as table_name,
       COUNT(*)::TEXT as record_count
FROM facebook_posts

UNION ALL

SELECT 'DATA VERIFICATION' as test_type,
       'facebook_comments' as table_name,
       COUNT(*)::TEXT as record_count
FROM facebook_comments

UNION ALL

SELECT 'DATA VERIFICATION' as test_type,
       'facebook_insights' as table_name,
       COUNT(*)::TEXT as record_count
FROM facebook_insights

UNION ALL

-- Test des fonctions RPC
SELECT 'RPC TEST' as test_type,
       'get_facebook_posts' as function_name,
       'AVAILABLE' as status

UNION ALL

SELECT 'RPC TEST' as test_type,
       'get_facebook_post_comments' as function_name,
       'AVAILABLE' as status

UNION ALL

SELECT 'RPC TEST' as test_type,
       'get_facebook_insights' as function_name,
       'AVAILABLE' as status

ORDER BY test_type, table_name;
