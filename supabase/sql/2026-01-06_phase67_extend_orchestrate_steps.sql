-- Phase 3 – Étendre orchestrate_content_job_step avec steps propose_plan, generate_assets, propose_variants
-- Objectif : ajouter des steps pour planification, génération, et variantes A/B

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
  v_created_job_ids uuid[] := '{}';
  v_i int;
  v_start_date date;
  v_days int;
  v_channels text[];
  v_new_job_id uuid;
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
  elsif v_step = 'propose_plan' then
    -- Créer N content_jobs en draft à partir d'analytics/M1–M5 (stub pour l'instant)
    v_start_date := coalesce((p_options->>'start_date')::date, current_date);
    v_days := coalesce((p_options->>'days')::int, 7);
    v_channels := coalesce((p_options->>'channels')::text[], array['facebook', 'instagram']);

    for v_i in 1..v_days loop
      insert into public.content_jobs (
        objective, format, channels, origin_ui, status, author_agent, metadata
      )
      values (
        v_job.objective,
        'post',
        v_channels,
        'marketing_brain',
        'draft',
        'marketing_brain',
        jsonb_build_object(
          'date', v_start_date + (v_i - 1) * interval '1 day',
          'parent_job_id', v_job.id
        )
      )
      returning id into v_created_job_ids[v_i];
    end loop;

    v_ctx := jsonb_build_object(
      'mode', 'propose_plan',
      'created_job_ids', v_created_job_ids,
      'start_date', v_start_date,
      'days', v_days,
      'channels', v_channels
    );

    return jsonb_build_object(
      'step', v_step,
      'content_job', to_jsonb(v_job),
      'context', v_ctx
    );
  elsif v_step = 'generate_assets' then
    -- Lancer une génération (image/vidéo/audio) et lier generation_job_id (stub pour l'instant)
    -- En pratique, on appellerait une edge function pour la génération
    v_ctx := jsonb_build_object(
      'mode', 'generate_assets',
      'format', v_job.format,
      'note', 'Stub: should call generation service and update generation_job_id'
    );

    return jsonb_build_object(
      'step', v_step,
      'content_job', to_jsonb(v_job),
      'context', v_ctx
    );
  elsif v_step = 'propose_variants' then
    -- Créer plusieurs content_jobs enfants pour A/B testing (stub pour l'instant)
    v_created_job_ids := '{}';
    for v_i in 1..3 loop
      insert into public.content_jobs (
        objective, format, channels, origin_ui, status, author_agent, metadata
      )
      values (
        v_job.objective,
        v_job.format,
        v_job.channels,
        'ab_testing',
        'draft',
        'ab_testing',
        jsonb_build_object(
          'variant_letter', chr(64 + v_i), -- A, B, C
          'parent_job_id', v_job.id,
          'experiment_id', p_options->>'experiment_id'
        )
      )
      returning id into v_created_job_ids[v_i];
    end loop;

    v_ctx := jsonb_build_object(
      'mode', 'propose_variants',
      'created_variant_ids', v_created_job_ids,
      'variants_count', array_length(v_created_job_ids, 1)
    );

    return jsonb_build_object(
      'step', v_step,
      'content_job', to_jsonb(v_job),
      'context', v_ctx
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
