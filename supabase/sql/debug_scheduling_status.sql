-- Debug: état des content_jobs Facebook planifiés et des schedules associés

-- 1) Nombre de jobs Facebook planifiés et arrivés à échéance
select count(*) as scheduled_fb_jobs_due
from public.content_jobs cj
join public.social_posts sp on sp.id = cj.social_post_id
left join public.social_schedules ss on ss.post_id = sp.id
where cj.status = 'scheduled'
  and cj.channels @> array['facebook']::text[]
  and (cj.metadata->>'prepared_post_id') is not null
  and (cj.metadata->>'scheduled_at')::timestamptz <= now();

-- 2) Échantillon des jobs concernés
select
  cj.id as content_job_id,
  (cj.metadata->>'prepared_post_id') as prepared_post_id,
  (cj.metadata->>'scheduled_at') as scheduled_at,
  cj.status as content_job_status,
  sp.status as social_post_status,
  ss.status as schedule_status
from public.content_jobs cj
join public.social_posts sp on sp.id = cj.social_post_id
left join public.social_schedules ss on ss.post_id = sp.id
where cj.status = 'scheduled'
  and cj.channels @> array['facebook']::text[]
  and (cj.metadata->>'prepared_post_id') is not null
  and (cj.metadata->>'scheduled_at')::timestamptz <= now()
order by (cj.metadata->>'scheduled_at')::timestamptz
limit 20;
