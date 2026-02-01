-- Phase 24 – Advisor weekly report (stub notify)

create or replace function public.notify_weekly_report_stub(
  p_emails text[],
  p_body text,
  p_period jsonb default '{}'::jsonb
)
returns int
language plpgsql
security definer
set search_path = public as
$$
declare v_cnt int := 0; begin
  v_cnt := coalesce(array_length(p_emails,1),0);
  perform public.log_event(
    'advisor',
    'info',
    'Weekly report generated (stub notify)',
    jsonb_build_object('emails', p_emails, 'body', p_body, 'period', p_period)
  );
  return v_cnt;
end; $$;

grant execute on function public.notify_weekly_report_stub(text[],text,jsonb) to anon, authenticated;
