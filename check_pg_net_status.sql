-- Vérifie l'état de pg_net et du schéma net de manière compacte
-- Noms de colonnes très courts pour garder une réponse JSON brève
select
  (select count(*) from pg_available_extensions where name = 'pg_net') as a,
  (select count(*) from pg_extension where extname = 'pg_net') as b,
  (select count(*) from pg_namespace where nspname = 'net') as c,
  (select count(*)
     from pg_proc p
     join pg_namespace n on p.pronamespace = n.oid
    where n.nspname = 'net' and p.proname = 'http_post') as d;
