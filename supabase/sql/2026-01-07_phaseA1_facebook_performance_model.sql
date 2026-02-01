-- Phase A1 – Modélisation de la performance Facebook (NON DESTRUCTIF)
-- Objectif : exposer ce qui marche sur Facebook par type de post et par objectif.

-- 1) Vue agrégée simple sur les posts Facebook récents
--    Basée sur facebook_posts et facebook_comments réels.

create or replace function public.get_facebook_post_performance_overview(
  p_days int default 30
)
returns table (
  type text,
  total_posts bigint,
  published_posts bigint,
  avg_comments_per_post numeric
)
language sql
security definer
set search_path = public
as $$
  with base as (
    select id, type, status, facebook_post_id, created_at
    from facebook_posts
    where created_at >= now() - (p_days || ' days')::interval
  ), comments_per_post as (
    select fp.id as post_uuid,
           count(fc.id)::bigint as comments_count
    from base fp
    left join facebook_comments fc
      on fc.facebook_post_id = fp.facebook_post_id
    group by fp.id
  )
  select
    b.type,
    count(*) as total_posts,
    count(*) filter (where b.status = 'published') as published_posts,
    coalesce(avg(c.comments_count)::numeric, 0) as avg_comments_per_post
  from base b
  left join comments_per_post c on c.post_uuid = b.id
  group by b.type
  order by b.type;
$$;

grant execute on function public.get_facebook_post_performance_overview(int) to anon, authenticated;

-- 2) Synthèse par objectif (notoriété / engagement / conversion) basée
--    sur post_strategy_outcomes et social_posts, filtrée sur le canal Facebook.

create or replace function public.get_objective_performance_summary(
  p_days int default 30
)
returns table (
  objective text,
  total_posts bigint,
  success_count bigint,
  failure_count bigint,
  neutral_count bigint
)
language sql
security definer
set search_path = public
as $$
  select
    coalesce(pso.objective_at_publication, 'unknown') as objective,
    count(*) as total_posts,
    count(*) filter (where pso.verdict = 'success') as success_count,
    count(*) filter (where pso.verdict = 'failure') as failure_count,
    count(*) filter (where pso.verdict = 'neutral') as neutral_count
  from post_strategy_outcomes pso
  join social_posts sp on sp.id = pso.post_id
  where sp.created_at >= now() - (p_days || ' days')::interval
    and 'facebook' = any(sp.target_channels)
  group by coalesce(pso.objective_at_publication, 'unknown')
  order by objective;
$$;

grant execute on function public.get_objective_performance_summary(int) to anon, authenticated;
