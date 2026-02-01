-- Résumé compact des dernières publications Facebook enregistrées
select
  concat_ws('|',
    coalesce(type, ''),
    coalesce(status, ''),
    coalesce(facebook_post_id, ''),
    left(coalesce(facebook_url, ''), 60),
    left(coalesce(error, ''), 60)
  ) as s
from facebook_posts
order by created_at desc
limit 3;
