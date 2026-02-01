-- Phase 3 – Leads & triggers (NON DESTRUCTIF)

create or replace function public.ensure_lead_on_message()
returns trigger
language plpgsql
security definer
set search_path = public as
$$
begin
  if TG_OP <> 'INSERT' then
    return NEW;
  end if;

  if NEW.direction <> 'inbound' then
    return NEW;
  end if;

  if NEW.contact_id is null then
    return NEW;
  end if;

  -- normalize channel
  declare
    src_channel text := lower(coalesce(NEW.channel, 'other'));
    lead_id uuid;
  begin
    if src_channel not in ('whatsapp','facebook','instagram','tiktok','youtube','offline','other') then
      src_channel := 'other';
    end if;

    select l.id into lead_id
    from public.leads l
    where l.contact_id = NEW.contact_id
      and l.source_channel = src_channel
    order by l.created_at desc
    limit 1;

    if lead_id is not null then
      update public.leads
      set last_contact_at = coalesce(NEW.sent_at, now()),
          status = case when status = 'new' then 'contacted' else status end,
          updated_at = now()
      where id = lead_id;
    else
      insert into public.leads (
        contact_id,
        source_channel,
        source_conversation_id,
        status,
        program_interest,
        notes,
        first_contact_at,
        last_contact_at,
        metadata
      ) values (
        NEW.contact_id,
        src_channel,
        NEW.conversation_id,
        'new',
        null,
        null,
        coalesce(NEW.sent_at, now()),
        coalesce(NEW.sent_at, now()),
        '{}'::jsonb
      );
    end if;

    return NEW;
  end;
end;
$$;

-- Create trigger if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_ensure_lead_on_message'
  ) THEN
    CREATE TRIGGER trg_ensure_lead_on_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.ensure_lead_on_message();
  END IF;
END$$;
