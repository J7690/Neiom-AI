-- Phase FB – Hashtags automatiques pour les recommandations et posts Facebook
-- Objectif : stocker des hashtags structurés et les injecter automatiquement
-- dans les publications Facebook, sans intervention humaine autre que la validation.
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseFB_hashtags.sql

-- 1) Étendre les tables marketing avec une colonne de hashtags structurés
alter table public.studio_marketing_recommendations
  add column if not exists hashtags text[];

alter table public.studio_facebook_prepared_posts
  add column if not exists hashtags text[];

-- 2) Mettre à jour ensure_prepared_post_for_recommendation pour propager mission_id et hashtags

-- Supprimer l'ancienne version (nécessaire car le RETURN TABLE change)
drop function if exists public.ensure_prepared_post_for_recommendation(text);

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
      mission_id,
      hashtags
    ) values (
      v_rec.id,
      coalesce(v_rec.proposed_message, ''),
      null,
      coalesce(v_rec.proposed_format, 'text'),
      false,
      'ready_for_validation',
      v_rec.mission_id,
      v_rec.hashtags
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

    -- Propager les hashtags de la recommandation si le post préparé n'en a pas
    if v_post.hashtags is null and v_rec.hashtags is not null then
      update studio_facebook_prepared_posts
      set hashtags = v_rec.hashtags,
          updated_at = now()
      where id = v_post.id;
      select * into v_post
      from studio_facebook_prepared_posts
      where id = v_post.id;
    end if;
  end if;

  return query
  select
    v_post.id::text,
    v_post.status,
    v_post.final_message,
    v_post.media_url,
    v_post.media_type;
end;
$$;

grant execute on function public.ensure_prepared_post_for_recommendation(text) to anon, authenticated;

-- 3) Mettre à jour approve_marketing_recommendation pour préserver mission_id et hashtags
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
    -- Mettre à jour le message final, mission_id et hashtags
    update studio_facebook_prepared_posts
    set final_message = coalesce(v_recommendation.proposed_message, studio_facebook_prepared_posts.final_message),
        mission_id = coalesce(studio_facebook_prepared_posts.mission_id, v_recommendation.mission_id),
        hashtags = coalesce(studio_facebook_prepared_posts.hashtags, v_recommendation.hashtags),
        updated_at = now()
    where id = v_prepared_post_id;
  else
    insert into studio_facebook_prepared_posts (
      recommendation_id,
      final_message,
      media_type,
      status,
      mission_id,
      hashtags
    ) values (
      v_recommendation.id,
      coalesce(v_recommendation.proposed_message, ''),
      coalesce(v_recommendation.proposed_format, 'text'),
      'ready_for_validation',
      v_recommendation.mission_id,
      v_recommendation.hashtags
    ) returning studio_facebook_prepared_posts.id into v_prepared_post_id;
  end if;

  return query
  select true, 'Recommandation approuvée avec succès', v_prepared_post_id::text;
end;
$$;

grant execute on function public.approve_marketing_recommendation(text,text) to anon, authenticated;

-- 4) Mettre à jour publish_prepared_post pour injecter les hashtags dans le message publié
create or replace function public.publish_prepared_post(
  p_prepared_post_id text
)
returns table (
  success boolean,
  message text,
  facebook_post_id text,
  facebook_url text
)
language plpgsql
security definer
set search_path = public as
$$
declare
  v_prepared_post studio_facebook_prepared_posts%rowtype;
  v_facebook_result record;
  v_rec studio_marketing_recommendations%rowtype;
  v_social_post_id uuid;
  v_fb_enabled boolean := true;
  v_cfg record;
  v_final_message text;
begin
  -- Récupérer le post préparé en statut prêt ou approuvé
  select * into v_prepared_post
  from studio_facebook_prepared_posts
  where studio_facebook_prepared_posts.id = p_prepared_post_id::uuid
    and studio_facebook_prepared_posts.status in ('ready_for_validation', 'approved');

  if not found then
    return query select false, 'Post non trouvé ou non prêt', null::text, null::text;
    return;
  end if;

  -- Lire la configuration de gouvernance (si présente)
  select facebook_publishing_enabled
  into v_cfg
  from public.ai_orchestration_settings
  where public.ai_orchestration_settings.id = 'default';

  if found then
    v_fb_enabled := coalesce(v_cfg.facebook_publishing_enabled, true);
  end if;

  if not v_fb_enabled then
    return query select false,
      'Publication Facebook désactivée par l''administrateur',
      null::text,
      null::text;
    return;
  end if;

  -- Récupérer la recommandation liée (peut servir pour l'objectif)
  select * into v_rec
  from studio_marketing_recommendations
  where studio_marketing_recommendations.id = v_prepared_post.recommendation_id;

  -- Construire le message final en injectant les hashtags structurés
  v_final_message := v_prepared_post.final_message;

  if v_prepared_post.hashtags is not null
     and cardinality(v_prepared_post.hashtags) > 0 then
    v_final_message := trim(
      both ' ' from coalesce(v_final_message, '') || ' ' || array_to_string(v_prepared_post.hashtags, ' ')
    );
  end if;

  -- Ajouter une signature Nexiom AI Studio pour la traçabilité des posts
  v_final_message := trim(both ' ' from coalesce(v_final_message, '')) ||
    E'\n\nPost réalisé par le studio Nexiom AI, développé par Nexiom Group.';

  -- Appeler la RPC Facebook réelle (wrapper vers Edge / Meta)
  select * into v_facebook_result
  from facebook_publish_post(
    v_prepared_post.media_type,
    v_final_message,
    case when v_prepared_post.media_type = 'image' then v_prepared_post.media_url else null end,
    case when v_prepared_post.media_type = 'video' then v_prepared_post.media_url else null end
  );

  if v_facebook_result.id is not null then
    -- Mettre à jour le statut du post préparé et synchroniser le message final
    update studio_facebook_prepared_posts
    set status = 'published',
        final_message = v_final_message,
        updated_at = now()
    where id = v_prepared_post.id;

    -- Mettre à jour la recommandation liée
    if v_rec.id is not null then
      update studio_marketing_recommendations
      set status = 'published',
          published_at = now(),
          published_facebook_id = v_facebook_result.post_id
      where id = v_rec.id;
    end if;

    -- Créer un social_post pour la supervision globale
    insert into public.social_posts(
      author_agent,
      objective,
      content_text,
      media_paths,
      target_channels,
      status,
      provider_metadata
    ) values (
      coalesce(v_rec.approved_by, 'marketing_brain'),
      coalesce(v_rec.objective, 'marketing'),
      v_final_message,
      case when v_prepared_post.media_url is not null then array[v_prepared_post.media_url] else '{}'::text[] end,
      array['facebook'],
      'published',
      jsonb_build_object(
        'facebook_post_id', v_facebook_result.post_id,
        'facebook_url', v_facebook_result.url,
        'prepared_post_id', v_prepared_post.id,
        'hashtags', v_prepared_post.hashtags
      )
    ) returning id into v_social_post_id;

    -- Enregistrer un outcome stratégique neutre (sera enrichi par les métriques plus tard)
    if v_social_post_id is not null then
      insert into public.post_strategy_outcomes (
        post_id,
        objective_at_publication,
        strategic_role,
        recommendation_id,
        verdict,
        outcome_metrics,
        context_notes
      ) values (
        v_social_post_id,
        coalesce(v_rec.objective, 'marketing'),
        'facebook_primary_post',
        v_rec.id,
        'neutral',
        '{}'::jsonb,
        'Outcome initial créé automatiquement lors de la publication Facebook (avec hashtags automatiques).'
      );
    end if;

    -- Créer un document de connaissance pour ce post Facebook publié
    perform public.ingest_document(
      'facebook_post',
      coalesce(v_rec.objective, 'Post Facebook Nexiom'),
      'fr',
      v_final_message,
      jsonb_build_object(
        'prepared_post_id', v_prepared_post.id,
        'facebook_post_id', v_facebook_result.post_id,
        'facebook_url', v_facebook_result.url,
        'mission_id', v_rec.mission_id,
        'social_post_id', v_social_post_id
      )
    );

    return query
    select true,
           'Publication réussie',
           v_facebook_result.post_id::text,
           v_facebook_result.url::text;
  else
    return query
    select false, 'Échec de publication Facebook', null::text, null::text;
  end if;
end;
$$;

grant execute on function public.publish_prepared_post(text) to anon, authenticated;
