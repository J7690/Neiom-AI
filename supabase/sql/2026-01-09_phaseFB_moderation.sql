-- Phase FB – Flux de modération des commentaires Facebook
-- Objectif : ajouter un statut de modération aux commentaires et exposer
-- une file d'attente + actions via RPC.

-- 1) Étendre la table facebook_comments avec des colonnes de modération
alter table public.facebook_comments
  add column if not exists moderation_status text not null default 'pending'
    check (moderation_status in ('pending','handled','ignored','escalated')),
  add column if not exists last_action_at timestamptz;

-- 2) Table d'historique des actions de modération
create table if not exists public.facebook_comment_actions (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.facebook_comments(id) on delete cascade,
  action_type text not null,
  actor text,
  notes text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table if exists public.facebook_comment_actions enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'facebook_comment_actions'
      and policyname = 'facebook_comment_actions_select_all'
  ) then
    create policy facebook_comment_actions_select_all
      on public.facebook_comment_actions
      for select using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'facebook_comment_actions'
      and policyname = 'facebook_comment_actions_insert_all'
  ) then
    create policy facebook_comment_actions_insert_all
      on public.facebook_comment_actions
      for insert with check (true);
  end if;
end$$;

grant select, insert on public.facebook_comment_actions to anon, authenticated;

-- 3) RPC : récupérer les commentaires en attente de modération
create or replace function public.get_pending_facebook_comments(
  p_limit integer default 50
)
returns table (
  id uuid,
  facebook_post_id text,
  facebook_comment_id text,
  message text,
  from_name text,
  from_id text,
  created_time timestamptz,
  like_count integer,
  moderation_status text
)
language sql
security definer
set search_path = public as
$$
  select
    fc.id,
    fc.facebook_post_id,
    fc.facebook_comment_id,
    fc.message,
    fc.from_name,
    fc.from_id,
    fc.created_time,
    fc.like_count,
    fc.moderation_status
  from public.facebook_comments fc
  where fc.moderation_status = 'pending'
  order by fc.created_time desc nulls last, fc.created_at desc
  limit p_limit
$$;

grant execute on function public.get_pending_facebook_comments(integer) to anon, authenticated;

-- 4) RPC : marquer un commentaire comme traité/ignoré/escaladé
create or replace function public.mark_facebook_comment_moderation(
  p_comment_id uuid,
  p_status text,
  p_action_type text default 'mark',
  p_actor text default 'studio_user',
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_old_status text;
begin
  if p_status not in ('pending','handled','ignored','escalated') then
    raise exception 'Invalid moderation status: %', p_status;
  end if;

  select moderation_status into v_old_status
  from public.facebook_comments
  where id = p_comment_id;

  if not found then
    return jsonb_build_object('success', false, 'message', 'comment not found');
  end if;

  update public.facebook_comments
    set moderation_status = p_status,
        last_action_at = now()
    where id = p_comment_id;

  insert into public.facebook_comment_actions(
    comment_id,
    action_type,
    actor,
    notes,
    metadata
  ) values (
    p_comment_id,
    p_action_type,
    p_actor,
    p_notes,
    jsonb_build_object('previous_status', v_old_status, 'new_status', p_status)
  );

  return jsonb_build_object('success', true, 'new_status', p_status);
end;
$$;

grant execute on function public.mark_facebook_comment_moderation(uuid,text,text,text,text) to anon, authenticated;
