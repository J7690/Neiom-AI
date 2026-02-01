-- Audit Facebook - Vérification des Edge Functions déployées
-- Note: Cette requête vérifie si les tables de suivi des Edge Functions existent
SELECT 
    function_name,
    status,
    created_at,
    updated_at
FROM supabase_migrations.schema_migrations 
WHERE version LIKE '%facebook%' 
   OR version LIKE '%meta%'
   OR version LIKE '%social%'
ORDER BY created_at DESC;
