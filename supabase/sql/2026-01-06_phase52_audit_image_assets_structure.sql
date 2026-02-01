-- Phase 52 – Audit de la table image_assets
-- Objectif : vérifier que la table image_assets est bien là et lister ses colonnes exactes.

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
  and table_name = 'image_assets'
order by ordinal_position;

-- Indexes sur image_assets
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'image_assets'
order by indexname;

-- Contraintes (PK, FK, CHECK, UNIQUE)
select
  constraint_name,
  constraint_type
from information_schema.table_constraints
where table_schema = 'public'
  and table_name = 'image_assets'
order by constraint_name;
