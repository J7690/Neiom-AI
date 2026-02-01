-- Test Phase M2 – Comité marketing Nexiom
-- Exécuter avec: python tools/admin_sql.py test_marketing_m2_basic.sql

-- 1) Vérifier l'existence de la fonction comité marketing
select 'FUNCTION_EXISTS' as check_type,
       'generate_marketing_committee_recommendation' as function_name,
       exists (
         select 1
         from pg_proc p
         join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public'
           and p.proname = 'generate_marketing_committee_recommendation'
       ) as exists;

-- 2) Appel simple sans paramètre
with payload as (
  select public.generate_marketing_committee_recommendation() as p
)
select 'FUNCTION_PAYLOAD' as check_type,
       p->>'objective' as objective,
       p->>'recommendation' as recommendation,
       p->>'justification' as justification,
       p->>'proposed_post_type' as proposed_post_type,
       p->>'confidence_level' as confidence_level,
       p->>'expected_impact' as expected_impact,
       p->>'risk_or_warning' as risk_or_warning
from payload;
