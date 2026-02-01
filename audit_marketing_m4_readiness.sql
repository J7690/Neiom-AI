-- Audit Phase M4 – Analyse algorithmique avancée par post
-- Vérifie la présence des tables de métriques et de la fonction d'explication.

DO $$
DECLARE
  missing text := '';
BEGIN
  -- Tables nécessaires
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'social_posts'
  ) THEN
    missing := missing || 'missing table public.social_posts; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'social_metrics'
  ) THEN
    missing := missing || 'missing table public.social_metrics; ';
  END IF;

  -- Fonction d'analyse algorithmique
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'explain_post_algorithmic_status'
  ) THEN
    missing := missing || 'missing function public.explain_post_algorithmic_status; ';
  END IF;

  IF missing <> '' THEN
    RAISE EXCEPTION 'MARKETING_M4_AUDIT_ERRORS: %', missing;
  END IF;
END;
$$;
