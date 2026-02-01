-- Audit détaillé missions vs rapports d'intelligence

-- 1) Dernières missions
select id,
       objective_id,
       channel,
       metric,
       status,
       start_date,
       end_date,
       created_at
from public.studio_marketing_missions
order by created_at desc
limit 20;

-- 2) Rapports groupés par mission
select mission_id,
       count(*) as report_count,
       max(created_at) as last_report_at
from public.studio_mission_intelligence_reports
group by mission_id
order by last_report_at desc
limit 20;

-- 3) Jointure missions ↔ rapports
select m.id as mission_id,
       m.channel,
       m.metric,
       m.status,
       m.start_date,
       m.end_date,
       m.created_at as mission_created_at,
       r.id as report_id,
       r.created_at as report_created_at
from public.studio_marketing_missions m
left join public.studio_mission_intelligence_reports r
  on r.mission_id = m.id
order by m.created_at desc, r.created_at desc
limit 40;
