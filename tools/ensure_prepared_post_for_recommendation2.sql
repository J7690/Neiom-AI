create or replace function public.ensure_prepared_post_for_recommendation2(
  p_recommendation_id text
)
returns table (
  id text,
  status text,
  final_message text,
  media_url text,
  media_type text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rec studio_marketing_recommendations%rowtype;
  v_post studio_facebook_prepared_posts%rowtype;
begin
  select * into v_rec
  from studio_marketing_recommendations
  where id = p_recommendation_id::uuid;

  if not found then
    raise exception 'studio_marketing_recommendations not found for id %', p_recommendation_id;
  end if;

  select *
  into v_post
  from studio_facebook_prepared_posts
  where recommendation_id = v_rec.id
  order by created_at desc
  limit 1;

  if not found then
    insert into studio_facebook_prepared_posts (
      recommendation_id,
      final_message,
      media_url,
      media_type,
      media_generated,
      status
    ) values (
      v_rec.id,
      coalesce(v_rec.proposed_message, ''),
      null,
      coalesce(v_rec.proposed_format, 'text'),
      false,
      'ready_for_validation'
    )
    returning * into v_post;
  end if;

  return query
  select v_post.id::text, v_post.status, v_post.final_message, v_post.media_url, v_post.media_type;
end;
$$;

grant execute on function public.ensure_prepared_post_for_recommendation2(text) to anon, authenticated;
