-- Fonction de debug pour voir exactement ce que retourne net.http_post
create or replace function debug_net_http_post_call()
returns jsonb
language plpgsql
security definer
as $$
declare
  res jsonb;
begin
  select to_jsonb(
    net.http_post(
      url := 'https://httpbin.org/post',
      body := jsonb_build_object('hello','world'),
      params := '{}'::jsonb,
      headers := jsonb_build_object('Content-Type','application/json'),
      timeout_milliseconds := 5000
    )
  )
  into res;

  return res;
end;
$$;

grant execute on function debug_net_http_post_call() to authenticated, anon;
