-- Phase FB – Annulation d'une planification sociale (social_schedules)
-- Objectif : permettre à l'UI (Calendrier) d'annuler une planification programmée
-- sans casser la cohérence des tables social_schedules, social_posts et content_jobs.

create or replace function public.cancel_social_schedule(
  p_schedule_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_sched  public.social_schedules%rowtype;
  v_post   public.social_posts%rowtype;
  v_job    public.content_jobs%rowtype;
begin
  if p_schedule_id is null then
    raise exception 'p_schedule_id is required';
  end if;

  -- 1) Récupérer le schedule et le post associé
  select * into v_sched
  from public.social_schedules
  where id = p_schedule_id;

  if not found then
    raise exception 'social_schedule not found for id %', p_schedule_id;
  end if;

  select * into v_post
  from public.social_posts
  where id = v_sched.post_id;

  -- 2) Récupérer un éventuel content_job lié à ce post
  begin
    select * into v_job
    from public.content_jobs
    where social_post_id = v_sched.post_id
    order by created_at desc
    limit 1;
  exception when others then
    -- En cas de problème (table absente, etc.), on ignore simplement la partie content_jobs
    null;
  end;

  -- 3) Ne permettre l'annulation que pour les schedules encore programmés
  if v_sched.status <> 'scheduled' then
    return jsonb_build_object(
      'schedule_id', v_sched.id,
      'status', v_sched.status,
      'message', 'Schedule is not in scheduled status and cannot be canceled.'
    );
  end if;

  -- 4) Marquer le schedule comme "canceled"
  update public.social_schedules
  set status = 'canceled'
  where id = v_sched.id;

  -- 5) Rebasculer le post en statut "draft" si nécessaire
  if v_post.id is not null and v_post.status = 'scheduled' then
    update public.social_posts
    set status = 'draft',
        updated_at = now()
    where id = v_post.id;
  end if;

  -- 6) Si un content_job existe et est encore en "scheduled", l'archiver
  if v_job.id is not null and v_job.status = 'scheduled' then
    update public.content_jobs
    set status = 'archived',
        updated_at = now()
    where id = v_job.id;
  end if;

  return jsonb_build_object(
    'schedule_id', v_sched.id,
    'post_id', v_sched.post_id,
    'social_post_status', coalesce(v_post.status, null),
    'content_job_id', coalesce(v_job.id, null),
    'previous_status', 'scheduled',
    'new_status', 'canceled'
  );
end;
$$;

grant execute on function public.cancel_social_schedule(uuid) to anon, authenticated;
