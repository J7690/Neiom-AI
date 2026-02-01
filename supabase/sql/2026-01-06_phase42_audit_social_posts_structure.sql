-- Phase 42 – Audit de la table social_posts
-- Objectif : vérifier que la table social_posts est bien là et lister ses colonnes exactes.

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
  and table_name = 'social_posts'
order by ordinal_position;

-- Indexes sur social_posts
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'social_posts'
order by indexname;

-- Contraintes (PK, FK, CHECK, UNIQUE)
select
  constraint_name,
  constraint_type
from information_schema.table_constraints
where table_schema = 'public'
  and table_name = 'social_posts'
order by constraint_name;
