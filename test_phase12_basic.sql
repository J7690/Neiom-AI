-- Phase 12 Basic Test
-- Single pipeline run + settings overview

-- 1) Run the pipeline once with default window and a small limit
SELECT public.run_pipeline_once(interval '1 hour', 50) AS pipeline_run_result;

-- 2) Fetch settings overview (booleans per key)
SELECT public.settings_overview() AS settings;
