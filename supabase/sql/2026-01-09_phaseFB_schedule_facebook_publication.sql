-- Phase FB – Planification avancée des publications Facebook
-- Objectif : planifier un studio_facebook_prepared_posts pour publication ultérieure
-- en créant un content_job + social_post + social_schedule et en fournissant
-- un orchestrateur dédié qui appelle publish_prepared_post au moment voulu.

create or replace function public.schedule_facebook_publication(
  p_prepared_post_id text,
  p_scheduled_at timestamptz,
  p_timezone text default 'UTC'
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_prepared_post studio_facebook_prepared_posts%rowtype;
  v_rec studio_marketing_recommendations%rowtype;
  v_social_post_id uuid;
  v_schedule_id uuid;
  v_content_job_id uuid;
  v_objective text;
  v_author text;
  v_media_paths text[];
  v_fb_enabled boolean := true;
  v_cfg record;
begin
  if p_prepared_post_id is null then
    raise exception 'p_prepared_post_id is required';
  end if;

  if p_scheduled_at is null then
    raise exception 'p_scheduled_at is required';
  end if;

  -- Récupérer le post préparé
  select * into v_prepared_post
  from studio_facebook_prepared_posts
  where studio_facebook_prepared_posts.id = p_prepared_post_id::uuid
    and studio_facebook_prepared_posts.status in ('ready_for_validation', 'approved');

  if not found then
    raise exception 'Prepared post not found or not in a schedulable status';
  end if;

  -- Récupérer la recommandation liée (pour objectif/auteur)
  select * into v_rec
  from studio_marketing_recommendations
  where studio_marketing_recommendations.id = v_prepared_post.recommendation_id;

  v_objective := coalesce(v_rec.objective, 'marketing');
  v_author := coalesce(v_rec.approved_by, 'marketing_brain');

  if v_prepared_post.media_url is not null then
    v_media_paths := array[v_prepared_post.media_url];
  else
    v_media_paths := '{}'::text[];
  end if;

  -- Vérifier la configuration de gouvernance (si présente)
  begin
    select facebook_publishing_enabled
    into v_cfg
    from public.ai_orchestration_settings
    where public.ai_orchestration_settings.id = 'default';

    if found then
      v_fb_enabled := coalesce(v_cfg.facebook_publishing_enabled, true);
    end if;
  exception when others then
    -- En cas d'erreur de lecture de la config, on reste sur true (comportement permissif)
    v_fb_enabled := true;
  end;

  if not v_fb_enabled then
    raise exception 'Facebook publishing disabled by administrator';
  end if;

  -- Créer un social_post en statut "scheduled" pour visibilité globale
  insert into public.social_posts(
    author_agent,
    objective,
    content_text,
    media_paths,
    target_channels,
    status,
    provider_metadata
  ) values (
    v_author,
    v_objective,
    v_prepared_post.final_message,
    v_media_paths,
    array['facebook'],
    'scheduled',
    jsonb_build_object(
      'prepared_post_id', v_prepared_post.id,
      'scheduled_at', p_scheduled_at,
      'timezone', p_timezone
    )
  ) returning id into v_social_post_id;

  -- Créer un social_schedule associé
  insert into public.social_schedules(
    post_id,
    scheduled_at,
    timezone,
    status
  ) values (
    v_social_post_id,
    p_scheduled_at,
    p_timezone,
    'scheduled'
  ) returning id into v_schedule_id;

  -- Créer un content_job qui référence le prepared_post, la mission (si présente) et le social_post
  insert into public.content_jobs(
    title,
    objective,
    format,
    channels,
    origin_ui,
    status,
    author_agent,
    mission_id,
    social_post_id,
    metadata
  ) values (
    substring(coalesce(v_prepared_post.final_message, '') for 120),
    v_objective,
    coalesce(v_prepared_post.media_type, 'text'),
    array['facebook'],
    'facebook_studio',
    'scheduled',
    v_author,
    v_prepared_post.mission_id,
    v_social_post_id,
    jsonb_build_object(
      'prepared_post_id', v_prepared_post.id,
      'schedule_id', v_schedule_id,
      'scheduled_at', p_scheduled_at,
      'timezone', p_timezone
    )
  ) returning id into v_content_job_id;

  return jsonb_build_object(
    'content_job_id', v_content_job_id,
    'social_post_id', v_social_post_id,
    'schedule_id', v_schedule_id,
    'scheduled_at', p_scheduled_at,
    'timezone', p_timezone,
    'prepared_post_id', v_prepared_post.id::text
  );
end;
$$;

revoke all on function public.schedule_facebook_publication(text,timestamptz,text) from public;
grant execute on function public.schedule_facebook_publication(text,timestamptz,text) to anon, authenticated;


-- Orchestrateur dédié : exécuter les plannings Facebook en appelant publish_prepared_post

create or replace function public.run_facebook_schedules_once()
returns integer
language plpgsql
security definer
set search_path = public as
$$
declare
  v_count integer := 0;
  rec record;
  v_res record;
  v_success boolean;
  v_post_id text;
  v_url text;
begin
  -- Sélectionner un seul job Facebook planifié et arrivé à échéance (le plus ancien)
  select
    cj.id as content_job_id,
    (cj.metadata->>'prepared_post_id')::uuid as prepared_post_id,
    (cj.metadata->>'scheduled_at')::timestamptz as scheduled_at,
    sp.id as social_post_id,
    ss.id as schedule_id
  into rec
  from public.content_jobs cj
  join public.social_posts sp on sp.id = cj.social_post_id
  left join public.social_schedules ss on ss.post_id = sp.id
  where cj.status = 'scheduled'
    and cj.channels @> array['facebook']::text[]
    and (cj.metadata->>'prepared_post_id') is not null
    and (cj.metadata->>'scheduled_at')::timestamptz <= now()
  order by (cj.metadata->>'scheduled_at')::timestamptz
  limit 1;

  if not found then
    return 0;
  end if;

  begin
    select * into v_res
    from public.publish_prepared_post(rec.prepared_post_id::text);

    v_success := coalesce(v_res.success, false);
    v_post_id := v_res.facebook_post_id;
    v_url := v_res.facebook_url;

    if v_success then
      update public.content_jobs
        set status = 'published',
            updated_at = now()
        where id = rec.content_job_id;

      update public.social_posts
        set status = 'published',
            updated_at = now(),
            provider_metadata = coalesce(provider_metadata, '{}'::jsonb)
              || jsonb_build_object(
                'facebook_post_id', v_post_id,
                'facebook_url', v_url
              )
        where id = rec.social_post_id;

      if rec.schedule_id is not null then
        update public.social_schedules
          set status = 'published'
          where id = rec.schedule_id;
      end if;
    else
      update public.content_jobs
        set status = 'archived',
            updated_at = now()
        where id = rec.content_job_id;

      update public.social_posts
        set status = 'failed',
            updated_at = now()
        where id = rec.social_post_id;

      if rec.schedule_id is not null then
        update public.social_schedules
          set status = 'failed'
          where id = rec.schedule_id;
      end if;
    end if;

    v_count := 1;
  exception when others then
    -- En cas d'erreur inattendue, marquer le job comme archivé/failed pour éviter les boucles infinies
    update public.content_jobs
      set status = 'archived',
          updated_at = now()
      where id = rec.content_job_id;

    update public.social_posts
      set status = 'failed',
          updated_at = now()
      where id = rec.social_post_id;

    if rec.schedule_id is not null then
      update public.social_schedules
        set status = 'failed'
        where id = rec.schedule_id;
    end if;
  end;

  return v_count;
end;
$$;

revoke all on function public.run_facebook_schedules_once() from public;
grant execute on function public.run_facebook_schedules_once() to anon, authenticated;

-- Helper: retourner le prochain job Facebook planifié arrivé à échéance
-- Cette fonction ne publie pas, elle se contente de sélectionner
-- le même enregistrement que run_facebook_schedules_once
-- pour un traitement côté Edge / JavaScript.

create or replace function public.get_next_facebook_schedule_job()
returns table (
  content_job_id uuid,
  prepared_post_id uuid,
  scheduled_at timestamptz,
  social_post_id uuid,
  schedule_id uuid
)
language sql
security definer
set search_path = public as
$$
  select
    cj.id as content_job_id,
    (cj.metadata->>'prepared_post_id')::uuid as prepared_post_id,
    (cj.metadata->>'scheduled_at')::timestamptz as scheduled_at,
    sp.id as social_post_id,
    ss.id as schedule_id
  from public.content_jobs cj
  join public.social_posts sp on sp.id = cj.social_post_id
  left join public.social_schedules ss on ss.post_id = sp.id
  where cj.status = 'scheduled'
    and cj.channels @> array['facebook']::text[]
    and (cj.metadata->>'prepared_post_id') is not null
    and (cj.metadata->>'scheduled_at')::timestamptz <= now()
  order by (cj.metadata->>'scheduled_at')::timestamptz
  limit 1;
$$;

revoke all on function public.get_next_facebook_schedule_job() from public;
grant execute on function public.get_next_facebook_schedule_job() to anon, authenticated;
