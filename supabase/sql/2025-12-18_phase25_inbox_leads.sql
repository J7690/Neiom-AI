-- Phase 25 – Inbox leads from conversation (NON DESTRUCTIF)

create or replace function public.create_lead_from_conversation(
  p_conversation_id uuid,
  p_program_interest text default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare
  v_contact_id uuid;
  v_channel text;
  v_first timestamptz;
  v_last timestamptz;
  v_lead_id uuid;
  v_existing uuid;
begin
  select contact_id, channel into v_contact_id, v_channel
  from public.conversations where id = p_conversation_id;
  if not found then raise exception 'conversation not found'; end if;

  if v_contact_id is null then
    select contact_id into v_contact_id
    from public.messages
    where conversation_id = p_conversation_id and contact_id is not null
    order by sent_at asc
    limit 1;
  end if;
  if v_contact_id is null then raise exception 'no contact for conversation %', p_conversation_id; end if;

  select id into v_existing from public.leads where source_conversation_id = p_conversation_id limit 1;
  select min(sent_at), max(sent_at) into v_first, v_last from public.messages where conversation_id = p_conversation_id;

  if v_existing is not null then
    update public.leads
      set program_interest = coalesce(p_program_interest, program_interest),
          notes = coalesce(case when p_notes is null then notes else (coalesce(notes,'')||'\n'||p_notes) end, notes),
          last_contact_at = coalesce(v_last, last_contact_at),
          updated_at = now()
      where id = v_existing
      returning id into v_lead_id;
  else
    insert into public.leads(
      contact_id, source_channel, source_conversation_id, status,
      program_interest, notes, first_contact_at, last_contact_at
    ) values (
      v_contact_id, v_channel, p_conversation_id, 'new',
      p_program_interest, p_notes, v_first, v_last
    ) returning id into v_lead_id;
  end if;

  return v_lead_id;
end; $$;

grANT execute on function public.create_lead_from_conversation(uuid,text,text) to anon, authenticated;
