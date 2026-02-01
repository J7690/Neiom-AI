-- Phase 13 Basic Test
-- Single editorial plan generation + recent activity + metrics timeseries + simple setting upsert

-- 1) Create a small editorial plan (3 days) on facebook/instagram
SELECT public.create_editorial_plan_stub(
  'phase13_agent',
  'Plan éditorial Phase 13 – basic test',
  now(),
  3,
  ARRAY['facebook','instagram'],
  'UTC',
  'neutre',
  140
) AS editorial_plan;

-- 2) Get recent activity (messages/posts/leads)
SELECT public.get_recent_activity(20) AS recent_activity;

-- 3) Get metrics timeseries for last 5 days
SELECT public.get_metrics_timeseries(5) AS metrics_5d;

-- 4) Upsert a dummy setting
SELECT public.upsert_setting('PHASE13_TEST_SETTING', 'ok') AS upsert_ok;
