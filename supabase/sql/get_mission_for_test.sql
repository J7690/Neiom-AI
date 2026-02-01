-- Récupérer une mission active pour tester l'orchestrateur
select
  id,
  objective_id,
  channel,
  activity_ref,
  status,
  created_at
from studio_marketing_missions
where status = 'active'
  and activity_ref ilike '%cours%'
order by created_at desc
limit 5;
