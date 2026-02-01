-- Audit Facebook - Vérification des tables manquantes pour l'implémentation complète
-- Tables Facebook spécifiques qui devraient exister selon notre implémentation
SELECT 'MISSING TABLES' as audit_type, 
       'facebook_posts' as table_name,
       'NOT FOUND' as status
WHERE NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'facebook_posts')

UNION ALL

SELECT 'MISSING TABLES' as audit_type, 
       'facebook_comments' as table_name,
       'NOT FOUND' as status
WHERE NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'facebook_comments')

UNION ALL

SELECT 'MISSING TABLES' as audit_type, 
       'facebook_insights' as table_name,
       'NOT FOUND' as status
WHERE NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'facebook_insights')

UNION ALL

-- Vérification des tables existantes qui sont utilisées
SELECT 'EXISTING TABLES' as audit_type, 
       table_name,
       'FOUND' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('social_channels', 'contacts', 'conversations', 'messages', 'leads', 'generation_jobs')

ORDER BY audit_type, table_name;
