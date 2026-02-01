-- Phase 7c – RPC wrappers for publication without UI auth (NON DESTRUCTIF)

create or replace function public.create_social_post(
  p_author_agent text,
  p_objective text,
  p_content_text text,
  p_target_channels text[],
  p_media_paths text[] default '{}'::text[]
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare
  v_id uuid;
begin
  insert into public.social_posts(author_agent, objective, content_text, media_paths, target_channels, status)
  values (p_author_agent, p_objective, p_content_text, coalesce(p_media_paths,'{}'::text[]), p_target_channels, 'draft')
  returning id into v_id;
  return v_id;
end;
$$;

grant execute on function public.create_social_post(text,text,text,text[],text[]) to anon, authenticated;

create or replace function public.schedule_social_post(
  p_post_id uuid,
  p_scheduled_at timestamptz,
  p_timezone text default null
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare
  v_id uuid;
begin
  insert into public.social_schedules(post_id, scheduled_at, timezone, status)
  values (p_post_id, p_scheduled_at, p_timezone, 'scheduled')
  returning id into v_id;
  return v_id;
end;
$$;

grant execute on function public.schedule_social_post(uuid,timestamptz,text) to anon, authenticated;

-- Conversation status helpers
create or replace function public.resolve_conversation(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public as
$$
begin
  update public.conversations
  set status = 'closed',
      metadata = coalesce(metadata,'{}'::jsonb) - 'needs_escalation',
      updated_at = now()
  where id = p_conversation_id;
end;
$$;

grant execute on function public.resolve_conversation(uuid) to anon, authenticated;

create or replace function public.reopen_conversation(p_conversation_id uuid)
returns void
language plpgsql
security definer
set search_path = public as
$$
begin
  update public.conversations
  set status = 'open',
      updated_at = now()
  where id = p_conversation_id;
end;
$$;

grant execute on function public.reopen_conversation(uuid) to anon, authenticated;

-- Overview view for UI convenience (read-only)
create or replace view public.v_conversations_overview as
select
  c.id,
  c.channel,
  c.status,
  c.last_message_at,
  coalesce((c.metadata->>'needs_escalation')::boolean, false) as needs_escalation,
  c.contact_id
from public.conversations c;

grant select on public.v_conversations_overview to anon, authenticated;
