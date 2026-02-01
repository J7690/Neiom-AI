-- Phase 29 – Brand rules CRUD enhancements (list + delete)

create or replace function public.list_brand_rules(
  p_limit int default 100
)
returns jsonb
language sql
security definer
stable
set search_path = public as
$$
  select coalesce(jsonb_agg(to_jsonb(b)), '[]'::jsonb)
  from (
    select * from public.brand_rules
    order by locale asc
    limit p_limit
  ) b;
$$;

grant execute on function public.list_brand_rules(int) to anon, authenticated;

create or replace function public.delete_brand_rules(
  p_locale text
)
returns boolean
language plpgsql
security definer
set search_path = public as
$$
begin
  delete from public.brand_rules where locale = lower(p_locale);
  return true;
end; $$;

grant execute on function public.delete_brand_rules(text) to anon, authenticated;
