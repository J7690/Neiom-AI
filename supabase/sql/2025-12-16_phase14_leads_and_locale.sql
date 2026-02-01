-- Phase 14 – Leads derivation + Locale-aware content stub (NON DESTRUCTIF)

create or replace function public.derive_leads_from_recent_messages(
  p_since interval default interval '7 days',
  p_limit int default 500
)
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_count int := 0;
  rec record;
  v_exists uuid;
  v_kw text[] := array['inscription','admission','candidature','frais','formation','cours','prix','tarif','diplome','bourse','inscrire'];
begin
  for rec in
    select m.id as message_id, m.contact_id, m.conversation_id, m.channel, coalesce(m.content_text,'') as txt
    from public.messages m
    where m.direction = 'inbound'
      and m.sent_at >= now() - p_since
    order by m.sent_at desc
    limit p_limit
  loop
    if rec.contact_id is null then
      continue;
    end if;

    -- keyword match
    if exists (
      select 1
      from unnest(v_kw) as kw
      where lower(rec.txt) like ('%' || kw || '%')
    ) then
      -- skip if a recent lead already exists for this contact
      select id into v_exists from public.leads
      where contact_id = rec.contact_id
      order by created_at desc
      limit 1;

      if v_exists is null then
        insert into public.leads(contact_id, source_channel, source_conversation_id, status, notes, first_contact_at, last_contact_at)
        values (rec.contact_id, rec.channel, rec.conversation_id, 'new', 'Auto: dérivé depuis message ' || rec.message_id::text, now(), now());
        v_count := v_count + 1;
      end if;
    end if;
  end loop;

  return v_count;
end;
$$;

grant execute on function public.derive_leads_from_recent_messages(interval,int) to anon, authenticated;

-- Locale-aware version of suggest_content_stub (reads DEFAULT_LOCALE and BRAND_NAME)
create or replace function public.suggest_content_stub(
  p_objective text,
  p_tone text default 'neutre',
  p_length int default 120
)
returns text
language plpgsql
security definer
set search_path = public as
$$
declare
  v_intro text;
  v_body text;
  v_cta text;
  v_text text;
  v_locale text := coalesce(public.get_setting('DEFAULT_LOCALE'), 'fr_BF');
  v_brand text := coalesce(public.get_setting('BRAND_NAME'), 'Nexiom');
  v_greeting text := case when v_locale like 'fr_%' then 'Bonjour' else 'Hello' end;
  v_suffix text := case when v_locale like 'fr_%' then ' Merci pour vos retours.' else ' Thank you for your feedback.' end;
begin
  v_intro := case lower(coalesce(p_tone,'neutre'))
    when 'enthousiaste' then '🚀 ' || v_greeting || ' !'
    when 'professionnel' then v_greeting || ' – Mise à jour'
    when 'convivial' then 'Hey 👋'
    else 'Info:'
  end;
  v_body := coalesce(p_objective, 'Découvrez nos nouveautés chez ' || v_brand || '.');
  v_cta := case when v_locale like 'fr_%' then ' Dites-nous ce que vous en pensez.' else ' Tell us what you think.' end;
  v_text := trim(v_intro || ' ' || v_body || v_cta || v_suffix);
  if length(v_text) > greatest(40, coalesce(p_length,120)) then
    v_text := substr(v_text, 1, greatest(40, coalesce(p_length,120)) - 3) || '...';
  end if;
  return v_text;
end;
$$;

grant execute on function public.suggest_content_stub(text,text,int) to anon, authenticated;
