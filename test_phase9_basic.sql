-- Phase 9 Basic Test
-- Single event routing: ingest + route_webhook_event + checks

-- 1) Ingest a single webhook_event for testing (idempotent on (channel, event_id))
SELECT public.ingest_webhook_event(
  'instagram',            -- p_channel
  'message',              -- p_type
  'phase9_test_evt_basic_1', -- p_event_id
  'phase9_user_1',        -- p_author_id
  'Phase9 Test User',     -- p_author_name
  'Hello from Phase 9 basic test', -- p_content
  now(),                  -- p_event_date
  NULL,                   -- p_post_id
  NULL,                   -- p_conversation_id
  '{}'::jsonb             -- p_raw_payload
) AS ingested_event;

-- 2) Route this single event
SELECT public.route_webhook_event('instagram', 'phase9_test_evt_basic_1') AS routed_payload;

-- 3) Check that the webhook_event row is now marked as routed and linked to a conversation
SELECT channel,
       event_id,
       conversation_id IS NOT NULL AS has_conversation,
       routed_at IS NOT NULL AS is_routed
FROM public.webhook_events
WHERE channel = 'instagram'
  AND event_id = 'phase9_test_evt_basic_1';

-- 4) Check that at least one message has been created for this provider_message_id
SELECT COUNT(*) AS message_count
FROM public.messages
WHERE channel = 'instagram'
  AND provider_message_id = 'phase9_test_evt_basic_1';
