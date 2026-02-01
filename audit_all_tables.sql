-- Audit Facebook - Liste complète des tables pour vérification
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND (
        table_name IN ('social_channels', 'contacts', 'conversations', 'messages', 'leads', 'generation_jobs', 'voice_profiles', 'text_templates', 'image_assets', 'visual_projects', 'visual_documents', 'visual_document_versions', 'ad_accounts', 'ad_campaigns', 'campaign_templates', 'alerts', 'social_posts', 'social_schedules')
    )
ORDER BY table_name;
