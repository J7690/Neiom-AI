-- Audit Phase M2 – Comité marketing Nexiom
-- Vérifie la présence des tables et fonctions clés.

DO $$
DECLARE
  missing text := '';
BEGIN
  -- Tables nécessaires
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'studio_marketing_objectives'
  ) THEN
    missing := missing || 'missing table public.studio_marketing_objectives; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'studio_analysis_cycles'
  ) THEN
    missing := missing || 'missing table public.studio_analysis_cycles; ';
  END IF;

  -- Fonctions de base marketing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'generate_marketing_recommendation'
  ) THEN
    missing := missing || 'missing function public.generate_marketing_recommendation; ';
  END IF;

  -- Fonction comité marketing
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'generate_marketing_committee_recommendation'
  ) THEN
    missing := missing || 'missing function public.generate_marketing_committee_recommendation; ';
  END IF;

  IF missing <> '' THEN
    RAISE EXCEPTION 'MARKETING_M2_AUDIT_ERRORS: %', missing;
  END IF;
END;
$$;
