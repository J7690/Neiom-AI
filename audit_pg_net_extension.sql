-- Audit de l'extension pg_net et du schéma net

-- 1) Extensions disponibles et état d'installation pour pg_net
select 'available_extensions' as section,
       name,
       default_version,
       installed_version,
       comment
from pg_available_extensions
where name = 'pg_net';

-- 2) Extensions effectivement installées
select 'installed_extensions' as section,
       extname,
       extversion
from pg_extension
where extname = 'pg_net';

-- 3) Schéma net présent ou non
select 'net_schema_exists' as section,
       nspname as schema_name
from pg_namespace
where nspname = 'net';

-- 4) Vérifier éventuellement la présence de la fonction net.http_post
select 'net_http_post_signature' as section,
       p.proname,
       pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on p.pronamespace = n.oid
where n.nspname = 'net'
  and p.proname = 'http_post';
