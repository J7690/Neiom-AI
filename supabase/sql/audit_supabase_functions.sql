-- Audit des Edge Functions déployées dans ce projet Supabase
-- NOTE : admin_execute_sql renvoie généralement null pour les SELECT,
-- mais cette requête permet au moins de vérifier qu'elle s'exécute sans erreur.
select
  name,
  slug,
  verify_jwt,
  created_at,
  updated_at
from supabase_functions.functions
order by created_at desc;
