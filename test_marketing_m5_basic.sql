-- Test Phase M5 – Mémoire stratégique par post
-- Exécuter avec: python tools/admin_sql.py test_marketing_m5_basic.sql

-- 1) Vérifier l'existence de la table et de la fonction
select 'TABLE_EXISTS' as check_type,
       'post_strategy_outcomes' as name,
       to_regclass('public.post_strategy_outcomes') is not null as exists;

select 'FUNCTION_EXISTS' as check_type,
       'list_post_strategy_lessons' as name,
       exists (
         select 1
         from pg_proc p
         join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public'
           and p.proname = 'list_post_strategy_lessons'
       ) as exists;

-- 2) Insérer un outcome de test si un post existe
DO $$
DECLARE
  v_post_id uuid;
BEGIN
  SELECT id INTO v_post_id FROM public.social_posts ORDER BY created_at DESC LIMIT 1;

  IF v_post_id IS NOT NULL THEN
    INSERT INTO public.post_strategy_outcomes(
      post_id,
      objective_at_publication,
      strategic_role,
      verdict,
      outcome_metrics,
      context_notes
    ) VALUES (
      v_post_id,
      'engagement',
      'educatif',
      'success',
      jsonb_build_object('likes', 10, 'comments', 5, 'shares', 2),
      'Test outcome M5'
    );
  END IF;
END;
$$;

-- 3) Appel de la fonction list_post_strategy_lessons
select 'LESSONS_PAYLOAD' as check_type,
       public.list_post_strategy_lessons('engagement', null, null, 20) as payload;
