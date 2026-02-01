-- Phase 58 – Audit de la table voice_profile_samples
-- Objectif : vérifier que la table voice_profile_samples est bien là et lister ses colonnes exactes.

select
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length,
  numeric_precision,
  numeric_scale
from information_schema.columns
where table_schema = 'public'
  and table_name = 'voice_profile_samples'
order by ordinal_position;

-- Indexes sur voice_profile_samples
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'voice_profile_samples'
order by indexname;

-- Contraintes (PK, FK, CHECK, UNIQUE)
select
  constraint_name,
  constraint_type
from information_schema.table_constraints
where table_schema = 'public'
  and table_name = 'voice_profile_samples'
order by constraint_name;
