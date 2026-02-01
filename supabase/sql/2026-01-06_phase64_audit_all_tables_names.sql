-- Phase 64 – Lister les noms de toutes les tables du schéma public
-- Objectif : avoir la liste exacte des tables déjà existantes pour planifier les phases.

select
  table_name,
  table_type,
  is_insertable_into
from information_schema.tables
where table_schema = 'public'
order by table_name;
