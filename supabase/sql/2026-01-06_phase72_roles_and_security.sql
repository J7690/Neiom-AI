-- Phase 8 – Rôles et sécurité pour l'orchestrateur IA
-- Objectif : introduire des rôles logiques sans casser les comportements existants

-- Créer les rôles s'ils n'existent pas déjà
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ai_orchestrator') THEN
    CREATE ROLE ai_orchestrator;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'marketing_admin') THEN
    CREATE ROLE marketing_admin;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'operator') THEN
    CREATE ROLE operator;
  END IF;
END
$$;

-- Donner accès au schéma public
GRANT USAGE ON SCHEMA public TO ai_orchestrator;
GRANT USAGE ON SCHEMA public TO marketing_admin;
GRANT USAGE ON SCHEMA public TO operator;

-- Privilèges pour ai_orchestrator (backend IA / orchestrateur)
GRANT EXECUTE ON FUNCTION public.orchestrate_content_job_step(uuid, text, jsonb) TO ai_orchestrator;
GRANT EXECUTE ON FUNCTION public.run_ai_reply_for_message(uuid) TO ai_orchestrator;
GRANT EXECUTE ON FUNCTION public.create_content_jobs_from_objective(text, date, int, text[], text, text, int, text) TO ai_orchestrator;
GRANT EXECUTE ON FUNCTION public.schedule_content_job(uuid, timestamptz, text) TO ai_orchestrator;
GRANT EXECUTE ON FUNCTION public.aggregate_ai_activity(text) TO ai_orchestrator;

-- Privilèges pour marketing_admin (validation / pilotage marketing)
GRANT SELECT, INSERT, UPDATE ON TABLE public.content_jobs TO marketing_admin;
GRANT SELECT, UPDATE ON TABLE public.messages TO marketing_admin;
GRANT SELECT, INSERT, UPDATE ON TABLE public.ai_alerts TO marketing_admin;
GRANT SELECT ON TABLE public.ai_activity_2h TO marketing_admin;
GRANT SELECT ON TABLE public.ai_activity_daily TO marketing_admin;
GRANT SELECT ON TABLE public.ai_activity_weekly TO marketing_admin;

GRANT EXECUTE ON FUNCTION public.list_content_jobs(text, int) TO marketing_admin;
GRANT EXECUTE ON FUNCTION public.get_content_job(uuid) TO marketing_admin;
GRANT EXECUTE ON FUNCTION public.upsert_content_job(uuid, text, text, text, text[], text, text, text, uuid, uuid, uuid, uuid, jsonb) TO marketing_admin;
GRANT EXECUTE ON FUNCTION public.orchestrate_content_job_step(uuid, text, jsonb) TO marketing_admin;
GRANT EXECUTE ON FUNCTION public.schedule_content_job(uuid, timestamptz, text) TO marketing_admin;

-- Privilèges pour operator (lecture / supervision)
GRANT SELECT ON TABLE public.messages TO operator;
GRANT SELECT ON TABLE public.content_jobs TO operator;
GRANT SELECT ON TABLE public.ai_alerts TO operator;
GRANT SELECT ON TABLE public.ai_activity_2h TO operator;
GRANT SELECT ON TABLE public.ai_activity_daily TO operator;
GRANT SELECT ON TABLE public.ai_activity_weekly TO operator;

GRANT EXECUTE ON FUNCTION public.get_ai_activity_2h(timestamptz) TO operator;
GRANT EXECUTE ON FUNCTION public.get_ai_activity_daily(int) TO operator;
GRANT EXECUTE ON FUNCTION public.get_ai_activity_weekly(int) TO operator;
