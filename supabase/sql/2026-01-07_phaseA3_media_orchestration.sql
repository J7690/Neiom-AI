-- Phase A3 – Orchestration des médias IA pour les recommandations marketing
-- Objectif : permettre au Studio Marketing Décisionnel de générer des médias IA
-- (image/vidéo) pour une recommandation et de les attacher au post préparé.

-- 1) Fonction utilitaire : obtenir ou créer un studio_facebook_prepared_posts
--    pour une recommandation donnée.

create or replace function public.ensure_prepared_post_for_recommendation(
  p_recommendation_id text
)
returns table (
  id text,
  status text,
  final_message text,
  media_url text,
  media_type text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rec studio_marketing_recommendations%rowtype;
  v_post studio_facebook_prepared_posts%rowtype;
begin
  select * into v_rec
  from studio_marketing_recommendations
  where studio_marketing_recommendations.id = p_recommendation_id::uuid;

  if not found then
    raise exception 'studio_marketing_recommendations not found for id %', p_recommendation_id;
  end if;

  select * into v_post
  from studio_facebook_prepared_posts
  where studio_facebook_prepared_posts.recommendation_id = v_rec.id
  order by studio_facebook_prepared_posts.created_at desc
  limit 1;

  if not found then
    insert into studio_facebook_prepared_posts (
      recommendation_id,
      final_message,
      media_url,
      media_type,
      media_generated,
      status
    ) values (
      v_rec.id,
      coalesce(v_rec.proposed_message, ''),
      null,
      coalesce(v_rec.proposed_format, 'text'),
      false,
      'ready_for_validation'
    )
    returning studio_facebook_prepared_posts.* into v_post;
  end if;

  return query
  select v_post.id::text, v_post.status, v_post.final_message, v_post.media_url, v_post.media_type;
end;
$$;

grant execute on function public.ensure_prepared_post_for_recommendation(text) to anon, authenticated;

-- 2) Fonction pour attacher un média IA à un prepared_post existant.

create or replace function public.attach_media_to_prepared_post(
  p_prepared_post_id text,
  p_media_url text,
  p_media_type text
)
returns table (
  success boolean,
  message text,
  media_url text,
  media_type text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := p_prepared_post_id::uuid;
begin
  update studio_facebook_prepared_posts
  set media_url = p_media_url,
      media_type = p_media_type,
      media_generated = true,
      updated_at = now()
  where studio_facebook_prepared_posts.id = v_id;

  if not found then
    return query select false, 'Prepared post not found', null::text, null::text;
    return;
  end if;

  return query
  select true, 'Media attached', studio_facebook_prepared_posts.media_url, studio_facebook_prepared_posts.media_type
  from studio_facebook_prepared_posts
  where studio_facebook_prepared_posts.id = v_id;
end;
$$;

grant execute on function public.attach_media_to_prepared_post(text, text, text) to anon, authenticated;

-- 3) Mise à jour de approve_marketing_recommendation pour réutiliser
--    un prepared_post existant le cas échéant.

create or replace function public.approve_marketing_recommendation(
  p_recommendation_id text,
  p_approved_by text default 'studio_admin'
)
returns table (
  success boolean,
  message text,
  prepared_post_id text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recommendation studio_marketing_recommendations%rowtype;
  v_prepared studio_facebook_prepared_posts%rowtype;
  v_prepared_post_id uuid;
begin
  -- Récupérer la recommandation en attente
  select * into v_recommendation
  from studio_marketing_recommendations
  where studio_marketing_recommendations.id = p_recommendation_id::uuid
    and studio_marketing_recommendations.status = 'pending';

  if not found then
    return query select false, 'Recommandation non trouvée ou déjà traitée', null::text;
    return;
  end if;

  -- Mettre à jour le statut de la recommandation
  update studio_marketing_recommendations
  set status = 'approved',
      approved_at = now(),
      approved_by = p_approved_by
  where studio_marketing_recommendations.id = v_recommendation.id;

  -- Réutiliser un prepared_post existant si possible
  select * into v_prepared
  from studio_facebook_prepared_posts
  where studio_facebook_prepared_posts.recommendation_id = v_recommendation.id
  order by studio_facebook_prepared_posts.created_at desc
  limit 1;

  if found then
    v_prepared_post_id := v_prepared.id;
    -- Mettre à jour le message final sans toucher au média déjà généré
    update studio_facebook_prepared_posts
    set final_message = coalesce(v_recommendation.proposed_message, studio_facebook_prepared_posts.final_message),
        updated_at = now()
    where id = v_prepared_post_id;
  else
    insert into studio_facebook_prepared_posts (
      recommendation_id,
      final_message,
      media_type,
      status
    ) values (
      v_recommendation.id,
      coalesce(v_recommendation.proposed_message, ''),
      coalesce(v_recommendation.proposed_format, 'text'),
      'ready_for_validation'
    ) returning studio_facebook_prepared_posts.id into v_prepared_post_id;
  end if;

  return query
  select true, 'Recommandation approuvée avec succès', v_prepared_post_id::text;
end;
$$;

grant execute on function public.approve_marketing_recommendation(text, text) to anon, authenticated;
