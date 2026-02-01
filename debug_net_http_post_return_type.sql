-- Crée une fonction RPC de debug pour lister les colonnes du type de retour de net.http_post
create or replace function debug_net_http_post_return_type()
returns table(attname text, atttype text)
language sql
security definer
as $$
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
  and not attisdropped
  order by attnum;
$$;

grant execute on function debug_net_http_post_return_type() to authenticated, anon;
