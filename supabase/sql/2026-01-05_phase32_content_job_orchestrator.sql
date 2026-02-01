-- Phase 32 – Content jobs orchestrator RPC (NON DESTRUCTIF)

create or replace function public.orchestrate_content_job_step(
  p_content_job_id uuid,
  p_step text default 'inspect',
  p_options jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_job public.content_jobs%rowtype;
  v_ctx jsonb := '{}'::jsonb;
  v_step text := lower(coalesce(p_step, 'inspect'));
begin
  select * into v_job
  from public.content_jobs
  where id = p_content_job_id;

  if not found then
    raise exception 'content_job not found';
  end if;

  if v_step = 'inspect' then
    v_ctx := jsonb_build_object('mode', 'inspect');

    if v_job.generation_job_id is not null then
      begin
        v_ctx := v_ctx || jsonb_build_object(
          'generation_job', public.get_generation_job(v_job.generation_job_id)
        );
      exception when others then
        v_ctx := v_ctx || jsonb_build_object('generation_job_error', SQLERRM);
      end;
    end if;

    begin
      v_ctx := v_ctx || jsonb_build_object('settings_overview', public.settings_overview());
    exception when others then
      v_ctx := v_ctx || jsonb_build_object('settings_overview_error', SQLERRM);
    end;

    return jsonb_build_object(
      'step', v_step,
      'content_job', to_jsonb(v_job),
      'context', v_ctx
    );
  elsif v_step = 'mark_pending_validation' then
    update public.content_jobs
    set status = 'pending_validation',
        updated_at = now()
    where id = p_content_job_id
    returning * into v_job;

    return jsonb_build_object(
      'step', v_step,
      'content_job', to_jsonb(v_job)
    );
  elsif v_step = 'mark_approved' then
    update public.content_jobs
    set status = 'approved',
        updated_at = now()
    where id = p_content_job_id
    returning * into v_job;

    return jsonb_build_object(
      'step', v_step,
      'content_job', to_jsonb(v_job)
    );
  else
    return jsonb_build_object(
      'step', v_step,
      'error', 'unknown_step',
      'message', format('Unsupported step: %s', v_step),
      'content_job', to_jsonb(v_job)
    );
  end if;
end;
$$;

grant execute on function public.orchestrate_content_job_step(uuid,text,jsonb) to anon, authenticated;
