-- Phase 18 – Meta/IG Integration scaffold: connections, queue, retries, staging/prod (NON DESTRUCTIF)

-- 1) Extend social_channels metadata usage; add oauth fields (optional)
alter table if exists public.social_channels
  add column if not exists oauth_status text default 'unknown',
  add column if not exists expires_at timestamptz,
  add column if not exists last_checked_at timestamptz;

-- 2) Publish queue with retries/backoff
create table if not exists public.publish_queue (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.social_posts(id) on delete cascade,
  channel text not null check (channel in ('whatsapp','facebook','instagram','tiktok','youtube')),
  status text not null default 'queued' check (status in ('queued','processing','success','error','giveup')),
  attempt_no int not null default 0,
  next_retry_at timestamptz not null default now(),
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists publish_queue_due_idx on public.publish_queue (next_retry_at, status);
create index if not exists publish_queue_post_channel_idx on public.publish_queue (post_id, channel);

alter table public.publish_queue enable row level security;
revoke all on table public.publish_queue from anon;
grant select on table public.publish_queue to authenticated;

-- 3) Helper: read boolean setting
create or replace function public.get_bool_setting(p_key text, p_default boolean)
returns boolean
language plpgsql
security definer
stable
set search_path = public as
$$
declare v text; begin
  select value into v from public.app_settings where key = p_key;
  if v is null then return p_default; end if;
  return lower(v) in ('1','true','yes','on');
end; $$;

grant execute on function public.get_bool_setting(text,boolean) to anon, authenticated;

-- 4) Channels RPCs
create or replace function public.upsert_social_channel(
  p_channel_type text,
  p_entity text,
  p_display_name text,
  p_status text default 'active',
  p_provider_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare v_row public.social_channels%rowtype; begin
  insert into public.social_channels(channel_type, entity, display_name, status, provider_metadata)
  values (lower(p_channel_type), p_entity, p_display_name, coalesce(p_status,'active'), coalesce(p_provider_metadata,'{}'::jsonb))
  on conflict (id) do nothing;
  -- If a row already exists for (channel_type, entity), update metadata; else insert
  update public.social_channels
  set display_name = coalesce(p_display_name, display_name),
      status = coalesce(p_status, status),
      provider_metadata = coalesce(p_provider_metadata,'{}'::jsonb),
      updated_at = now()
  where id in (
    select id from public.social_channels where channel_type = lower(p_channel_type) and coalesce(entity,'') = coalesce(p_entity,'')
    order by created_at asc
    limit 1
  )
  returning * into v_row;

  if v_row.id is null then
    insert into public.social_channels(channel_type, entity, display_name, status, provider_metadata)
    values (lower(p_channel_type), p_entity, p_display_name, coalesce(p_status,'active'), coalesce(p_provider_metadata,'{}'::jsonb))
    returning * into v_row;
  end if;
  return to_jsonb(v_row);
end; $$;

grant execute on function public.upsert_social_channel(text,text,text,text,jsonb) to anon, authenticated;

create or replace function public.list_social_channels()
returns jsonb
language sql
security definer
stable
set search_path = public as
$$
  select coalesce(jsonb_agg(row_to_json(sc) order by sc.created_at desc), '[]'::jsonb)
  from public.social_channels sc;
$$;

grant execute on function public.list_social_channels() to anon, authenticated;

-- 5) Enqueue publication for a post
create or replace function public.enqueue_publish_for_post(p_post_id uuid)
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_post record;
  ch text;
  v_cnt int := 0;
begin
  select id, target_channels from public.social_posts where id = p_post_id into v_post;
  if not found then raise exception 'post not found'; end if;
  foreach ch in array coalesce(v_post.target_channels, '{}'::text[]) loop
    if not exists (
      select 1 from public.publish_queue where post_id = p_post_id and channel = ch and status in ('queued','processing')
    ) then
      insert into public.publish_queue(post_id, channel, status, attempt_no, next_retry_at)
      values (p_post_id, ch, 'queued', 0, now());
      v_cnt := v_cnt + 1;
    end if;
  end loop;
  return v_cnt;
end; $$;

grant execute on function public.enqueue_publish_for_post(uuid) to anon, authenticated;

-- 6) Channel publish dispatcher (stub + staging guard)
create or replace function public.publish_to_channel_stub(p_post_id uuid, p_channel text)
returns boolean
language plpgsql
security definer
set search_path = public as
$$
declare
  v_post record;
  v_staging boolean;
  v_msg text;
begin
  select id, content_text, target_channels into v_post from public.social_posts where id = p_post_id;
  if not found then raise exception 'post not found'; end if;

  -- content policy check (reuse existing function)
  if not (public.content_policy_check(coalesce(v_post.content_text,''), null)->>'allowed')::boolean then
    insert into public.publish_logs(post_id, channel, status, error_message, provider_response)
    values (p_post_id, p_channel, 'error', 'Blocked by content policy', '{}'::jsonb);
    return false;
  end if;

  v_staging := public.get_bool_setting('STAGING_MODE', true);

  if v_staging then
    insert into public.publish_logs(post_id, channel, status, error_message, provider_response)
    values (p_post_id, p_channel, 'success', 'staging no-op', jsonb_build_object('mode','staging'));
    return true;
  else
    -- TODO: implement real Meta/IG calls when secrets available
    insert into public.publish_logs(post_id, channel, status, error_message, provider_response)
    values (p_post_id, p_channel, 'error', 'Real provider publish not implemented', '{}'::jsonb);
    return false;
  end if;
end; $$;

grant execute on function public.publish_to_channel_stub(uuid,text) to anon, authenticated;

-- 7) Run publish queue once with exponential backoff
create or replace function public.run_publish_queue_once(p_limit int default 10)
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cnt int := 0;
  rec record;
  v_ok boolean;
  v_backoff_seconds int;
begin
  for rec in
    select * from public.publish_queue
    where status in ('queued','error') and next_retry_at <= now()
    order by next_retry_at asc
    limit p_limit
  loop
    update public.publish_queue set status = 'processing', updated_at = now(), attempt_no = attempt_no + 1 where id = rec.id;
    begin
      v_ok := public.publish_to_channel_stub(rec.post_id, rec.channel);
      if v_ok then
        update public.publish_queue set status = 'success', updated_at = now() where id = rec.id;
      else
        v_backoff_seconds := least(3600, (2 ^ greatest(0, rec.attempt_no)) * 30);
        update public.publish_queue
          set status = 'error',
              next_retry_at = now() + make_interval(secs => v_backoff_seconds),
              updated_at = now()
          where id = rec.id;
      end if;
    exception when others then
      v_backoff_seconds := least(3600, (2 ^ greatest(0, rec.attempt_no)) * 30);
      update public.publish_queue
        set status = 'error',
            last_error = sqlerrm,
            next_retry_at = now() + make_interval(secs => v_backoff_seconds),
            updated_at = now()
        where id = rec.id;
    end;

    -- If all channels for this post have at least one success, mark as published
    if not exists (
      select 1 from (
        select unnest(sp.target_channels) ch from public.social_posts sp where sp.id = rec.post_id
      ) t
      where not exists (
        select 1 from public.publish_logs pl where pl.post_id = rec.post_id and pl.channel = t.ch and pl.status = 'success'
      )
    ) then
      update public.social_posts set status = 'published', updated_at = now() where id = rec.post_id and status <> 'published';
    end if;

    v_cnt := v_cnt + 1;
  end loop;
  return v_cnt;
end; $$;

grant execute on function public.run_publish_queue_once(int) to anon, authenticated;

-- 8) High-level publish_post: enqueue or staging-direct
create or replace function public.publish_post(p_post_id uuid)
returns text
language plpgsql
security definer
set search_path = public as
$$
declare
  v_post record;
  v_staging boolean;
  v_enq int := 0;
  ch text;
begin
  select id, target_channels into v_post from public.social_posts where id = p_post_id;
  if not found then raise exception 'post not found'; end if;

  if not (public.content_policy_check(coalesce((select content_text from public.social_posts where id = p_post_id),''), null)->>'allowed')::boolean then
    return 'blocked_by_policy';
  end if;

  v_staging := public.get_bool_setting('STAGING_MODE', true);
  if v_staging then
    -- Direct publish success per channel (no-op)
    foreach ch in array v_post.target_channels loop
      perform public.publish_to_channel_stub(p_post_id, ch);
    end loop;
    return 'staging_published';
  else
    v_enq := public.enqueue_publish_for_post(p_post_id);
    return 'enqueued_' || v_enq;
  end if;
end; $$;

grant execute on function public.publish_post(uuid) to anon, authenticated;

-- 9) Messaging reply via channel (stub)
create or replace function public.send_channel_reply_stub(
  p_conversation_id uuid,
  p_text text
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
begin
  -- For staging mode, just use respond_with_stub and log
  perform public.log_event('send_reply','info','Reply via channel (stub)', jsonb_build_object('conversation_id', p_conversation_id));
  return public.respond_with_stub(p_conversation_id, p_text);
end; $$;

grant execute on function public.send_channel_reply_stub(uuid,text) to anon, authenticated;
