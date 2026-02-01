-- Phase 0 – Sécurité & Idempotence (NON DESTRUCTIF, prêt pour RPC admin)
-- 1) Idempotence des messages (évite doublons par provider)
create unique index if not exists messages_channel_provider_message_id_unique
  on public.messages (channel, provider_message_id)
  where provider_message_id is not null;

-- 2) Activer RLS (lecture côté client authentifié, écritures par Edge/service_role)
alter table if exists public.conversations enable row level security;
alter table if exists public.messages enable row level security;
alter table if exists public.leads enable row level security;

-- 3) Restreindre les privilèges anon, autoriser authenticated en lecture
revoke all on table public.conversations from anon;
revoke all on table public.messages from anon;
revoke all on table public.leads from anon;

grant select on table public.conversations to authenticated;
grant select on table public.messages to authenticated;
grant select on table public.leads to authenticated;

-- 4) Politiques RLS (créées uniquement si absentes)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'conversations' AND policyname = 'conversations_select_authenticated'
  ) THEN
    CREATE POLICY conversations_select_authenticated
      ON public.conversations
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'messages' AND policyname = 'messages_select_authenticated'
  ) THEN
    CREATE POLICY messages_select_authenticated
      ON public.messages
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'leads' AND policyname = 'leads_select_authenticated'
  ) THEN
    CREATE POLICY leads_select_authenticated
      ON public.leads
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END$$;
