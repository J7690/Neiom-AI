-- Phase 33 – Audit réel du schéma existant (via admin_execute_sql)
-- Objectif : lister tables, colonnes, fonctions, RPC réellement présents pour planifier les phases suivantes.

-- 1. Lister les tables du schéma public (hors system)
select
  table_name,
  table_type,
  is_insertable_into
from information_schema.tables
where table_schema = 'public'
order by table_name;

-- 2. Lister les colonnes des tables clés
select
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'content_jobs',
    'generation_jobs',
    'social_posts',
    'social_schedules',
    'publish_logs',
    'messages',
    'conversations',
    'contacts',
    'leads',
    'documents',
    'brand_rules',
    'app_settings',
    'experiments',
    'experiment_variants',
    'variant_results',
    'ad_campaigns',
    'campaign_templates',
    'visual_projects',
    'visual_documents',
    'visual_document_versions',
    'image_assets',
    'video_segments',
    'video_assets_library',
    'video_briefs',
    'avatar_profiles',
    'voice_profiles',
    'voice_profile_samples'
  )
order by table_name, ordinal_position;

-- 3. Lister les fonctions (RPC) du schéma public
select
  routine_name,
  routine_type,
  data_type,
  external_language,
  security_type
from information_schema.routines
where routine_schema = 'public'
  and routine_type = 'FUNCTION'
order by routine_name;

-- 4. Lister les triggers (pour info)
select
  trigger_name,
  event_manipulation,
  event_object_table,
  action_timing,
  action_condition,
  action_statement
from information_schema.triggers
where trigger_schema = 'public'
order by trigger_name;
