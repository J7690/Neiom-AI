-- Phase 39 – Lister les RPC existants (fonctions publiques)
-- Objectif : obtenir la liste exacte des fonctions RPC déjà présentes pour planifier les phases.

select
  routine_name,
  routine_type,
  data_type,
  external_language,
  security_type
from information_schema.routines
where routine_schema = 'public'
  and routine_type = 'FUNCTION'
order by routine_name;
