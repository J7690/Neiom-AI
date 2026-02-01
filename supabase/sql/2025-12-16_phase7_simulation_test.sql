DO $$
DECLARE
  v jsonb;
  conv uuid;
  msg uuid;
  v2 jsonb;
  conv2 uuid;
  msg2 uuid;
  p_id uuid;
  s_id uuid;
  m_count integer;
BEGIN
  -- Simulate WhatsApp message (no external app required)
  v := public.simulate_message('whatsapp', 'wa_+33601020304', 'Jean Dupont', 'Bonjour, j''ai besoin d''aide urgent ?', null, now());
  RAISE NOTICE 'simulate_message whatsapp => %', v;
  conv := (v->>'conversation_id')::uuid;
  msg := (v->>'message_id')::uuid;

--   -- Simulate Facebook message
--   v2 := public.simulate_message('facebook', 'fb_123', 'Alice', 'Hello, any update?', null, now());
--   RAISE NOTICE 'simulate_message facebook => %', v2;
--   conv2 := (v2->>'conversation_id')::uuid;
--   msg2 := (v2->>'message_id')::uuid;

--   -- Mark escalation on first conversation
--   PERFORM public.set_conversation_escalation(conv, true);

--   -- Send stub outbound response
--   PERFORM public.respond_with_stub(conv, 'Bonjour Jean, notre équipe va vous aider.');

--   -- Create a social post and schedule now (publication will stub to failed with logs)
--   INSERT INTO public.social_posts(author_agent, objective, content_text, target_channels, status)
--   VALUES ('agent:nexiom', 'test publication', 'Ceci est un post de test', ARRAY['facebook','instagram'], 'draft')
--   RETURNING id INTO p_id;
  INSERT INTO public.social_posts(author_agent, objective, content_text, target_channels, status)
  VALUES ('agent:nexiom', 'test publication', 'Ceci est un post de test', ARRAY['facebook','instagram'], 'draft')
  RETURNING id INTO p_id;

  -- immediate schedule
  INSERT INTO public.social_schedules(post_id, scheduled_at, timezone, status)
  VALUES (p_id, now(), 'Europe/Paris', 'scheduled') RETURNING id INTO s_id;

  -- Run schedules once (will call publish_post_stub internally)
  PERFORM public.run_schedules_once();

  -- Collect metrics stub entries
  m_count := public.collect_metrics_stub();
  RAISE NOTICE 'collect_metrics_stub inserted rows: %', m_count;
END$$;
