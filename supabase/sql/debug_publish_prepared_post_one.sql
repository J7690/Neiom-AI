-- Debug: tester publish_prepared_post sur un seul post préparé

-- 1) Afficher un candidat éventuel
with candidate as (
  select id
  from public.studio_facebook_prepared_posts
  where status in ('ready_for_validation', 'approved')
  order by created_at
  limit 1
)
select 'candidate_prepared_post_id' as label, id::text as value from candidate;

-- 2) Tester publish_prepared_post sur ce candidat (si présent)
with candidate as (
  select id
  from public.studio_facebook_prepared_posts
  where status in ('ready_for_validation', 'approved')
  order by created_at
  limit 1
)
select *
from public.publish_prepared_post((select id::text from candidate));
