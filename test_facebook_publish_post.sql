-- Test direct de la fonction facebook_publish_post via SQL
select *
from facebook_publish_post(
  'TEXT',
  'Test publication Facebook depuis SQL (pg_net activé)',
  null,
  null
);
