-- Audit Facebook - Vérification des migrations récentes (version simple)
SELECT 
    version,
    name
FROM supabase_migrations.schema_migrations 
WHERE version LIKE '%facebook%' 
   OR version LIKE '%meta%'
   OR version LIKE '%social%'
   OR version LIKE '%2025-12-16%'
   OR version LIKE '%2025-12-17%'
   OR version LIKE '%2025-12-18%'
ORDER BY version DESC
LIMIT 20;
