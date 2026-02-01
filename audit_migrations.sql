-- Audit Facebook - Vérification des migrations récentes
SELECT 
    version,
    name,
    executed_at
FROM supabase_migrations.schema_migrations 
WHERE version LIKE '%facebook%' 
   OR version LIKE '%meta%'
   OR version LIKE '%social%'
   OR version LIKE '%2025-12-16%'
   OR version LIKE '%2025-12-17%'
   OR version LIKE '%2025-12-18%'
ORDER BY executed_at DESC
LIMIT 20;
