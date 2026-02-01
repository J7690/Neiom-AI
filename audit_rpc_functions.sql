-- Audit Facebook - Vérification des fonctions RPC spécifiques
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_name IN ('list_social_channels', 'upsert_social_channel', 'receive_meta_webhook', 'verify_whatsapp_challenge', 'verify_meta_signature', 'get_report_weekly', 'get_report_monthly', 'get_dashboard_overview', 'list_alerts', 'ack_alert', 'recommend_ad_campaigns', 'create_ads_from_reco', 'list_ad_campaigns', 'update_ad_campaign_status', 'admin_execute_sql')
    )
ORDER BY routine_name;
