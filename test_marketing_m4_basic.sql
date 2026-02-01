-- Test Phase M4 – Analyse algorithmique avancée par post
-- Exécuter avec: python tools/admin_sql.py test_marketing_m4_basic.sql

-- 1) Vérifier l'existence de la fonction
select 'FUNCTION_EXISTS' as check_type,
       'explain_post_algorithmic_status' as function_name,
       exists (
         select 1
         from pg_proc p
         join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public'
           and p.proname = 'explain_post_algorithmic_status'
       ) as exists;

-- 2) Appel de la fonction pour un post si disponible
DO $$
DECLARE
  v_post_id uuid;
  v_payload jsonb;
BEGIN
  SELECT id INTO v_post_id FROM public.social_posts ORDER BY created_at DESC LIMIT 1;

  IF v_post_id IS NULL THEN
    RAISE NOTICE 'No social_posts available, skipping explain_post_algorithmic_status payload test.';
  ELSE
    SELECT public.explain_post_algorithmic_status(v_post_id) INTO v_payload;
    RAISE NOTICE 'Algorithmic status payload: %', v_payload;
  END IF;
END;
$$;
