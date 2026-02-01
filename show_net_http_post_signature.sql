-- Crée une fonction RPC de debug pour lister les signatures de net.http_post
create or replace function debug_net_http_post_signatures()
returns table(schema_name text, proname text, args text)
language sql
security definer
as $$
  select
    n.nspname as schema_name,
    p.proname,
    pg_get_function_identity_arguments(p.oid) as args
  from pg_proc p
  join pg_namespace n on p.pronamespace = n.oid
  where n.nspname = 'net'
    and p.proname = 'http_post';
$$;

grant execute on function debug_net_http_post_signatures() to authenticated, anon;
