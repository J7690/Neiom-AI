-- Audit Facebook - Vérification des fonctions RPC existantes
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_name LIKE '%facebook%' 
        OR routine_name LIKE '%social%'
        OR routine_name LIKE '%meta%'
        OR routine_name LIKE '%whatsapp%'
        OR routine_name LIKE '%insight%'
        OR routine_name LIKE '%analytics%'
    )
ORDER BY routine_name;
