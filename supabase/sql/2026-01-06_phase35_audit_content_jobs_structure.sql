-- Phase 35 – Audit de la table content_jobs (colonnes, indexes, contraintes)
-- Objectif : vérifier que la table content_jobs est bien là et lister ses colonnes exactes.

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
  and table_name = 'content_jobs'
order by ordinal_position;

-- Indexes sur content_jobs
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'content_jobs'
order by indexname;

-- Contraintes (PK, FK, CHECK, UNIQUE)
select
  constraint_name,
  constraint_type,
  check_clause
from information_schema.table_constraints
where table_schema = 'public'
  and table_name = 'content_jobs'
order by constraint_name;
