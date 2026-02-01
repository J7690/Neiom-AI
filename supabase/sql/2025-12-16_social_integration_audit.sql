-- Audit Social Integration – Vérifie la présence des tables et colonnes clés pour la messagerie multicanal.
-- IMPORTANT : aucune modification de schéma. Lève une exception si des éléments manquent.

DO $$
DECLARE
  missing text := '';
BEGIN
  -- Tables requises
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'contacts'
  ) THEN
    missing := missing || 'missing table public.contacts; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'contact_channels'
  ) THEN
    missing := missing || 'missing table public.contact_channels; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'conversations'
  ) THEN
    missing := missing || 'missing table public.conversations; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'messages'
  ) THEN
    missing := missing || 'missing table public.messages; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'leads'
  ) THEN
    missing := missing || 'missing table public.leads; ';
  END IF;

  -- Colonnes critiques: contacts
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'contacts' AND column_name = 'whatsapp_phone'
  ) THEN
    missing := missing || 'missing column contacts.whatsapp_phone; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'contacts' AND column_name = 'created_at'
  ) THEN
    missing := missing || 'missing column contacts.created_at; ';
  END IF;

  -- Colonnes critiques: contact_channels
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'contact_channels' AND column_name = 'contact_id'
  ) THEN
    missing := missing || 'missing column contact_channels.contact_id; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'contact_channels' AND column_name = 'channel'
  ) THEN
    missing := missing || 'missing column contact_channels.channel; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'contact_channels' AND column_name = 'external_id'
  ) THEN
    missing := missing || 'missing column contact_channels.external_id; ';
  END IF;

  -- Colonnes critiques: conversations
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'conversations' AND column_name = 'contact_id'
  ) THEN
    missing := missing || 'missing column conversations.contact_id; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'conversations' AND column_name = 'channel'
  ) THEN
    missing := missing || 'missing column conversations.channel; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'conversations' AND column_name = 'status'
  ) THEN
    missing := missing || 'missing column conversations.status; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'conversations' AND column_name = 'last_message_at'
  ) THEN
    missing := missing || 'missing column conversations.last_message_at; ';
  END IF;

  -- Colonnes critiques: messages
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'conversation_id'
  ) THEN
    missing := missing || 'missing column messages.conversation_id; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'channel'
  ) THEN
    missing := missing || 'missing column messages.channel; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'direction'
  ) THEN
    missing := missing || 'missing column messages.direction; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'message_type'
  ) THEN
    missing := missing || 'missing column messages.message_type; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'content_text'
  ) THEN
    missing := missing || 'missing column messages.content_text; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'provider_message_id'
  ) THEN
    missing := missing || 'missing column messages.provider_message_id; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'sent_at'
  ) THEN
    missing := missing || 'missing column messages.sent_at; ';
  END IF;

  -- Colonnes critiques: leads
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'leads' AND column_name = 'contact_id'
  ) THEN
    missing := missing || 'missing column leads.contact_id; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'leads' AND column_name = 'source_channel'
  ) THEN
    missing := missing || 'missing column leads.source_channel; ';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'leads' AND column_name = 'status'
  ) THEN
    missing := missing || 'missing column leads.status; ';
  END IF;

  IF missing <> '' THEN
    RAISE EXCEPTION 'SOCIAL_INTEGRATION_AUDIT_ERRORS: %', missing;
  END IF;
END;
$$;
