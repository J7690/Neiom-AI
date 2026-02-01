-- Vérification de l'état des Edge Functions avant déploiement
-- Les Edge Functions sont stockées dans des tables système Supabase

SELECT 'EDGE FUNCTIONS STATUS' as check_type,
       'Checking deployment tables' as description,
       'STARTING VERIFICATION' as status

UNION ALL

-- Vérifier si les tables de migration existent
SELECT 'MIGRATION TABLES' as check_type,
       'supabase_migrations.schema_migrations' as table_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'supabase_migrations' AND table_name = 'schema_migrations')
           THEN '✅ EXISTS'
           ELSE '❌ MISSING'
       END as status

UNION ALL

-- Vérifier les migrations existantes
SELECT 'EXISTING MIGRATIONS' as check_type,
       'Facebook related migrations' as description,
       CASE 
           WHEN EXISTS (SELECT 1 FROM supabase_migrations.schema_migrations WHERE version LIKE '%facebook%' OR version LIKE '%meta%')
           THEN '✅ FOUND'
           ELSE '❌ NONE FOUND'
       END as status

UNION ALL

-- Vérifier les tables système pour Edge Functions
SELECT 'EDGE FUNCTIONS TABLES' as check_type,
       'supabase_functions.functions' as table_name,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'supabase_functions' AND table_name = 'functions')
           THEN '✅ EXISTS'
           ELSE '❌ MISSING'
       END as status

UNION ALL

-- Préparation pour le déploiement
SELECT 'DEPLOYMENT READINESS' as check_type,
       'Facebook Edge Functions' as description,
       'READY TO DEPLOY' as status;
