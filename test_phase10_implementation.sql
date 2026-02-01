-- Phase 10 Implementation Test
-- Multiple simulated comments across channels + pipeline stats breakdown

-- 1) Simulate several comments on different channels
WITH c1 AS (
  SELECT public.simulate_comment('facebook', 'phase10_fb_user', 'Phase10 FB', 'Commentaire FB Phase 10') AS p
),
 c2 AS (
  SELECT public.simulate_comment('instagram', 'phase10_ig_user', 'Phase10 IG', 'Commentaire IG Phase 10') AS p
),
 c3 AS (
  SELECT public.simulate_comment('tiktok', 'phase10_tt_user', 'Phase10 TT', 'Commentaire TikTok Phase 10') AS p
)
SELECT
  (SELECT (p->>'conversation_id') IS NOT NULL FROM c1) AS fb_has_conversation,
  (SELECT (p->>'conversation_id') IS NOT NULL FROM c2) AS ig_has_conversation,
  (SELECT (p->>'conversation_id') IS NOT NULL FROM c3) AS tt_has_conversation;

-- 2) Call pipeline stats and project some top-level metrics
WITH stats AS (
  SELECT public.get_pipeline_stats() AS s
)
SELECT
  (s->'contacts')::text              AS contacts_total,
  (s->'webhook_events'->'total')::text   AS webhook_total,
  (s->'webhook_events'->'unrouted')::text AS webhook_unrouted,
  (s->'messages'->'total')::text     AS messages_total,
  (s->'leads')::text                 AS leads_by_status
FROM stats;
