-- Phase MI – Ouverture contrôlée de la fonction d'intelligence de mission
-- Objet : permettre au client Nexiom (rôle authenticated / anon) de lire le dernier
-- rapport d'intelligence pour une mission via get_latest_mission_intelligence_report.
-- Cette fonction reste security definer et ne permet qu'une lecture filtrée.

grant execute on function public.get_latest_mission_intelligence_report(uuid)
  to authenticated;

grant execute on function public.get_latest_mission_intelligence_report(uuid)
  to anon;
