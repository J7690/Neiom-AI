-- Phase 11 Basic Test
-- Simple calls to content suggestion and scheduling + seed + auto-reply

-- 1) Suggest a single content stub
SELECT public.suggest_content_stub(
  'Annonce Phase 11: outils sans secrets',
  'neutre',
  140
) AS suggested_content;

-- 2) Create and schedule a post stub
SELECT public.create_and_schedule_post_stub(
  'phase11_agent',
  'Phase 11 test: auto-planification',
  ARRAY['facebook','instagram'],
  now() + interval '5 minutes',
  'UTC',
  'enthousiaste',
  160
) AS scheduled_post;

-- 3) Seed a few random inbound messages
SELECT public.seed_random_messages(ARRAY['whatsapp','facebook'], 5) AS seeded_count;

-- 4) Auto reply to recent inbound messages (non-assertive, just returns count)
SELECT public.auto_reply_recent_inbound(interval '1 hour', 10) AS auto_replied_count;
