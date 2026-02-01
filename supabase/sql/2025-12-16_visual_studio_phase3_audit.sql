-- Audit Phase 3 – Studio visuel
-- Vérifie la présence des tables et colonnes clés pour l'éditeur visuel.
-- IMPORTANT : aucune modification de schéma, uniquement des SELECT et un éventuel RAISE EXCEPTION.

DO $$
DECLARE
  missing text := '';
BEGIN
  -- Tables requises pour le studio visuel
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'visual_projects'
  ) THEN
    missing := missing || 'missing table public.visual_projects; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'visual_documents'
  ) THEN
    missing := missing || 'missing table public.visual_documents; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'visual_document_versions'
  ) THEN
    missing := missing || 'missing table public.visual_document_versions; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'image_assets'
  ) THEN
    missing := missing || 'missing table public.image_assets; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'generation_jobs'
  ) THEN
    missing := missing || 'missing table public.generation_jobs; ';
  END IF;

  -- Colonnes critiques dans visual_documents
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'visual_documents'
      AND column_name = 'width'
  ) THEN
    missing := missing || 'missing column visual_documents.width; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'visual_documents'
      AND column_name = 'height'
  ) THEN
    missing := missing || 'missing column visual_documents.height; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'visual_documents'
      AND column_name = 'background_color'
  ) THEN
    missing := missing || 'missing column visual_documents.background_color; ';
  END IF;

  -- Colonnes critiques dans visual_document_versions
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'visual_document_versions'
      AND column_name = 'canvas_state'
  ) THEN
    missing := missing || 'missing column visual_document_versions.canvas_state; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'visual_document_versions'
      AND column_name = 'thumbnail_asset_id'
  ) THEN
    missing := missing || 'missing column visual_document_versions.thumbnail_asset_id; ';
  END IF;

  -- Colonnes critiques dans image_assets
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'image_assets'
      AND column_name = 'variant_type'
  ) THEN
    missing := missing || 'missing column image_assets.variant_type; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'image_assets'
      AND column_name = 'storage_path'
  ) THEN
    missing := missing || 'missing column image_assets.storage_path; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'image_assets'
      AND column_name = 'mask_path'
  ) THEN
    missing := missing || 'missing column image_assets.mask_path; ';
  END IF;

  -- Résultat de l'audit
  IF missing <> '' THEN
    RAISE EXCEPTION 'VISUAL_STUDIO_AUDIT_ERRORS: %', missing;
  END IF;
END;
$$;
