-- Phase A4 – Boucle publication → performance → mémoire stratégique
-- Objectif : à chaque publication réussie via publish_prepared_post,
-- créer un social_post réel et une entrée dans post_strategy_outcomes.

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
set search_path = public
as $$
declare
  v_prepared_post studio_facebook_prepared_posts%rowtype;
  v_rec studio_marketing_recommendations%rowtype;
  v_social_post_id uuid;
  v_facebook_post_id text;
  v_facebook_url text;
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

  -- Récupérer la recommandation liée (peut servir pour l'objectif)
  select * into v_rec
  from studio_marketing_recommendations
  where studio_marketing_recommendations.id = v_prepared_post.recommendation_id;

  -- Générer des identifiants Facebook factices (stub interne) pour représenter la publication
  v_facebook_post_id := 'fb_' || gen_random_uuid()::text;
  v_facebook_url := 'https://facebook.com/' || v_facebook_post_id;

  if v_facebook_post_id is not null then
    -- Mettre à jour le statut du post préparé
    update studio_facebook_prepared_posts
    set status = 'published',
        updated_at = now()
    where id = v_prepared_post.id;

    -- Mettre à jour la recommandation liée
    if v_rec.id is not null then
      update studio_marketing_recommendations
      set status = 'published',
          published_at = now(),
          published_facebook_id = v_facebook_post_id
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
      v_prepared_post.final_message,
      case when v_prepared_post.media_url is not null then array[v_prepared_post.media_url] else '{}'::text[] end,
      array['facebook'],
      'published',
      jsonb_build_object(
        'facebook_post_id', v_facebook_post_id,
        'facebook_url', v_facebook_url,
        'prepared_post_id', v_prepared_post.id
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
        'Outcome initial créé automatiquement lors de la publication Facebook.'
      );
    end if;

    return query
    select true,
           'Publication réussie',
           v_facebook_post_id::text,
           v_facebook_url::text;
  else
    return query
    select false, 'Échec de publication Facebook', null::text, null::text;
  end if;
end;
$$;

grant execute on function public.publish_prepared_post(text) to anon, authenticated;
