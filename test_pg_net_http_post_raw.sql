-- Test brut de net.http_post pour inspecter la structure de réponse
select *
from net.http_post(
  url := 'https://httpbin.org/post',
  body := jsonb_build_object('hello','world'),
  params := '{}'::jsonb,
  headers := jsonb_build_object('Content-Type','application/json'),
  timeout_milliseconds := 5000
);
