-- Fichier neutralisé : ancien smoke-test complet du pipeline marketing, à ne plus utiliser.
-- A0) Comptages rapides des tables clés
-- select 'A0_counts' as step,
--        (select count(*) from public.studio_marketing_recommendations) as recommendations_count,
--        (select count(*) from public.studio_facebook_prepared_posts) as prepared_posts_count,
--        (select count(*) from public.studio_marketing_objectives) as objectives_count,
--        (select count(*) from public.studio_performance_patterns) as patterns_count,
--        (select count(*) from public.content_jobs) as content_jobs_count;

-- B1) Générer quelques recommandations marketing (SQL canonique)
-- with g as (
--   select *
--   from public.generate_marketing_recommendation('engagement', 3)
-- )
-- select 'B1_generate_marketing_recommendation' as step, * from g;

-- B2) Voir les recommandations en attente via RPC get_pending_recommendations
select 'B2_get_pending_recommendations' as step, *
from public.get_pending_recommendations()
limit 10;

-- B3) Approuver une recommandation récente via approve_marketing_recommendation
with cand as (
  select id
  from public.studio_marketing_recommendations
  where status = 'pending'
  order by created_at desc
  limit 1
),
app as (
  select *
  from public.approve_marketing_recommendation(
    (select id::text from cand),
    'studio_admin_smoketest'
  )
)
select 'B3_approve_marketing_recommendation' as step, * from app;

-- B4) Rejeter une recommandation récente via reject_marketing_recommendation
with cand as (
  select id
  from public.studio_marketing_recommendations
  where status = 'pending'
  order by created_at desc
  limit 1
),
rej as (
  select *
  from public.reject_marketing_recommendation(
    (select id from cand),
    'Rejet via smoke-test admin_execute_sql'
  )
)
select 'B4_reject_marketing_recommendation' as step, * from rej;

-- B5) Recompter les statuts de recommandations
select 'B5_recommendations_status_counts' as step,
       status,
       count(*) as cnt
from public.studio_marketing_recommendations
group by status
order by status;

-- C1) Créer une alerte marketing
select 'C1_create_marketing_alert' as step, *
from public.create_marketing_alert(
  'test_smoketest',
  'Alerte de test smoke-test générée via admin_execute_sql'
);

-- C2) Analyser les patterns de performance
select 'C2_analyze_performance_patterns' as step, *
from public.analyze_performance_patterns();

-- C3) Obtenir les objectifs marketing
select 'C3_get_marketing_objectives' as step, *
from public.get_marketing_objectives();

-- C4) État marketing global (objectif M1)
select 'C4_get_marketing_objective_state' as step,
       public.get_marketing_objective_state();

-- C5) Générer une recommandation de comité marketing
select 'C5_generate_marketing_committee_recommendation' as step,
       public.generate_marketing_committee_recommendation('engagement', true);

-- C6) Lister les leçons stratégiques
select 'C6_list_post_strategy_lessons' as step,
       public.list_post_strategy_lessons('engagement', null, null, 10);

-- D1) Publier un post préparé si disponible
with p as (
  select id
  from public.studio_facebook_prepared_posts
  order by created_at desc
  limit 1
),
pub as (
  select * from public.publish_prepared_post((select id from p))
)
select 'D1_publish_prepared_post' as step, * from pub;

-- E1) Créer des content_jobs à partir d'un objectif
select 'E1_create_content_jobs_from_objective' as step,
       public.create_content_jobs_from_objective(
         p_objective => 'engagement',
         p_start_date => current_date,
         p_days => 3,
         p_channels => array['facebook'],
         p_timezone => 'UTC',
         p_tone => 'neutre',
         p_length => 120,
         p_author_agent => 'marketing_brain_smoketest'
       );

-- E2) Lister les content_jobs récents
select 'E2_list_content_jobs' as step, *
from public.list_content_jobs(
  p_status := null,
  p_limit := 20
);

-- E3) Orchestration: inspect
with j as (
  select id
  from public.content_jobs
  order by created_at desc
  limit 1
)
select 'E3_orchestrate_inspect' as step,
       public.orchestrate_content_job_step((select id from j), 'inspect');

-- E4) Orchestration: mark_pending_validation
with j as (
  select id
  from public.content_jobs
  order by created_at desc
  limit 1
)
select 'E4_orchestrate_mark_pending_validation' as step,
       public.orchestrate_content_job_step((select id from j), 'mark_pending_validation');

-- E5) Orchestration: mark_approved
with j as (
  select id
  from public.content_jobs
  order by created_at desc
  limit 1
)
select 'E5_orchestrate_mark_approved' as step,
       public.orchestrate_content_job_step((select id from j), 'mark_approved');

-- E6) Orchestration: propose_plan (création de jobs enfants)
with j as (
  select id
  from public.content_jobs
  order by created_at desc
  limit 1
)
select 'E6_orchestrate_propose_plan' as step,
       public.orchestrate_content_job_step(
         (select id from j),
         'propose_plan',
         jsonb_build_object(
           'start_date', current_date,
           'days', 2
         )
       );

-- E7) Orchestration: generate_assets (stub SQL)
with j as (
  select id
  from public.content_jobs
  order by created_at desc
  limit 1
)
select 'E7_orchestrate_generate_assets' as step,
       public.orchestrate_content_job_step((select id from j), 'generate_assets');

-- E8) Orchestration: propose_variants (A/B)
with j as (
  select id
  from public.content_jobs
  order by created_at desc
  limit 1
)
select 'E8_orchestrate_propose_variants' as step,
       public.orchestrate_content_job_step(
         (select id from j),
         'propose_variants',
         jsonb_build_object('experiment_id', 'smoke_test_experiment')
       );

-- E9) Planifier un content_job
with j as (
  select id
  from public.content_jobs
  order by created_at desc
  limit 1
)
select 'E9_schedule_content_job' as step,
       public.schedule_content_job(
         p_content_job_id := (select id from j),
         p_schedule_at := now() + interval '1 day',
         p_timezone := 'UTC'
       );

-- F1) Comptages finaux après tests
select 'F1_counts_after' as step,
       (select count(*) from public.studio_marketing_recommendations) as recommendations_count,
       (select count(*) from public.studio_facebook_prepared_posts) as prepared_posts_count,
       (select count(*) from public.studio_marketing_objectives) as objectives_count,
       (select count(*) from public.studio_performance_patterns) as patterns_count,
       (select count(*) from public.content_jobs) as content_jobs_count;
