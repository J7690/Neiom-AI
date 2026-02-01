-- Phase 45 – Audit de la table experiment_variants
-- Objectif : vérifier que la table experiment_variants est bien là et lister ses colonnes exactes.

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
  and table_name = 'experiment_variants'
order by ordinal_position;

-- Indexes sur experiment_variants
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'experiment_variants'
order by indexname;

-- Contraintes (PK, FK, CHECK, UNIQUE)
select
  constraint_name,
  constraint_type
from information_schema.table_constraints
where table_schema = 'public'
  and table_name = 'experiment_variants'
order by constraint_name;
