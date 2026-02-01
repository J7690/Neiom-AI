-- Phase M4 – Analyse algorithmique avancée par post
-- Implémente explain_post_algorithmic_status(p_post_id uuid)

create or replace function public.explain_post_algorithmic_status(
  p_post_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_post record;
  v_created_at timestamptz;
  v_now timestamptz := now();
  v_first_start timestamptz;
  v_first_end timestamptz;
  v_baseline_start timestamptz;
  v_first jsonb;
  v_base jsonb;
  v_status text;
  v_reason text;
  v_first_eng numeric := 0;
  v_base_eng numeric := 0;
begin
  -- Vérifier que le post existe
  select id, created_at
  into v_post
  from public.social_posts
  where id = p_post_id;

  if not found then
    raise exception 'social_post not found for id %', p_post_id;
  end if;

  v_created_at := v_post.created_at;
  v_first_start := v_created_at;
  v_first_end := v_created_at + interval '3 hours';
  v_baseline_start := v_now - interval '30 days';

  -- Agrégats sur les premières heures (3h)
  select jsonb_build_object(
    'impressions', coalesce(sum(impressions),0),
    'views', coalesce(sum(views),0),
    'likes', coalesce(sum(likes),0),
    'comments', coalesce(sum(comments),0),
    'shares', coalesce(sum(shares),0),
    'engagement_rate', round(avg(engagement_rate)::numeric,4)
  )
  into v_first
  from public.social_metrics m
  where m.post_id = p_post_id
    and m.fetched_at >= v_first_start
    and m.fetched_at <= v_first_end;

  -- Agrégats de référence sur les autres posts récents (premières 3h)
  select jsonb_build_object(
    'impressions', coalesce(sum(impressions),0),
    'views', coalesce(sum(views),0),
    'likes', coalesce(sum(likes),0),
    'comments', coalesce(sum(comments),0),
    'shares', coalesce(sum(shares),0),
    'engagement_rate', round(avg(engagement_rate)::numeric,4)
  )
  into v_base
  from public.social_metrics m
  join public.social_posts p on p.id = m.post_id
  where p.id <> p_post_id
    and p.created_at >= v_baseline_start
    and p.created_at < v_now
    and m.fetched_at >= p.created_at
    and m.fetched_at <= p.created_at + interval '3 hours';

  begin
    v_first_eng := coalesce((v_first->>'engagement_rate')::numeric, 0);
  exception when others then
    v_first_eng := 0;
  end;

  begin
    v_base_eng := coalesce((v_base->>'engagement_rate')::numeric, 0);
  exception when others then
    v_base_eng := 0;
  end;

  if v_base_eng <= 0 then
    v_status := 'neutral';
    v_reason := 'Pas assez de données de référence pour comparer les performances; utiliser les métriques brutes des premières heures.';
  else
    if v_first_eng >= v_base_eng * 1.5 then
      v_status := 'boosted';
      v_reason := format(
        'Engagement dans les 3 premières heures supérieur d''environ %.0f%% à la moyenne des posts récents.',
        ((v_first_eng / v_base_eng) - 1) * 100
      );
    elsif v_first_eng <= v_base_eng * 0.7 then
      v_status := 'weak';
      v_reason := format(
        'Engagement dans les 3 premières heures inférieur d''environ %.0f%% à la moyenne des posts récents.',
        (1 - (v_first_eng / v_base_eng)) * 100
      );
    else
      v_status := 'neutral';
      v_reason := 'Engagement dans les 3 premières heures proche de la moyenne des posts récents.';
    end if;
  end if;

  return jsonb_build_object(
    'post_id', p_post_id,
    'status', v_status,
    'reason', v_reason,
    'window_hours', 3,
    'first_hours_metrics', coalesce(v_first, '{}'::jsonb),
    'baseline_metrics', coalesce(v_base, '{}'::jsonb)
  );
end;
$$;

grant execute on function public.explain_post_algorithmic_status(uuid) to anon, authenticated;
