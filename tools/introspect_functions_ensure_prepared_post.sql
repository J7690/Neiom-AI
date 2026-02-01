-- 1) Définition réelle des fonctions ensure_prepared_post_for_recommendation*
SELECT
  n.nspname AS schema,
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname ILIKE '%ensure_prepared_post_for_recommendation%';

-- 2) Liste complète des fonctions ensure_prepared_post* tous schémas
SELECT
  n.nspname,
  p.proname,
  p.oid
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname ILIKE '%ensure_prepared_post%';

-- 5) Test direct de la fonction ensure_prepared_post_for_recommendation2
SELECT *
FROM public.ensure_prepared_post_for_recommendation2('00000000-0000-0000-0000-000000000000');
