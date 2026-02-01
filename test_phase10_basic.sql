-- Phase 10 Basic Test
-- Single comment simulation + pipeline stats call

-- 1) Simulate a single comment via RPC
WITH res AS (
  SELECT public.simulate_comment(
    'facebook',                 -- p_channel
    'phase10_user_1',           -- p_author_id
    'Phase10 Test User',        -- p_author_name
    'Un commentaire Phase 10'   -- p_content
  ) AS payload
)
SELECT (payload->>'conversation_id') IS NOT NULL AS has_conversation,
       (payload->>'message_id') IS NOT NULL AS has_message
FROM res;

-- 2) Call pipeline stats (non-assertive)
SELECT public.get_pipeline_stats() AS pipeline_stats;
