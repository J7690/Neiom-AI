create or replace function public.get_marketing_objective_state()
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_obj jsonb;
begin
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', id::text,
        'objective', objective,
        'target_value', target_value,
        'current_value', current_value,
        'unit', unit,
        'horizon', horizon,
        'status', status,
        'start_date', start_date,
        'target_date', target_date,
        'progress_percentage', progress_percentage
      )
    ),
    '[]'::jsonb
  )
  into v_obj
  from public.studio_marketing_objectives
  where status = 'active';

  return jsonb_build_object(
    'objectives', v_obj,
    'generated_at', now()
  );
end;
$$;

grant execute on function public.get_marketing_objective_state() to anon, authenticated;
