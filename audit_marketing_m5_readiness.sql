-- Audit Phase M5 – Mémoire stratégique par post
-- Vérifie la présence de la table post_strategy_outcomes et de la RPC list_post_strategy_lessons.

DO $$
DECLARE
  missing text := '';
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'post_strategy_outcomes'
  ) THEN
    missing := missing || 'missing table public.post_strategy_outcomes; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'list_post_strategy_lessons'
  ) THEN
    missing := missing || 'missing function public.list_post_strategy_lessons; ';
  END IF;

  IF missing <> '' THEN
    RAISE EXCEPTION 'MARKETING_M5_AUDIT_ERRORS: %', missing;
  END IF;
END;
$$;
