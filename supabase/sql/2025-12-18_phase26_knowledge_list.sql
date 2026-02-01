-- Phase 26 – Knowledge listing & preview (NON DESTRUCTIF)

create or replace function public.list_documents(
  p_locale text default null,
  p_tag text default null,
  p_limit int default 50
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select coalesce(jsonb_agg(x), '[]'::jsonb) into v from (
    select jsonb_build_object(
      'id', d.id,
      'title', d.title,
      'locale', d.locale,
      'created_at', d.created_at,
      'tags', case when (d.metadata ? 'tags') then d.metadata->'tags' else '[]'::jsonb end
    ) as x
    from public.documents d
    where (p_locale is null or lower(d.locale) = lower(p_locale))
      and (p_tag is null or exists (
        select 1
        from jsonb_array_elements_text(coalesce(d.metadata->'tags','[]'::jsonb)) as t(tag)
        where lower(t.tag) = lower(p_tag)
      ))
    order by d.created_at desc
    limit p_limit
  ) t;
  return v;
end; $$;

grant execute on function public.list_documents(text,text,int) to anon, authenticated;

create or replace function public.get_document(
  p_id uuid
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select to_jsonb(d) into v from public.documents d where d.id = p_id;
  if v is null then raise exception 'document not found'; end if;
  return v;
end; $$;

grant execute on function public.get_document(uuid) to anon, authenticated;
