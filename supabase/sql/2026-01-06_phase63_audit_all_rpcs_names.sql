-- Phase 63 – Lister les noms de toutes les fonctions RPC (publiques) présentes
-- Objectif : avoir la liste exacte des RPC déjà existants pour planifier les phases.

select
  proname,
  prorettype::regtype as return_type,
  prosrc as source
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prokind = 'f'
order by proname;
