-- Audit SuperBuzz / moteur de timing & planification intelligente Facebook
-- Objectif : vérifier lexistence des fonctions, la présence de données
-- historiques suffisantes et la distribution des créneaux horaires utilisés.

-- 1) Résumé des fonctions de timing disponibles
select 'get_best_facebook_time_for_topic(text,int,int)' as function,
       to_regprocedure('public.get_best_facebook_time_for_topic(text,integer,integer)') as signature;

select 'compute_best_facebook_time_for_prepared_post(text,text,int)' as function,
       to_regprocedure('public.compute_best_facebook_time_for_prepared_post(text,text,integer)') as signature;

select 'schedule_facebook_publication_smart(text,text,int)' as function,
       to_regprocedure('public.schedule_facebook_publication_smart(text,text,integer)') as signature;

select 'get_best_facebook_time_summary(int)' as function,
       to_regprocedure('public.get_best_facebook_time_summary(integer)') as signature;


-- 2) Volume et période des posts Facebook publiés (base pour le calcul des créneaux)
select
  count(*)                            as total_posts,
  min(created_at)                     as first_post_at,
  max(created_at)                     as last_post_at,
  count(*) filter (where status = 'published') as published_posts
from public.facebook_posts;

-- Répartition par jour de la semaine et heure (posts publiés)
select
  extract(dow  from created_at)::int as weekday,
  extract(hour from created_at)::int as hour,
  count(*)                            as posts_count
from public.facebook_posts
where status = 'published'
group by 1,2
order by 1,2;


select *
from public.get_best_facebook_time_for_topic(null, 90, 8);


-- 4) Calendrier actuel des posts Facebook planifiés (social_schedules)
--    Permet de voir à quelles heures réelles tombent les posts "smart".
select
  date(scheduled_at at time zone 'Africa/Ouagadougou')                             as date_local,
  to_char(scheduled_at at time zone 'Africa/Ouagadougou', 'HH24:MI')               as time_local,
  timezone,
  status,
  count(*)                                                                          as items
from public.social_schedules
where scheduled_at >= now() - interval '7 days'
  and scheduled_at <= now() + interval '30 days'
group by 1,2,3,4
order by date_local asc, time_local asc;


-- 5) Détails des prochains posts Facebook planifiés (texte + origine)
select
  ss.id                                   as schedule_id,
  ss.scheduled_at,
  ss.timezone,
  ss.status,
  sp.id                                   as social_post_id,
  sp.status                               as social_post_status,
  left(coalesce(sp.content_text,''), 140) as content_preview,
  sp.provider_metadata
from public.social_schedules ss
join public.social_posts sp on sp.id = ss.post_id
where ss.scheduled_at >= now() - interval '1 day'
  and ss.scheduled_at <= now() + interval '7 days'
order by ss.scheduled_at asc
limit 50;


-- 6) Vérifier le lien entre prepared_posts et social_posts créés par la planification intelligente
select
  s.id                            as social_post_id,
  s.status                        as social_status,
  (s.provider_metadata->>'prepared_post_id')      as prepared_post_id,
  (s.provider_metadata->>'scheduled_at')         as scheduled_at_metadata,
  (s.provider_metadata->>'timezone')             as timezone_metadata
from public.social_posts s
where s.status = 'scheduled'
  and s.provider_metadata ? 'prepared_post_id'
order by (s.provider_metadata->>'scheduled_at')::timestamptz asc
limit 50;


-- 7) Résumé des créneaux déjà utilisés vs créneaux "théoriques" optimaux
--    (permet de voir si lon concentre tout sur un seul créneau comme 01:00)
with best_slots as (
  select weekday, hour
  from public.get_best_facebook_time_for_topic(null, 90, 8)
), used_slots as (
  select
    extract(dow  from scheduled_at at time zone 'Africa/Ouagadougou')::int as weekday,
    extract(hour from scheduled_at at time zone 'Africa/Ouagadougou')::int as hour,
    count(*) as used_count
  from public.social_schedules
  where scheduled_at >= now() - interval '30 days'
  group by 1,2
)
select
  b.weekday,
  b.hour,
  coalesce(u.used_count, 0) as used_last_30_days
from best_slots b
left join used_slots u
  on u.weekday = b.weekday and u.hour = b.hour
order by b.weekday, b.hour;
