create or replace function public.admin_query_sql(sql text)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_sql text;
  v_result jsonb;
begin
  v_sql := btrim(sql);

  if v_sql is null or v_sql = '' then
    raise exception 'Missing sql';
  end if;

  if right(v_sql, 1) = ';' then
    v_sql := left(v_sql, length(v_sql) - 1);
  end if;

  if position(';' in v_sql) > 0 then
    raise exception 'Multiple statements not allowed';
  end if;

  if not (v_sql ilike 'select %') then
    raise exception 'Only SELECT statements starting with SELECT are allowed';
  end if;

  if v_sql ~* '\m(insert|update|delete|merge|drop|alter|create|grant|revoke|truncate|comment|vacuum|analyze|call|do)\M' then
    raise exception 'Forbidden keyword in query';
  end if;

  execute format(
    'select coalesce(jsonb_agg(to_jsonb(t)), ''[]''::jsonb) from (%s) t',
    v_sql
  ) into v_result;

  return coalesce(v_result, '[]'::jsonb);
end;
$$;

revoke all on function public.admin_query_sql(text) from public;
revoke all on function public.admin_query_sql(text) from anon;
revoke all on function public.admin_query_sql(text) from authenticated;

grant execute on function public.admin_query_sql(text) to service_role;
