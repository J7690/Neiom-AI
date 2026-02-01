-- Phase 4 – Créer RPC create_content_jobs_from_objective (Marketing Brain)
-- Objectif : permettre au Marketing Brain de créer des content_jobs à partir d'un objectif

create or replace function public.create_content_jobs_from_objective(
  p_objective text,
  p_start_date date,
  p_days int,
  p_channels text[],
  p_timezone text default 'UTC',
  p_tone text default 'neutre',
  p_length int default 120,
  p_author_agent text default 'marketing_brain'
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_job_ids uuid[] := '{}';
  v_i int;
  v_current_date date;
  v_job_id uuid;
begin
  -- Validation des paramètres
  if p_objective is null or trim(p_objective) = '' then
    raise exception 'objective cannot be null or empty';
  end if;
  
  if p_start_date is null then
    v_current_date := current_date;
  else
    v_current_date := p_start_date;
  end if;
  
  if p_days is null or p_days <= 0 then
    raise exception 'days must be a positive integer';
  end if;
  
  if p_channels is null or array_length(p_channels, 1) is null then
    p_channels := array['facebook', 'instagram'];
  end if;

  -- Créer les content_jobs
  for v_i in 1..p_days loop
    insert into public.content_jobs (
      objective,
      format,
      channels,
      origin_ui,
      status,
      author_agent,
      metadata
    )
    values (
      p_objective,
      'post',
      p_channels,
      'marketing_brain',
      'draft',
      p_author_agent,
      jsonb_build_object(
        'date', v_current_date + (v_i - 1) * interval '1 day',
        'timezone', p_timezone,
        'tone', p_tone,
        'length', p_length,
        'day_index', v_i
      )
    )
    returning id into v_job_id;
    
    v_job_ids[v_i] := v_job_id;
  end loop;

  return jsonb_build_object(
    'created_job_ids', v_job_ids,
    'objective', p_objective,
    'start_date', v_current_date,
    'days', p_days,
    'channels', p_channels,
    'timezone', p_timezone,
    'tone', p_tone,
    'length', p_length,
    'author_agent', p_author_agent,
    'created_count', array_length(v_job_ids, 1)
  );
end;
$$;

grant execute on function public.create_content_jobs_from_objective(text, date, int, text[], text, text, int, text) to anon, authenticated;
