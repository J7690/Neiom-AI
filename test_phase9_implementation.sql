-- Phase 9 Implementation Test
-- Batch routing via route_unrouted_events

-- 1) Ingest a small batch of webhook_events
SELECT public.ingest_webhook_event(
  'instagram', 'message', 'phase9_test_evt_batch_1', 'phase9_user_b1', 'Phase9 Batch User 1',
  'Batch message 1', now(), NULL, NULL, '{}'::jsonb
) AS evt_batch_1;

SELECT public.ingest_webhook_event(
  'instagram', 'message', 'phase9_test_evt_batch_2', 'phase9_user_b2', 'Phase9 Batch User 2',
  'Batch message 2', now(), NULL, NULL, '{}'::jsonb
) AS evt_batch_2;

SELECT public.ingest_webhook_event(
  'instagram', 'message', 'phase9_test_evt_batch_3', 'phase9_user_b3', 'Phase9 Batch User 3',
  'Batch message 3', now(), NULL, NULL, '{}'::jsonb
) AS evt_batch_3;

-- 2) Reset routed_at / conversation_id for these events so the test is repeatable
UPDATE public.webhook_events
SET routed_at = NULL,
    conversation_id = NULL
WHERE event_id LIKE 'phase9_test_evt_batch_%';

-- 3) Run batch routing (null channel = all channels)
SELECT public.route_unrouted_events(NULL, 50) AS processed_count;

-- 4) Check the routing status for the batch events
SELECT event_id,
       routed_at IS NOT NULL AS is_routed,
       conversation_id IS NOT NULL AS has_conversation
FROM public.webhook_events
WHERE event_id LIKE 'phase9_test_evt_batch_%'
ORDER BY event_id;

-- 5) Basic sanity check on messages
SELECT provider_message_id,
       COUNT(*) AS message_count
FROM public.messages
WHERE provider_message_id LIKE 'phase9_test_evt_batch_%'
GROUP BY provider_message_id
ORDER BY provider_message_id;
