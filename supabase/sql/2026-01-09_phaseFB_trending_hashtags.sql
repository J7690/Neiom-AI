-- Phase FB – Hashtags tendance basés sur les performances réelles Facebook
-- Objectif : exposer les hashtags qui ont le mieux performé récemment sur la page,
-- pour aider le cerveau marketing à choisir des hashtags alignés avec le thème.
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseFB_trending_hashtags.sql

create or replace function public.get_best_hashtags_for_topic(
  p_topic text default null,
  p_limit integer default 20,
  p_days integer default 90
)
returns table (
  hashtag text,
  score numeric,
  posts_count integer
)
language sql
security definer
set search_path = public
as $$
  with recent_posts as (
    select fp.id, fp.message, fp.facebook_post_id, fp.created_at
    from public.facebook_posts fp
    where fp.status = 'published'
      and fp.created_at >= now() - (p_days || ' days')::interval
      and (p_topic is null or fp.message ilike '%' || p_topic || '%')
  ), insights_by_day as (
    select
      date_trunc('day', fi.end_time) as day,
      sum(coalesce(fi.value, 0)) as impressions
    from public.facebook_insights fi
    where fi.end_time >= now() - (p_days || ' days')::interval
      and fi.metric_name in (
        'page_impressions',
        'page_impressions_unique',
        'post_impressions',
        'post_impressions_unique',
        'reach',
        'post_reach'
      )
    group by date_trunc('day', fi.end_time)
  ), insights_stats as (
    select coalesce(max(impressions), 1)::numeric as max_impressions
    from insights_by_day
  ), metrics as (
    select
      rp.id as post_id,
      coalesce(count(fc.id), 0)::numeric as comments_count,
      coalesce(sum(fc.like_count), 0)::numeric as likes_sum,
      coalesce(ibd.impressions, 0)::numeric as day_impressions
    from recent_posts rp
    left join public.facebook_comments fc
      on fc.facebook_post_id = rp.facebook_post_id
    left join insights_by_day ibd
      on date_trunc('day', rp.created_at) = ibd.day
    group by rp.id, ibd.impressions
  ), tags as (
    select
      lower(tag) as hashtag,
      sum(
        m.comments_count
        + m.likes_sum * 0.5
        + (m.day_impressions / s.max_impressions) * 5
      ) as score,
      count(distinct m.post_id) as posts_count
    from (
      select
        rp.id as post_id,
        unnest(regexp_matches(rp.message, '#[A-Za-z0-9_]+', 'g')) as tag
      from recent_posts rp
    ) t
    join metrics m on m.post_id = t.post_id
    cross join insights_stats s
    group by lower(tag)
  )
  select hashtag, score, posts_count
  from tags
  where hashtag is not null and hashtag <> ''
  order by score desc, posts_count desc, hashtag asc
  limit p_limit;
$$;

grant execute on function public.get_best_hashtags_for_topic(text, integer, integer) to anon, authenticated;
