-- Admin SQL executor function for development (used via REST /rpc/admin_execute_sql)
create or replace function public.admin_execute_sql(sql text)
returns void
language plpgsql
security definer
set search_path = public as
$$
begin
  execute sql;
end;
$$;

-- lock down access: no direct calls from anon/authenticated/public
revoke all on function public.admin_execute_sql(text) from public;
revoke all on function public.admin_execute_sql(text) from anon;
revoke all on function public.admin_execute_sql(text) from authenticated;
