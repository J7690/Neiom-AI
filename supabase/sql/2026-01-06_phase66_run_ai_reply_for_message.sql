-- Phase 2 – Créer RPC run_ai_reply_for_message (pipeline knowledge-gated)
-- Objectif : appliquer la règle d'or (pas de réponse sans knowledge)

create or replace function public.run_ai_reply_for_message(p_message_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_msg public.messages%rowtype;
  v_rules jsonb;
  v_knowledge jsonb;
  v_context jsonb;
  v_response jsonb;
  v_mode text;
  v_reply_text text;
  v_knowledge_refs uuid[];
  v_channel text;
  v_locale text;
begin
  -- 1. Récupérer le message
  select * into v_msg from public.messages where id = p_message_id;
  if not found then
    raise exception 'message not found';
  end if;

  -- 2. Extraire le canal et la locale (stub pour l'instant)
  v_channel := coalesce(v_msg.channel, 'facebook');
  v_locale := 'fr'; -- stub, à extraire du message ou settings

  -- 3. Brand rules
  select coalesce(jsonb_agg(to_jsonb(br)), '[]'::jsonb) into v_rules
  from public.get_brand_rules(v_locale, v_channel) br;

  -- 4. Knowledge search
  select coalesce(jsonb_agg(to_jsonb(d)), '[]'::jsonb) into v_knowledge
  from public.search_knowledge(v_msg.content, 5, v_locale) d;

  -- 5. Contexte
  v_context := jsonb_build_object(
    'message', to_jsonb(v_msg),
    'brand_rules', v_rules,
    'knowledge_hits', v_knowledge
  );

  -- 6. Décision IA (stub pour l'instant, sera remplacé par edge function)
  if jsonb_array_length(v_knowledge) = 0 then
    v_mode := 'silence';
    v_reply_text := null;
    v_knowledge_refs := null;
  else
    v_mode := 'answer';
    v_reply_text := (v_knowledge->0->>'content'); -- stub
    v_knowledge_refs := array(select (d->>'id')::uuid from jsonb_array_elements(v_knowledge) d);
  end if;

  -- 7. Effets
  if v_mode = 'answer' then
    -- Créer la réponse IA
    insert into public.messages (
      channel, 
      author_id, 
      author_name, 
      content, 
      created_at, 
      answered_by_ai, 
      knowledge_hit_ids
    )
    values (
      v_msg.channel, 
      'ai', 
      'Nexiom AI', 
      v_reply_text, 
      now(), 
      true, 
      v_knowledge_refs
    );
  else
    -- Marquer comme needing human et créer une alerte
    update public.messages
      set needs_human = true,
          ai_skipped = true
      where id = p_message_id;
    
    insert into public.ai_alerts (type, message_id, created_at)
    values ('missing_knowledge', p_message_id, now());
  end if;

  -- 8. Retourner le résultat
  return jsonb_build_object(
    'mode', v_mode, 
    'reply_text', v_reply_text, 
    'knowledge_refs', v_knowledge_refs,
    'context', v_context
  );
end;
$$;

-- Grant pour les rôles Supabase
grant execute on function public.run_ai_reply_for_message(uuid) to anon, authenticated;
