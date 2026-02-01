-- Phase FB – Calcul automatique des meilleurs créneaux Facebook et planification intelligente
-- Objectif :
-- 1) Calculer les meilleurs créneaux horaires (jour + heure) pour publier sur Facebook,
--    en fonction des performances réelles (engagement) et éventuellement d'un thème.
-- 2) Exposer une fonction de planification "smart" qui choisit automatiquement l'heure
--    à partir de ces créneaux et de schedule_facebook_publication.
-- 3) Fournir une routine quotidienne simple pour créer un planning de content_jobs
--    à partir d'un objectif marketing.
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseFB_timing_planning.sql

-- 1) Meilleurs créneaux horaires par thème / objectif (basé sur les posts Facebook réels)
create or replace function public.get_best_facebook_time_for_topic(
  p_topic text default null,
  p_days integer default 90,
  p_limit integer default 8
)
returns table (
  weekday integer,
  hour integer,
  score numeric,
  posts_count integer
)
language sql
security definer
set search_path = public
as $$
  with recent_posts as (
    select fp.id, fp.message, fp.facebook_post_id, fp.created_at
    from public.facebook_posts fp
    where fp.status = 'published'
      and fp.created_at >= now() - (p_days || ' days')::interval
      and (p_topic is null or fp.message ilike '%' || p_topic || '%')
  ), engagement as (
    select
      rp.id as post_id,
      coalesce(count(fc.id), 0)::numeric as comments_count,
      coalesce(sum(fc.like_count), 0)::numeric as likes_sum
    from recent_posts rp
    left join public.facebook_comments fc
      on fc.facebook_post_id = rp.facebook_post_id
    group by rp.id
  ), slot_metrics as (
    select
      extract(dow from rp.created_at)::int as weekday,
      extract(hour from rp.created_at)::int as hour,
      sum(eng.comments_count + eng.likes_sum * 0.5)::numeric as score,
      count(*) as posts_count
    from recent_posts rp
    join engagement eng on eng.post_id = rp.id
    group by extract(dow from rp.created_at), extract(hour from rp.created_at)
  )
  select weekday, hour, score, posts_count
  from slot_metrics
  where posts_count > 0
  order by score desc, posts_count desc, weekday, hour
  limit p_limit;
$$;

grant execute on function public.get_best_facebook_time_for_topic(text, integer, integer) to anon, authenticated;


-- 2) Calculer un créneau optimal pour un prepared_post donné
create or replace function public.compute_best_facebook_time_for_prepared_post(
  p_prepared_post_id text,
  p_timezone text default 'UTC',
  p_days integer default 90
)
returns timestamptz
language plpgsql
security definer
set search_path = public as
$$
declare
  v_prepared_post studio_facebook_prepared_posts%rowtype;
  v_slot record;
  v_now_local timestamp;
  v_today_dow integer;
  v_target_dow integer;
  v_hour integer;
  v_day_diff integer;
  v_target_date date;
  v_candidate_local timestamp;
  v_scheduled_at timestamptz;
  v_min_posts integer := 3;  -- nombre minimum de posts pour considérer un créneau fiable
  v_min_hour integer := 7;   -- début de la plage horaire "humaine" (heure locale)
  v_max_hour integer := 22;  -- fin de la plage horaire "humaine" (heure locale)
begin
  if p_prepared_post_id is null then
    raise exception 'p_prepared_post_id is required';
  end if;

  select * into v_prepared_post
  from public.studio_facebook_prepared_posts
  where id = p_prepared_post_id::uuid;

  if not found then
    raise exception 'studio_facebook_prepared_posts not found for id %', p_prepared_post_id;
  end if;

  -- Récupérer un créneau optimal en appliquant quelques garde-fous :
  -- 1) privilégier les créneaux avec suffisamment d'historique et dans une
  --    plage horaire raisonnable (journée/soirée) ;
  -- 2) à défaut, prendre le meilleur créneau global parmi les slots connus ;
  -- 3) si aucun historique n'est exploitable, fallback à +1 heure.

  -- 1) Slots avec suffisamment de posts et dans une plage horaire "humaine"
  select weekday, hour, score, posts_count
  into v_slot
  from public.get_best_facebook_time_for_topic(null, p_days, 8)
  where posts_count >= v_min_posts
    and hour between v_min_hour and v_max_hour
  order by score desc, posts_count desc, weekday, hour
  limit 1;

  -- 2) Si rien ne correspond (très peu d'historique), prendre le meilleur slot
  --    parmi tous les slots disponibles mais toujours dans la plage horaire
  --    "humaine" définie ci-dessus.
  if v_slot.weekday is null then
    select weekday, hour, score, posts_count
    into v_slot
    from public.get_best_facebook_time_for_topic(null, p_days, 8)
    where hour between v_min_hour and v_max_hour
    order by score desc, posts_count desc, weekday, hour
    limit 1;
  end if;

  v_now_local := (now() at time zone p_timezone);

  if v_slot.weekday is null then
    -- Pas d'historique exploitable : fallback à +1 heure
    v_scheduled_at := (v_now_local + interval '1 hour') at time zone p_timezone;
    return v_scheduled_at;
  end if;

  v_today_dow := extract(dow from v_now_local)::int;
  v_target_dow := v_slot.weekday;
  v_hour := v_slot.hour;

  -- Calcul du prochain jour correspondant au weekday cible
  v_day_diff := (v_target_dow - v_today_dow + 7) % 7;

  -- Si c'est le même jour mais l'heure est déjà passée, repousser à la semaine suivante
  if v_day_diff = 0 and v_hour <= extract(hour from v_now_local)::int then
    v_day_diff := 7;
  end if;

  v_target_date := (v_now_local::date + v_day_diff);

  v_candidate_local := timestamp with time zone 'epoch'
    + (v_target_date::date - date '1970-01-01') * interval '1 day'
    + make_interval(hours => v_hour);

  -- Convertir ce timestamp local en timestamptz basé sur le timezone fourni
  v_scheduled_at := timezone(p_timezone, v_candidate_local);

  return v_scheduled_at;
end;
$$;

grant execute on function public.compute_best_facebook_time_for_prepared_post(text, text, integer) to anon, authenticated;


-- 3) Planification intelligente d'une publication Facebook à partir d'un prepared_post
create or replace function public.schedule_facebook_publication_smart(
  p_prepared_post_id text,
  p_timezone text default 'UTC',
  p_days integer default 90
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_scheduled_at timestamptz;
  v_result jsonb;
begin
  if p_prepared_post_id is null then
    raise exception 'p_prepared_post_id is required';
  end if;

  v_scheduled_at := public.compute_best_facebook_time_for_prepared_post(
    p_prepared_post_id,
    p_timezone,
    p_days
  );

  v_result := public.schedule_facebook_publication(
    p_prepared_post_id,
    v_scheduled_at,
    p_timezone
  );

  return v_result || jsonb_build_object('computed_scheduled_at', v_scheduled_at);
end;
$$;

revoke all on function public.schedule_facebook_publication_smart(text, text, integer) from public;
grant execute on function public.schedule_facebook_publication_smart(text, text, integer) to anon, authenticated;


-- 4) Routine quotidienne simple de planning de content_jobs à partir d'un objectif
create or replace function public.run_daily_facebook_planning(
  p_objective text default 'engagement',
  p_days integer default 1,
  p_timezone text default 'UTC'
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_today date := current_date;
  v_result jsonb;
begin
  v_result := public.create_content_jobs_from_objective(
    p_objective => p_objective,
    p_start_date => v_today,
    p_days => p_days,
    p_channels => array['facebook'],
    p_timezone => p_timezone,
    p_tone => 'neutre',
    p_length => 120,
    p_author_agent => 'marketing_brain_daily_planner'
  );

  return jsonb_build_object(
    'objective', p_objective,
    'days', p_days,
    'timezone', p_timezone,
    'jobs', v_result
  );
end;
$$;

grant execute on function public.run_daily_facebook_planning(text, integer, text) to anon, authenticated;

-- 5) Résumé simple des meilleurs créneaux horaires pour la page Facebook
--    Cette fonction est un alias pratique de get_best_facebook_time_for_topic
--    pour l'UI du Studio (retourne directement un tableau de créneaux).
create or replace function public.get_best_facebook_time_summary(
  p_days integer default 90
)
returns table (
  weekday integer,
  hour integer,
  score numeric,
  posts_count integer
)
language sql
security definer
set search_path = public as
$$
  select weekday, hour, score, posts_count
  from public.get_best_facebook_time_for_topic(null, p_days, 8);
$$;

grant execute on function public.get_best_facebook_time_summary(integer) to anon, authenticated;
