-- Test Phase M1 – état marketing via get_marketing_objective_state()
-- Exécuter avec: python tools/admin_sql.py test_marketing_state_m1.sql

-- 1) Vérifier l'existence de la fonction
select 'FUNCTION_EXISTS' as check_type,
       'get_marketing_objective_state' as function_name,
       exists (
         select 1
         from pg_proc
         join pg_namespace n on n.oid = pg_proc.pronamespace
         where n.nspname = 'public'
           and proname = 'get_marketing_objective_state'
       ) as exists;

-- 2) Appel simple de la fonction pour vérifier le JSON retourné
select 'FUNCTION_CALL' as check_type,
       get_marketing_objective_state() as state_payload;
