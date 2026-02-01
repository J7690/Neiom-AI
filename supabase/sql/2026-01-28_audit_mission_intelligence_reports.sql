-- Audit lecture seule des rapports d'intelligence de mission
-- 1) Derniers rapports créés
select id,
       mission_id,
       objective,
       channel,
       created_at
from public.studio_mission_intelligence_reports
order by created_at desc
limit 10;

-- 2) Comptage de rapports par mission
select mission_id,
       count(*) as report_count,
       max(created_at) as last_report_at
from public.studio_mission_intelligence_reports
group by mission_id
order by last_report_at desc
limit 10;
