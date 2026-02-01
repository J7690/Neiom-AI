-- Phase 10 – Rapports de cohérence pour supervision IA
-- Objectif : exposer des listes ciblées pour repérer les trous d'orchestration

-- Content jobs de type média sans generation_job_id
create or replace function public.get_content_jobs_without_generation_job()
returns jsonb
language sql
security definer
set search_path = public as
$$
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  from (
    select *
    from public.content_jobs
    where format in ('image', 'video', 'audio')
      and generation_job_id is null
  ) as t;
$$;

-- Content jobs approuvés mais non reliés à un social_post (donc non planifiés)
create or replace function public.get_content_jobs_approved_unscheduled()
returns jsonb
language sql
security definer
set search_path = public as
$$
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  from (
    select *
    from public.content_jobs
    where status = 'approved'
      and social_post_id is null
  ) as t;
$$;

-- Messages marqués needs_human depuis plus de p_hours heures
create or replace function public.get_messages_needs_human_older_than(p_hours int)
returns jsonb
language sql
security definer
set search_path = public as
$$
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  from (
    select *
    from public.messages
    where needs_human = true
      and sent_at < (now() - (p_hours || ' hours')::interval)
  ) as t;
$$;

grant execute on function public.get_content_jobs_without_generation_job() to anon, authenticated;
grant execute on function public.get_content_jobs_approved_unscheduled() to anon, authenticated;
grant execute on function public.get_messages_needs_human_older_than(int) to anon, authenticated;
