-- Phase 16b – Intégration content policy dans publish_post_stub (NON DESTRUCTIF)

create or replace function public.publish_post_stub(
  p_post_id uuid
)
returns void
language plpgsql
security definer
set search_path = public as
$$
DECLARE
  v_post record;
  ch text;
  v_policy jsonb;
  v_allowed boolean := true;
BEGIN
  select id, target_channels, coalesce(content_text,'') as content_text into v_post from public.social_posts where id = p_post_id;
  if not found then raise exception 'post not found'; end if;

  -- Content policy check (soft guard here, fail fast if not allowed)
  v_policy := public.content_policy_check(v_post.content_text, null);
  v_allowed := coalesce((v_policy->>'allowed')::boolean, true);

  if not v_allowed then
    update public.social_posts set status = 'failed', updated_at = now() where id = p_post_id;
    perform public.record_alert('content_policy_violation','error','Post blocked by policy', jsonb_build_object('post_id', p_post_id, 'policy', v_policy));
    foreach ch in array coalesce(v_post.target_channels, '{}'::text[]) loop
      insert into public.publish_logs(post_id, channel, status, error_message, provider_response)
      values (p_post_id, ch, 'error', 'Blocked by content policy', jsonb_build_object('policy', v_policy));
    end loop;
    return;
  end if;

  update public.social_posts set status = 'publishing', updated_at = now() where id = p_post_id;

  foreach ch in array coalesce(v_post.target_channels, '{}'::text[]) loop
    insert into public.publish_logs(post_id, channel, status, error_message, provider_response)
    values (p_post_id, ch, 'error', 'Provider tokens not configured', '{}'::jsonb);
  end loop;

  update public.social_posts set status = 'failed', updated_at = now() where id = p_post_id;
END;
$$;

revoke all on function public.publish_post_stub(uuid) from public;
grant execute on function public.publish_post_stub(uuid) to anon, authenticated;
