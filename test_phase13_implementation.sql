-- Phase 13 Implementation Test
-- Deeper editorial plan + activity and metrics checks + settings upsert

-- 1) Generate a 7-day editorial plan with multiple channels
SELECT public.create_editorial_plan_stub(
  'phase13_agent',
  'Plan éditorial Phase 13 – implementation',
  now(),
  7,
  ARRAY['facebook','instagram','tiktok'],
  'UTC',
  'enthousiaste',
  160
) AS editorial_plan_7d;

-- 2) Fetch recent activity with a larger limit
SELECT public.get_recent_activity(100) AS recent_activity_100;

-- 3) Metrics timeseries over last 10 days
SELECT public.get_metrics_timeseries(10) AS metrics_10d;

-- 4) Upsert multiple settings keys used by other phases (non-destructive)
SELECT public.upsert_setting('NEXIOM_DEFAULT_CHAT_MODEL', 'openrouter/auto') AS upsert_model;
SELECT public.upsert_setting('META_APP_SECRET', 'dummy_secret_placeholder') AS upsert_meta_secret;
-- WhatsApp-related keys should remain configured by infra; here we can still write placeholders if needed
SELECT public.upsert_setting('WHATSAPP_VERIFY_TOKEN', 'dummy_verify_placeholder') AS upsert_verify_token;
