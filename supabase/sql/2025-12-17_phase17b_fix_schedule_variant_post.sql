-- Phase 17b – Fix schedule_variant_post parameter order (NON DESTRUCTIF)

create or replace function public.schedule_variant_post(
  p_variant_id uuid,
  p_schedule_at timestamptz,
  p_timezone text default 'UTC'
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_var record;
  v_post_id uuid;
  v_sched_id uuid;
begin
  select * into v_var from public.experiment_variants where id = p_variant_id;
  if not found then raise exception 'variant not found'; end if;
  -- Correct parameter order: (author, objective, content_text, target_channels, media_paths)
  v_post_id := public.create_social_post(
    'agent:ab',
    coalesce((select objective from public.experiments where id = v_var.experiment_id),'AB Test'),
    v_var.content_text,
    v_var.target_channels,
    '{}'::text[]
  );
  v_sched_id := public.schedule_social_post(v_post_id, p_schedule_at, p_timezone);
  update public.experiment_variants set post_id = v_post_id, status = 'scheduled', updated_at = now() where id = p_variant_id;
  return jsonb_build_object('post_id', v_post_id, 'schedule_id', v_sched_id);
end; $$;

grant execute on function public.schedule_variant_post(uuid,timestamptz,text) to anon, authenticated;
