-- LEGACY / OUTIL D'ADMIN UNIQUEMENT
-- Ce script sert uniquement à introspecter les signatures des RPC marketing en base.
-- Il n'est pas utilisé par le runtime Nexiom (Edge Functions / Flutter) mais peut être rejoué manuellement via tools/admin_sql.py si besoin.
-- Introspection des signatures des RPC marketing clés
select 'approve_marketing_recommendation' as fn,
       oid::regprocedure as signature,
       proargtypes::regtype[] as arg_types
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'approve_marketing_recommendation';

select 'reject_marketing_recommendation' as fn,
       oid::regprocedure as signature,
       proargtypes::regtype[] as arg_types
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'reject_marketing_recommendation';
