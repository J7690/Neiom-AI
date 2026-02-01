-- Audit Facebook - Vérification des tables existantes
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND (
        table_name LIKE '%facebook%' 
        OR table_name LIKE '%social%'
        OR table_name LIKE '%post%'
        OR table_name LIKE '%comment%'
        OR table_name LIKE '%insight%'
        OR table_name LIKE '%analytics%'
    )
ORDER BY table_name;
