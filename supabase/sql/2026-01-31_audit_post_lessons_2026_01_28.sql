-- Audit – Vérifier s'il existe des leçons (post_strategy_outcomes)
-- pour des posts Facebook publiés le 28/01/2026
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-31_audit_post_lessons_2026_01_28.sql

DO $$
DECLARE
  v_total_outcomes integer := 0;
  v_28_outcomes integer := 0;
BEGIN
  -- Nombre total de leçons enregistrées
  SELECT count(*) INTO v_total_outcomes
  FROM public.post_strategy_outcomes;

  IF v_total_outcomes = 0 THEN
    RAISE EXCEPTION 'NO_LESSONS_ANY: aucune entrée dans post_strategy_outcomes.';
  END IF;

  -- Nombre de leçons pour les posts Facebook du 28/01/2026
  SELECT count(*) INTO v_28_outcomes
  FROM public.post_strategy_outcomes pso
  JOIN public.social_posts sp ON sp.id = pso.post_id
  WHERE sp.created_at::date = DATE '2026-01-28'
    AND 'facebook' = ANY (sp.target_channels);

  IF v_28_outcomes = 0 THEN
    RAISE EXCEPTION 'NO_LESSONS_FOR_2026-01-28: aucune leçon trouvée pour les posts Facebook du 28/01/2026.';
  END IF;
END;
$$;
