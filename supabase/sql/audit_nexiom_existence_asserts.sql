-- Audit asserts for Nexiom AI Studio Supabase schema
-- This script RAISE EXCEPTION if expected objects are missing.

DO $$
DECLARE
  missing text[] := array[]::text[];
BEGIN
  -- 1) Core tables expected by schema.sql
  IF to_regclass('public.generation_jobs') IS NULL THEN
    missing := array_append(missing, 'table public.generation_jobs');
  END IF;

  IF to_regclass('public.image_assets') IS NULL THEN
    missing := array_append(missing, 'table public.image_assets');
  END IF;

  IF to_regclass('public.voice_profiles') IS NULL THEN
    missing := array_append(missing, 'table public.voice_profiles');
  END IF;

  IF to_regclass('public.text_templates') IS NULL THEN
    missing := array_append(missing, 'table public.text_templates');
  END IF;

  IF to_regclass('public.visual_projects') IS NULL THEN
    missing := array_append(missing, 'table public.visual_projects');
  END IF;

  IF to_regclass('public.visual_documents') IS NULL THEN
    missing := array_append(missing, 'table public.visual_documents');
  END IF;

  IF to_regclass('public.visual_document_versions') IS NULL THEN
    missing := array_append(missing, 'table public.visual_document_versions');
  END IF;

  -- 2) Advanced video/image tables expected by fix_nexiom_video_schema.sql
  IF to_regclass('public.avatar_profiles') IS NULL THEN
    missing := array_append(missing, 'table public.avatar_profiles');
  END IF;

  IF to_regclass('public.voice_profile_samples') IS NULL THEN
    missing := array_append(missing, 'table public.voice_profile_samples');
  END IF;

  IF to_regclass('public.video_assets_library') IS NULL THEN
    missing := array_append(missing, 'table public.video_assets_library');
  END IF;

  IF to_regclass('public.video_segments') IS NULL THEN
    missing := array_append(missing, 'table public.video_segments');
  END IF;

  IF to_regclass('public.video_briefs') IS NULL THEN
    missing := array_append(missing, 'table public.video_briefs');
  END IF;

  -- 3) Critical columns on generation_jobs
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name  = 'generation_jobs'
      AND column_name = 'provider'
  ) THEN
    missing := array_append(missing, 'column public.generation_jobs.provider');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name  = 'generation_jobs'
      AND column_name = 'provider_job_id'
  ) THEN
    missing := array_append(missing, 'column public.generation_jobs.provider_job_id');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name  = 'generation_jobs'
      AND column_name = 'quality_tier'
  ) THEN
    missing := array_append(missing, 'column public.generation_jobs.quality_tier');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name  = 'generation_jobs'
      AND column_name = 'provider_metadata'
  ) THEN
    missing := array_append(missing, 'column public.generation_jobs.provider_metadata');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name  = 'generation_jobs'
      AND column_name = 'video_brief_id'
  ) THEN
    missing := array_append(missing, 'column public.generation_jobs.video_brief_id');
  END IF;

  -- 4) Key RPC functions expected by schema & migrations
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'get_generation_job'
  ) THEN
    missing := array_append(missing, 'function public.get_generation_job(uuid)');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'set_setting'
  ) THEN
    missing := array_append(missing, 'function public.set_setting(text,text)');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'get_setting'
  ) THEN
    missing := array_append(missing, 'function public.get_setting(text)');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'settings_overview'
  ) THEN
    missing := array_append(missing, 'function public.settings_overview()');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'admin_execute_sql'
  ) THEN
    missing := array_append(missing, 'function public.admin_execute_sql(text)');
  END IF;

  -- 5) Final assertion
  IF coalesce(array_length(missing, 1), 0) > 0 THEN
    RAISE EXCEPTION 'NEXIOM_SCHEMA_MISMATCH: missing: %', array_to_string(missing, ', ');
  END IF;
END;
$$;
