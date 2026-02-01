-- Inspecte le type de retour de net.http_post
select
  p.proretset,
  t.typname,
  t.typtype,
  t.typrelid
from pg_proc p
join pg_namespace n on p.pronamespace = n.oid
join pg_type t on p.prorettype = t.oid
where n.nspname = 'net'
  and p.proname = 'http_post';

-- Si typrelid > 0, lister les colonnes du type composite
select
  attname,
  format_type(atttypid, atttypmod) as atttype
from pg_attribute
where attrelid = (
  select t.typrelid
  from pg_proc p
  join pg_namespace n on p.pronamespace = n.oid
  join pg_type t on p.prorettype = t.oid
  where n.nspname = 'net'
    and p.proname = 'http_post'
)
and attnum > 0
and not attisdropped;
