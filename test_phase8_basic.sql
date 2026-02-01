-- Phase 8 Basic Test Script
-- Basic checks and simple RPC calls for activation orchestration

-- 1) List activation tables
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'studio_activation_channels',
    'studio_activation_scenarios',
    'studio_activation_executions',
    'studio_channel_messages_outbox'
)
ORDER BY table_name;

-- 2) Test create_activation_channel (may be run multiple times safely)
SELECT * FROM public.create_activation_channel(
  'Test WhatsApp Channel',
  'whatsapp',
  'meta',
  '{"description": "Test Phase 8 channel"}'::jsonb
);

-- 3) Test create_activation_scenario
SELECT * FROM public.create_activation_scenario(
  'Auto-reply incoming questions',
  'Auto-reply for question intents on any channel',
  'incoming_message',
  NULL,
  '{"require_escalation": false}'::jsonb,
  'auto_reply',
  '{"fallback_message": "Merci pour votre message, nous revenons vers vous."}'::jsonb,
  5
);

-- 4) Check outbox view
SELECT *
FROM studio_channel_messages_outbox
ORDER BY created_at DESC
LIMIT 20;
