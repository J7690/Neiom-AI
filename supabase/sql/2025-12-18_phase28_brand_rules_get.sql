-- Phase 28 – Brand rules getter (NON DESTRUCTIF)

create or replace function public.get_brand_rules(p_locale text)
returns jsonb
language sql
security definer
stable
set search_path = public as
$$
  select to_jsonb(b)
  from public.brand_rules b
  where b.locale = lower(p_locale)
  limit 1;
$$;

grant execute on function public.get_brand_rules(text) to anon, authenticated;
