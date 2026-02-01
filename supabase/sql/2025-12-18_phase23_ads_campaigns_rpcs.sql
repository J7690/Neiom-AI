-- Phase 23 – Ads campaigns RPCs (NON DESTRUCTIF)

create or replace function public.list_ad_campaigns(
  p_status text default null,
  p_limit int default 50,
  p_offset int default 0,
  p_search text default null,
  p_sort text default 'created_at_desc'
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare
  v jsonb;
  order_clause text := 'created_at desc';
  sql text;
begin
  if p_sort = 'created_at_asc' then
    order_clause := 'created_at asc';
  elsif p_sort = 'name_asc' then
    order_clause := 'name asc';
  elsif p_sort = 'name_desc' then
    order_clause := 'name desc';
  elsif p_sort = 'status_asc' then
    order_clause := 'status asc, created_at desc';
  end if;

  sql := format($f$
    select coalesce(jsonb_agg(row_to_json(c)), '[]'::jsonb)
    from (
      select id, account_id, name, objective, status, daily_budget, start_date, end_date, created_at, updated_at
      from public.ad_campaigns
      where ($1::text is null or status = $1)
        and ($2::text is null or name ilike '%%' || $2 || '%%')
      order by %s
      limit $3 offset $4
    ) c
  $f$, order_clause);

  execute sql into v using p_status, p_search, p_limit, p_offset;
  return v;
end; $$;

grant execute on function public.list_ad_campaigns(text,int,int,text,text) to anon, authenticated;

create or replace function public.update_ad_campaign_status(
  p_id uuid,
  p_status text
)
returns boolean
language plpgsql
security definer
set search_path = public as
$$
begin
  update public.ad_campaigns set status = p_status, updated_at = now() where id = p_id;
  return found;
end; $$;

grant execute on function public.update_ad_campaign_status(uuid,text) to anon, authenticated;
