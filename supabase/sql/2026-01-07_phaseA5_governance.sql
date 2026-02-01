-- Phase A5 – Gouvernance & garde-fous pour le cerveau marketing
-- Objectif : permettre à l'administrateur de désactiver OpenRouter ou la publication Facebook
-- et préparer des limites d'usage, sans mocks.

-- 1) Table de configuration centrale pour l'orchestration IA
create table if not exists public.ai_orchestration_settings (
  id text primary key default 'default',
  openrouter_enabled boolean not null default true,
  facebook_publishing_enabled boolean not null default true,
  max_daily_marketing_brain_calls int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger updated_at (réutilise set_updated_at déjà présent dans le schéma public)
create or replace function public.set_ai_orchestration_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists ai_orchestration_settings_updated_at on public.ai_orchestration_settings;
create trigger ai_orchestration_settings_updated_at
  before update on public.ai_orchestration_settings
  for each row
  execute function public.set_ai_orchestration_updated_at();

-- Insérer une configuration par défaut si elle n'existe pas
insert into public.ai_orchestration_settings (id, openrouter_enabled, facebook_publishing_enabled)
values ('default', true, true)
on conflict (id) do nothing;

grant select, update on public.ai_orchestration_settings to authenticated;

-- 2) RPC simple pour récupérer la configuration (facultatif pour UI/admin)
create or replace function public.get_ai_orchestration_settings()
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cfg jsonb;
begin
  select to_jsonb(s)
  into v_cfg
  from public.ai_orchestration_settings s
  where id = 'default';

  return coalesce(v_cfg, '{}'::jsonb);
end;
$$;

grant execute on function public.get_ai_orchestration_settings() to anon, authenticated;

-- 3) Adapter publish_prepared_post pour respecter facebook_publishing_enabled
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

  -- Appeler la RPC Facebook réelle (wrapper vers Edge / Meta)
  select * into v_facebook_result
  from facebook_publish_post(
    v_prepared_post.media_type,
    v_prepared_post.final_message,
    case when v_prepared_post.media_type = 'image' then v_prepared_post.media_url else null end,
    case when v_prepared_post.media_type = 'video' then v_prepared_post.media_url else null end
  );

  if v_facebook_result.id is not null then
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
      v_prepared_post.final_message,
      case when v_prepared_post.media_url is not null then array[v_prepared_post.media_url] else '{}'::text[] end,
      array['facebook'],
      'published',
      jsonb_build_object(
        'facebook_post_id', v_facebook_result.post_id,
        'facebook_url', v_facebook_result.url,
        'prepared_post_id', v_prepared_post.id,
        'publication_context', v_prepared_post.publication_context
      )
    ) returning id into v_social_post_id;

    -- Enrichir facebook_posts.metadata avec le contexte de publication si disponible
    begin
      update public.facebook_posts
      set metadata = coalesce(metadata, '{}'::jsonb) || jsonb_build_object(
        'publication_context', v_prepared_post.publication_context
      )
      where facebook_post_id = v_facebook_result.post_id;
    exception when others then
      -- Ne jamais casser la publication pour un simple enrichissement de contexte
      null;
    end;

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
           v_facebook_result.post_id::text,
           v_facebook_result.url::text;
  else
    return query
    select false, 'Échec de publication Facebook', null::text, null::text;
  end if;
end;
$$;

grant execute on function public.publish_prepared_post(text) to anon, authenticated;
