-- Audit Phase M1 – état marketing
-- Vérifie la présence des tables et de la fonction get_marketing_objective_state()

DO $$
DECLARE
  missing text := '';
BEGIN
  -- Table centrale des objectifs marketing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'studio_marketing_objectives'
  ) THEN
    missing := missing || 'missing table public.studio_marketing_objectives; ';
  END IF;

  -- Fonction get_marketing_objective_state()
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'get_marketing_objective_state'
  ) THEN
    missing := missing || 'missing function public.get_marketing_objective_state; ';
  END IF;

  IF missing <> '' THEN
    RAISE EXCEPTION 'MARKETING_STATE_M1_AUDIT_ERRORS: %', missing;
  END IF;
END;
$$;
