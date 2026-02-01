-- Test des tables marketing créées
-- Exécuter avec: python tools/admin_sql.py test_marketing_tables.sql

-- Vérifier que les tables marketing existent
SELECT 'TABLES CHECK' as verification_type,
       table_name,
       CASE 
           WHEN table_name IN ('studio_marketing_recommendations', 'studio_facebook_prepared_posts', 'studio_marketing_alerts', 'studio_marketing_objectives', 'studio_performance_patterns', 'studio_analysis_cycles')
           THEN '✅ MARKETING TABLE EXISTS'
           ELSE 'OTHER TABLE'
       END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('studio_marketing_recommendations', 'studio_facebook_prepared_posts', 'studio_marketing_alerts', 'studio_marketing_objectives', 'studio_performance_patterns', 'studio_analysis_cycles')
ORDER BY table_name;

-- Insérer des données de test
INSERT INTO studio_marketing_objectives (
    objective,
    target_value,
    unit,
    horizon,
    target_date
) VALUES 
    ('notoriety', 100000, 'vues', 'long_term', '2025-12-31'),
    ('engagement', 5000, 'interactions', 'short_term', '2025-02-28'),
    ('conversion', 100, 'inscriptions', 'medium_term', '2025-06-30');

-- Insérer une recommandation de test
INSERT INTO studio_marketing_recommendations (
    objective,
    recommendation_summary,
    reasoning,
    proposed_format,
    proposed_message,
    confidence_level
) VALUES (
    'engagement',
    'Publier un visuel attractif avec message engageant',
    'Matin : moment optimal pour engagement',
    'image',
    'Votre avenir commence ici. #Education #Excellence',
    'high'
);

-- Vérifier les données insérées
SELECT 'DATA VERIFICATION' as verification_type,
       'studio_marketing_objectives' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as status
FROM studio_marketing_objectives

UNION ALL

SELECT 'DATA VERIFICATION' as verification_type,
       'studio_marketing_recommendations' as table_name,
       COUNT(*)::TEXT as record_count,
       CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as status
FROM studio_marketing_recommendations;

-- Vérifier les RPC marketing existantes
SELECT 'RPC FUNCTIONS CHECK' as verification_type,
       routine_name,
       '✅ MARKETING RPC EXISTS' as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name LIKE '%marketing%'
    OR routine_name LIKE '%recommendation%'
    OR routine_name LIKE '%pattern%'
ORDER BY routine_name;

-- Message final
SELECT 'MARKETING SYSTEM STATUS' as status_type,
       'Architecture Décisionnelle' as component,
       '✅ TABLES CREATED' as tables_status,
       '❌ RPC PENDING' as rpc_status,
       'READY FOR IMPLEMENTATION' as overall_status;
