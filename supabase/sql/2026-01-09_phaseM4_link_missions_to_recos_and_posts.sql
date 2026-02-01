-- Phase M4 – Lier les missions aux recommandations et aux posts préparés
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseM4_link_missions_to_recos_and_posts.sql

-- 1) Ajouter mission_id sur les recommandations et posts préparés
alter table public.studio_marketing_recommendations
  add column if not exists mission_id uuid
    references public.studio_marketing_missions(id)
    on delete set null;

alter table public.studio_facebook_prepared_posts
  add column if not exists mission_id uuid
    references public.studio_marketing_missions(id)
    on delete set null;

-- 2) Mettre à jour ensure_prepared_post_for_recommendation pour propager mission_id
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
      status,
      mission_id
    ) values (
      v_rec.id,
      coalesce(v_rec.proposed_message, ''),
      null,
      coalesce(v_rec.proposed_format, 'text'),
      false,
      'ready_for_validation',
      v_rec.mission_id
    )
    returning studio_facebook_prepared_posts.* into v_post;
  else
    -- S'assurer que mission_id est aligné avec la recommandation si absent
    if v_post.mission_id is null and v_rec.mission_id is not null then
      update studio_facebook_prepared_posts
      set mission_id = v_rec.mission_id,
          updated_at = now()
      where id = v_post.id;
      select * into v_post
      from studio_facebook_prepared_posts
      where id = v_post.id;
    end if;
  end if;

  return query
  select v_post.id::text, v_post.status, v_post.final_message, v_post.media_url, v_post.media_type;
end;
$$;

-- 3) Mettre à jour approve_marketing_recommendation pour préserver mission_id
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
    -- Mettre à jour le message final et aligner mission_id
    update studio_facebook_prepared_posts
    set final_message = coalesce(v_recommendation.proposed_message, studio_facebook_prepared_posts.final_message),
        mission_id = coalesce(studio_facebook_prepared_posts.mission_id, v_recommendation.mission_id),
        updated_at = now()
    where id = v_prepared_post_id;
  else
    insert into studio_facebook_prepared_posts (
      recommendation_id,
      final_message,
      media_type,
      status,
      mission_id
    ) values (
      v_recommendation.id,
      coalesce(v_recommendation.proposed_message, ''),
      coalesce(v_recommendation.proposed_format, 'text'),
      'ready_for_validation',
      v_recommendation.mission_id
    ) returning studio_facebook_prepared_posts.id into v_prepared_post_id;
  end if;

  return query
  select true, 'Recommandation approuvée avec succès', v_prepared_post_id::text;
end;
$$;
