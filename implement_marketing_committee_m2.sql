-- Phase M2 – Comité marketing Nexiom (RPC JSON unique)
-- Implémente generate_marketing_committee_recommendation() basé sur les objectifs
-- et les recommandations existantes.

create or replace function public.generate_marketing_committee_recommendation(
  p_objective text default null,
  p_persist boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_objective text;
  v_rec record;
  v_payload jsonb;
  v_patterns record;
begin
  -- Déterminer l'objectif prioritaire
  select objective
  into v_objective
  from public.studio_marketing_objectives
  where status = 'active'
  order by horizon, created_at desc
  limit 1;

  v_objective := coalesce(p_objective, v_objective, 'engagement');

  -- Essayer de récupérer une analyse de patterns si disponible
  begin
    select *
    into v_patterns
    from public.analyze_performance_patterns()
    limit 1;
  exception
    when undefined_function then
      v_patterns := null;
  end;

  -- Générer une recommandation de base via la fonction existante
  begin
    select *
    into v_rec
    from public.generate_marketing_recommendation(v_objective, 1)
    limit 1;
  exception
    when undefined_function then
      v_rec := null;
  end;

  if v_rec is null then
    -- Fallback minimal si aucune fonction n'est disponible
    v_payload := jsonb_build_object(
      'objective', v_objective,
      'recommendation', 'Publier un contenu simple pour soutenir l''objectif ' || v_objective,
      'justification', 'Recommandation générique faute de données historiques suffisantes.',
      'proposed_post_type', 'text',
      'confidence_level', 'low',
      'expected_impact', 'Impact modéré attendu sur l''objectif ' || v_objective,
      'risk_or_warning', 'Vérifier manuellement la cohérence avec la stratégie et les règles de marque.'
    );
  else
    v_payload := jsonb_build_object(
      'objective', coalesce(v_rec.objective, v_objective),
      'recommendation', coalesce(v_rec.proposed_message, v_rec.recommendation_summary),
      'justification', coalesce(v_rec.reasoning, 'Basé sur les patterns récents et les objectifs définis.'),
      'proposed_post_type', coalesce(v_rec.proposed_format, 'text'),
      'confidence_level', coalesce(v_rec.confidence_level, 'medium'),
      'expected_impact',
        case coalesce(v_rec.objective, v_objective)
          when 'notoriety' then 'Augmenter la visibilité et la portée de la marque sur la période à venir.'
          when 'engagement' then 'Stimuler les interactions (likes, commentaires, partages) sur les prochains posts.'
          when 'conversion' then 'Générer davantage d''inscriptions ou de demandes de contact qualifiées.'
          else 'Améliorer la présence globale et la cohérence marketing sur les réseaux.'
        end,
      'risk_or_warning',
        case
          when v_patterns is not null then
            coalesce(v_patterns.insights->>'risk', 'Vérifier la cohérence avec les règles de marque et le contexte local.')
          else 'Vérifier la cohérence avec les règles de marque et le contexte local avant publication.'
        end
    );
  end if;

  -- Persistance dans les cycles d''analyse si demandé
  if coalesce(p_persist, true) then
    insert into public.studio_analysis_cycles(
      cycle_date,
      analysis_type,
      posts_analyzed,
      recommendations_generated,
      recommendations_approved,
      recommendations_published,
      performance_score,
      insights
    ) values (
      current_date,
      'committee',
      0,
      1,
      0,
      0,
      null,
      v_payload
    );
  end if;

  return v_payload;
end;
$$;

grant execute on function public.generate_marketing_committee_recommendation(text,boolean) to anon, authenticated;
