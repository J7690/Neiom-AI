-- Audit Facebook - Détails des fonctions RPC existantes
SELECT 
    routine_name,
    routine_type,
    external_language,
    security_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_name LIKE '%social%' 
        OR routine_name LIKE '%facebook%' 
        OR routine_name LIKE '%meta%'
        OR routine_name LIKE '%whatsapp%'
        OR routine_name LIKE '%report%'
        OR routine_name LIKE '%dashboard%'
        OR routine_name LIKE '%admin%'
    )
ORDER BY routine_name;
