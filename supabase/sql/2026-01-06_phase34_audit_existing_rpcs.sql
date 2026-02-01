-- Phase 34 – Audit des RPC déjà existants (fonctions publiques)
-- Objectif : lister les fonctions RPC réellement présentes pour planifier les phases suivantes.

-- Lister les fonctions publiques (celles qu’on peut appeler via .rpc())
select
  proname,
  prorettype::regtype as return_type,
  prosrc as source
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.prokind = 'f'
order by proname;
