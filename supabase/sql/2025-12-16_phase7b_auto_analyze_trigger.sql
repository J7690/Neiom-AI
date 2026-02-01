-- Phase 7b – Auto analysis trigger on inbound messages (NON DESTRUCTIF)

-- Ensure unique per message
create unique index if not exists message_analysis_message_id_unique on public.message_analysis(message_id);

create or replace function public.auto_analyze_on_message()
returns trigger
language plpgsql
security definer
set search_path = public as
$$
begin
  if TG_OP <> 'INSERT' then
    return NEW;
  end if;

  if NEW.direction = 'inbound' and NEW.content_text is not null then
    -- Only analyze if not already analyzed
    if not exists (select 1 from public.message_analysis ma where ma.message_id = NEW.id) then
      perform public.analyze_message_simple(NEW.id);
    end if;
  end if;

  return NEW;
end;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_auto_analyze_on_message'
  ) THEN
    CREATE TRIGGER trg_auto_analyze_on_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_analyze_on_message();
  END IF;
END$$;
