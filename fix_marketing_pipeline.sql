-- Fix pipeline marketing : persistance des recommandations + unification RPC
-- A exécuter avec : python tools/admin_sql.py fix_marketing_pipeline.sql

-- 1) Securiser la colonne engagement_rate pour les analyses de performance
alter table if exists public.facebook_posts
  add column if not exists engagement_rate numeric;

-- 2) Nettoyer les anciennes surcharges de generate_marketing_recommendation
--    (on garde une seule signature text,int avec valeurs par défaut)
drop function if exists public.generate_marketing_recommendation();
drop function if exists public.generate_marketing_recommendation(text);
drop function if exists public.generate_marketing_recommendation(integer);
drop function if exists public.generate_marketing_recommendation(text, integer);

-- 3) Nouvelle version canonique : insère dans studio_marketing_recommendations
create or replace function public.generate_marketing_recommendation(
  p_objective text default 'engagement',
  p_count integer default 5
)
returns table (
  id text,
  objective text,
  recommendation_summary text,
  reasoning text,
  proposed_format text,
  proposed_message text,
  confidence_level text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public as
$$
begin
  return query
  with inserted as (
    insert into public.studio_marketing_recommendations as smr (
      objective,
      recommendation_summary,
      reasoning,
      proposed_format,
      proposed_message,
      proposed_media_prompt,
      confidence_level,
      status
    )
    select
      coalesce(p_objective, 'engagement') as objective,
      case coalesce(p_objective, 'engagement')
        when 'notoriety' then 'Publier un contenu viral pour augmenter la visibilité'
        when 'engagement' then 'Publier un visuel attractif avec message engageant'
        when 'conversion' then 'Partager une offre attractive pour générer des inscriptions'
        else 'Publier un contenu équilibré pour soutenir le marketing'
      end as recommendation_summary,
      case
        when extract(hour from now()) between 8 and 12 then 'Matin : moment optimal pour engagement'
        when extract(hour from now()) between 12 and 14 then 'Midi : pic d''activité sur Facebook'
        when extract(hour from now()) between 17 and 20 then 'Soir : meilleur moment pour notoriété'
        else 'Hors créneau habituel : tester une nouvelle plage horaire'
      end as reasoning,
      case coalesce(p_objective, 'engagement')
        when 'notoriety' then 'video'
        when 'engagement' then 'image'
        else 'text'
      end as proposed_format,
      case coalesce(p_objective, 'engagement')
        when 'notoriety' then 'Découvrez pourquoi Academia est le meilleur choix !'
        when 'engagement' then 'Votre avenir commence ici. #Education #Excellence'
        when 'conversion' then 'Places limitées ! Inscrivez-vous dès maintenant.'
        else 'Rejoignez une communauté qui valorise votre excellence.'
      end as proposed_message,
      case coalesce(p_objective, 'engagement')
        when 'notoriety' then 'Video institutionnelle, professionnelle, éducation, moderne, dynamique'
        when 'engagement' then 'Image engageante, communautaire, étudiants, interaction, positive'
        else 'Texte informatif, professionnel, éducation, opportunité'
      end as proposed_media_prompt,
      case
        when extract(hour from now()) between 8 and 20 then 'high'
        else 'medium'
      end as confidence_level,
      'pending' as status
    from generate_series(1, greatest(coalesce(p_count, 5), 1))
    returning
      smr.id,
      smr.objective,
      smr.recommendation_summary,
      smr.reasoning,
      smr.proposed_format,
      smr.proposed_message,
      smr.confidence_level,
      smr.status,
      smr.created_at
  )
  select
    i.id::text,
    i.objective,
    i.recommendation_summary,
    i.reasoning,
    i.proposed_format,
    i.proposed_message,
    i.confidence_level,
    i.status,
    i.created_at
  from inserted i;
end;
$$;

grant execute on function public.generate_marketing_recommendation(text, integer) to anon, authenticated;

-- 4) Unifier get_pending_recommendations pour éviter les surcharges ambiguës
drop function if exists public.get_pending_recommendations();
drop function if exists public.get_pending_recommendations(integer);

create or replace function public.get_pending_recommendations(
  p_limit integer default 10
)
returns table (
  id text,
  objective text,
  recommendation_summary text,
  reasoning text,
  proposed_format text,
  proposed_message text,
  confidence_level text,
  created_at timestamptz
)
language sql
security definer
set search_path = public as
$$
  select
    smr.id::text,
    smr.objective,
    smr.recommendation_summary,
    smr.reasoning,
    smr.proposed_format,
    smr.proposed_message,
    smr.confidence_level,
    smr.created_at
  from public.studio_marketing_recommendations as smr
  where smr.status = 'pending'
  order by
    case smr.confidence_level
      when 'high' then 1
      when 'medium' then 2
      else 3
    end,
    smr.created_at desc
  limit p_limit;
$$;

grant execute on function public.get_pending_recommendations(integer) to anon, authenticated;

-- 5) Unifier create_marketing_alert pour éviter les surcharges ambiguës
drop function if exists public.create_marketing_alert(text, text);
drop function if exists public.create_marketing_alert(text, text, text);

create or replace function public.create_marketing_alert(
  p_alert_type text,
  p_message text,
  p_priority text default 'medium'
)
returns table (
  success boolean,
  alert_id text,
  message text
)
language sql
security definer
set search_path = public as
$$
  with inserted as (
    insert into public.studio_marketing_alerts (
      alert_type,
      message,
      priority
    ) values (
      p_alert_type,
      p_message,
      p_priority
    )
    returning id
  )
  select
    true as success,
    i.id::text as alert_id,
    'Alerte marketing créée avec succès'::text as message
  from inserted i;
$$;

grant execute on function public.create_marketing_alert(text, text, text) to anon, authenticated;

-- 6) Unifier approve_marketing_recommendation pour éviter les surcharges ambiguës
drop function if exists public.approve_marketing_recommendation();
drop function if exists public.approve_marketing_recommendation(text);
drop function if exists public.approve_marketing_recommendation(uuid);
drop function if exists public.approve_marketing_recommendation(text, text);
drop function if exists public.approve_marketing_recommendation(uuid, text);

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
set search_path = public as
$$
declare
  v_recommendation public.studio_marketing_recommendations%rowtype;
  v_prepared_post_id text;
begin
  -- Récupérer la recommandation en attente
  select *
  into v_recommendation
  from public.studio_marketing_recommendations
  where id = p_recommendation_id::uuid
    and status = 'pending';

  if not found then
    return query select false, 'Recommandation non trouvée ou déjà traitée', null::text;
    return;
  end if;

  -- Mettre à jour le statut de la recommandation
  update public.studio_marketing_recommendations
  set status = 'approved',
      approved_at = now(),
      approved_by = p_approved_by
  where id = p_recommendation_id::uuid;

  -- Créer le post préparé pour validation finale / publication
  insert into public.studio_facebook_prepared_posts (
    recommendation_id,
    final_message,
    media_type,
    status
  ) values (
    p_recommendation_id::uuid,
    v_recommendation.proposed_message,
    v_recommendation.proposed_format,
    'ready_for_validation'
  ) returning id::text into v_prepared_post_id;

  return query
  select true,
         'Recommandation approuvée avec succès',
         v_prepared_post_id;
end;
$$;

grant execute on function public.approve_marketing_recommendation(text, text) to anon, authenticated;
