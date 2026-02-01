-- Phase FB – Enrichissement des insights et mise à jour des outcomes
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-31_phaseFB_insights_entity_and_outcomes.sql
-- Non destructif : ajoute des colonnes et une fonction de rafraîchissement

-- 1) Ajouter un lien générique vers l'entité (page ou post) dans facebook_insights
alter table public.facebook_insights
  add column if not exists entity_type text,
  add column if not exists entity_id text;

create index if not exists facebook_insights_entity_idx
  on public.facebook_insights(entity_type, entity_id);

-- 2) Fonction pour rafraîchir outcome_metrics de post_strategy_outcomes
--    à partir des insights de posts Facebook stockés dans facebook_insights

create or replace function public.refresh_post_outcomes_from_insights(
  p_days integer default 30
)
returns integer
language plpgsql
security definer
set search_path = public as
$$
declare
  v_updated integer := 0;
begin
  -- Mettre à jour outcome_metrics pour les posts Facebook récents
  update public.post_strategy_outcomes pso
  set outcome_metrics = coalesce(pso.outcome_metrics, '{}'::jsonb) || jsonb_build_object(
        'impressions', metrics.impressions,
        'reach', metrics.reach,
        'engagements', metrics.engagements,
        'likes', metrics.likes,
        'comments', metrics.comments,
        'shares', metrics.shares,
        'video_views', metrics.video_views
      )
  from (
    select
      sp.id as social_post_id,
      max(case when fi.metric_name = 'post_impressions' then fi.value end) as impressions,
      max(case when fi.metric_name = 'post_reach' then fi.value end) as reach,
      max(case when fi.metric_name = 'post_engaged_users' then fi.value end) as engagements,
      max(case when fi.metric_name = 'post_reactions_total' then fi.value end) as likes,
      max(case when fi.metric_name = 'post_comments' then fi.value end) as comments,
      max(case when fi.metric_name = 'post_shares' then fi.value end) as shares,
      max(case when fi.metric_name = 'post_video_views' then fi.value end) as video_views
    from public.social_posts sp
    join public.post_strategy_outcomes pso2 on pso2.post_id = sp.id
    join public.facebook_insights fi
      on fi.entity_type = 'post'
     and fi.entity_id = (sp.provider_metadata ->> 'facebook_post_id')
    where sp.created_at >= now() - (p_days || ' days')::interval
    group by sp.id
  ) as metrics
  where pso.post_id = metrics.social_post_id;

  get diagnostics v_updated = row_count;

  return v_updated;
end;
$$;

grant execute on function public.refresh_post_outcomes_from_insights(integer) to authenticated;
