-- Audit Nexiom AI Studio Supabase schema (lecture seule)

-- 1) Structure de generation_jobs
select
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name  = 'generation_jobs'
order by ordinal_position;

-- 2) Index sur generation_jobs
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'generation_jobs'
order by indexname;

-- 3) Présence des tables avancées IA vidéo
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'voice_profiles',
    'voice_profile_samples',
    'avatar_profiles',
    'video_assets_library',
    'video_segments',
    'video_briefs',
    'image_assets'
  )
order by table_name;

-- 4) Structure de avatar_profiles (si existe)
select
  'avatar_profiles' as table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name  = 'avatar_profiles'
order by column_name;

-- 5) Structure de video_briefs (si existe)
select
  'video_briefs' as table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
from information_schema.columns
where table_schema = 'public'
  and table_name  = 'video_briefs'
order by column_name;
