-- Phase 11 Implementation Test
-- Multiple content suggestions and auto-scheduling, plus seed + auto-reply

-- 1) Generate several content suggestions with different tones
SELECT public.suggest_content_stub('Phase 11 – neutre', 'neutre', 120) AS content_neutre
UNION ALL
SELECT public.suggest_content_stub('Phase 11 – enthousiaste', 'enthousiaste', 160) AS content_enthousiaste
UNION ALL
SELECT public.suggest_content_stub('Phase 11 – professionnel', 'professionnel', 180) AS content_professionnel
UNION ALL
SELECT public.suggest_content_stub('Phase 11 – convivial', 'convivial', 140) AS content_convivial;

-- 2) Create and schedule a couple of posts
SELECT public.create_and_schedule_post_stub(
  'phase11_agent',
  'Phase 11 implementation test A',
  ARRAY['facebook'],
  now() + interval '10 minutes',
  'UTC',
  'neutre',
  150
) AS scheduled_post_a;

SELECT public.create_and_schedule_post_stub(
  'phase11_agent',
  'Phase 11 implementation test B',
  ARRAY['instagram'],
  now() + interval '15 minutes',
  'UTC',
  'convivial',
  150
) AS scheduled_post_b;

-- 3) Seed more random messages and run auto-reply on a small batch
SELECT public.seed_random_messages(ARRAY['whatsapp','instagram'], 8) AS seeded_count_impl;

SELECT public.auto_reply_recent_inbound(interval '2 hours', 20) AS auto_replied_count_impl;
