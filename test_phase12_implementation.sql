-- Phase 12 Implementation Test
-- Multiple pipeline runs with different windows + projection of metrics and settings

-- 1) Run pipeline with a short window (30 minutes)
WITH r1 AS (
  SELECT public.run_pipeline_once(interval '30 minutes', 50) AS r
)
SELECT
  (r->>'routed')::int        AS routed_30m,
  (r->>'auto_replied')::int  AS auto_replied_30m,
  (r->>'schedules_run')::int AS schedules_run_30m,
  (r->>'metrics_collected')::int AS metrics_30m
FROM r1;

-- 2) Run pipeline with a longer window (4 hours)
WITH r2 AS (
  SELECT public.run_pipeline_once(interval '4 hours', 100) AS r
)
SELECT
  (r->>'routed')::int        AS routed_4h,
  (r->>'auto_replied')::int  AS auto_replied_4h,
  (r->>'schedules_run')::int AS schedules_run_4h,
  (r->>'metrics_collected')::int AS metrics_4h
FROM r2;

-- 3) Project settings overview booleans
WITH s AS (
  SELECT public.settings_overview() AS cfg
)
SELECT
  (cfg->>'WHATSAPP_VERIFY_TOKEN')::bool        AS has_whatsapp_verify_token,
  (cfg->>'META_APP_SECRET')::bool             AS has_meta_app_secret,
  (cfg->>'OPENROUTER_API_KEY')::bool          AS has_openrouter_api_key,
  (cfg->>'NEXIOM_DEFAULT_CHAT_MODEL')::bool   AS has_default_chat_model,
  (cfg->>'WHATSAPP_PHONE_NUMBER_ID')::bool    AS has_whatsapp_phone_number_id,
  (cfg->>'WHATSAPP_ACCESS_TOKEN')::bool       AS has_whatsapp_access_token,
  (cfg->>'WHATSAPP_API_BASE_URL')::bool       AS has_whatsapp_api_base_url
FROM s;
