-- Vérifier si les sources externes ont is_active = true
select
  id,
  name,
  domain,
  is_active,
  is_official,
  priority,
  tags,
  created_at
from studio_external_knowledge_sources
order by created_at desc
limit 30;
