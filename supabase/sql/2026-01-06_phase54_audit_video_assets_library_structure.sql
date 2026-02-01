-- Phase 54 – Audit de la table video_assets_library
-- Objectif : vérifier que la table video_assets_library est bien là et lister ses colonnes exactes.

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
  and table_name = 'video_assets_library'
order by ordinal_position;

-- Indexes sur video_assets_library
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'video_assets_library'
order by indexname;

-- Contraintes (PK, FK, CHECK, UNIQUE)
select
  constraint_name,
  constraint_type
from information_schema.table_constraints
where table_schema = 'public'
  and table_name = 'video_assets_library'
order by constraint_name;
