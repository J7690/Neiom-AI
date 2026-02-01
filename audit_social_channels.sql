-- Audit Facebook - Vérification de la table social_channels
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'social_channels'
ORDER BY ordinal_position;
