-- Option B: enregistrement de la publication Facebook après appel Edge côté Flutter
create or replace function public.record_facebook_publication_for_prepared_post(
  p_prepared_post_id text,
  p_facebook_post_id text,
  p_facebook_url text
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
  v_rec studio_marketing_recommendations%rowtype;
  v_social_post_id uuid;
  v_existing_social_post_id uuid;
  v_existing_facebook_post_id text;
begin
  -- Récupérer le post préparé
  select * into v_prepared_post
  from studio_facebook_prepared_posts
  where studio_facebook_prepared_posts.id = p_prepared_post_id::uuid;

  if not found then
    return query select false, 'Post préparé introuvable', null::text, null::text;
    return;
  end if;

  -- Vérifier si une publication a déjà été enregistrée pour ce prepared_post
  select
    sp.id,
    (sp.provider_metadata ->> 'facebook_post_id') as existing_facebook_post_id
  into v_existing_social_post_id, v_existing_facebook_post_id
  from public.social_posts sp
  where (sp.provider_metadata ->> 'prepared_post_id')::uuid = v_prepared_post.id
  order by sp.created_at desc
  limit 1;

  if v_existing_social_post_id is not null
     and v_existing_facebook_post_id is not null then
    -- Idempotent: on considère que la publication est déjà enregistrée
    return query select true, 'Publication déjà enregistrée', p_facebook_post_id, p_facebook_url;
    return;
  end if;

  -- Récupérer la recommandation liée
  select * into v_rec
  from studio_marketing_recommendations
  where studio_marketing_recommendations.id = v_prepared_post.recommendation_id;

  -- Mettre à jour le statut du post préparé
  update studio_facebook_prepared_posts
  set status = 'published',
      updated_at = now()
  where id = v_prepared_post.id;

  -- Mettre à jour la recommandation liée si disponible
  if v_rec.id is not null then
    update studio_marketing_recommendations
    set status = 'published',
        published_at = now(),
        published_facebook_id = p_facebook_post_id
    where id = v_rec.id;
  end if;

  -- Créer un social_post pour la supervision globale
  if v_existing_social_post_id is not null then
    update public.social_posts
    set
      status = 'published',
      provider_metadata = coalesce(provider_metadata, '{}'::jsonb) || jsonb_build_object(
        'facebook_post_id', p_facebook_post_id,
        'facebook_url', p_facebook_url,
        'prepared_post_id', v_prepared_post.id,
        'publication_context', v_prepared_post.publication_context
      )
    where id = v_existing_social_post_id
    returning id into v_social_post_id;
  else
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
        'facebook_post_id', p_facebook_post_id,
        'facebook_url', p_facebook_url,
        'prepared_post_id', v_prepared_post.id,
        'publication_context', v_prepared_post.publication_context
      )
    ) returning id into v_social_post_id;
  end if;

  -- Enregistrer un outcome stratégique neutre (sera enrichi plus tard)
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
      'Outcome initial créé automatiquement lors de la publication Facebook (Option B).'
    );
  end if;

  -- Créer un document de connaissance pour ce post Facebook publié (option B)
  perform public.ingest_document(
    'facebook_post',
    coalesce(v_rec.objective, 'Post Facebook Nexiom'),
    'fr',
    v_prepared_post.final_message,
    jsonb_build_object(
      'prepared_post_id', v_prepared_post.id,
      'facebook_post_id', p_facebook_post_id,
      'facebook_url', p_facebook_url,
      'mission_id', v_rec.mission_id,
      'social_post_id', v_social_post_id,
      'publication_context', v_prepared_post.publication_context
    )
  );

  return query
  select true,
         'Publication enregistrée avec succès',
         p_facebook_post_id,
         p_facebook_url;
end;
$$;

grant execute on function public.record_facebook_publication_for_prepared_post(text, text, text) to anon, authenticated;
