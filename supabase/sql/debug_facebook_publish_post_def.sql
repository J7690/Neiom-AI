-- Inspecter la définition actuelle de la fonction facebook_publish_post dans la base
select pg_get_functiondef('facebook_publish_post(text, text, text, text)'::regprocedure) as facebook_publish_post_def;

-- Inspecter aussi publish_prepared_post pour vérifier qu'il correspond au fichier SQL
select pg_get_functiondef('public.publish_prepared_post(text)'::regprocedure) as publish_prepared_post_def;
