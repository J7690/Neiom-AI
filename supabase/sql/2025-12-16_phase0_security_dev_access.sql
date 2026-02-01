-- Dev access to keep Flutter UI working without auth while RLS is enabled
-- Allow anon to SELECT on messaging tables (temporary until auth is added)
revoke all on table public.conversations from anon;
revoke all on table public.messages from anon;
revoke all on table public.leads from anon;

grant select on table public.conversations to anon;
grant select on table public.messages to anon;
grant select on table public.leads to anon;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'conversations' AND policyname = 'conversations_select_anon'
  ) THEN
    CREATE POLICY conversations_select_anon
      ON public.conversations
      FOR SELECT
      TO anon
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'messages' AND policyname = 'messages_select_anon'
  ) THEN
    CREATE POLICY messages_select_anon
      ON public.messages
      FOR SELECT
      TO anon
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'leads' AND policyname = 'leads_select_anon'
  ) THEN
    CREATE POLICY leads_select_anon
      ON public.leads
      FOR SELECT
      TO anon
      USING (true);
  END IF;
END$$;
