-- Phase 48 – Audit de la table campaign_templates
-- Objectif : vérifier que la table campaign_templates est bien là et lister ses colonnes exactes.

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
  and table_name = 'campaign_templates'
order by ordinal_position;

-- Indexes sur campaign_templates
select
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'campaign_templates'
order by indexname;

-- Contraintes (PK, FK, CHECK, UNIQUE)
select
  constraint_name,
  constraint_type
from information_schema.table_constraints
where table_schema = 'public'
  and table_name = 'campaign_templates'
order by constraint_name;
