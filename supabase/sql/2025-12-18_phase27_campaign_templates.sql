-- Phase 27 – Campaign templates (NON DESTRUCTIF)

create table if not exists public.campaign_templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  objective text not null check (objective in ('messages','leads','traffic')),
  personas jsonb not null default '[]'::jsonb,
  channels text[] not null default '{}'::text[],
  tone text default 'neutre',
  brief text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.campaign_templates enable row level security;

create or replace function public.upsert_campaign_template(
  p_name text,
  p_objective text,
  p_id uuid default null,
  p_personas jsonb default '[]'::jsonb,
  p_channels text[] default '{}'::text[],
  p_tone text default 'neutre',
  p_brief text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare v_id uuid; begin
  if p_id is null then
    insert into public.campaign_templates(name, objective, personas, channels, tone, brief, metadata)
    values (p_name, p_objective, coalesce(p_personas,'[]'::jsonb), coalesce(p_channels,'{}'::text[]), coalesce(p_tone,'neutre'), p_brief, coalesce(p_metadata,'{}'::jsonb))
    returning id into v_id;
  else
    update public.campaign_templates
    set name = p_name,
        objective = p_objective,
        personas = coalesce(p_personas,'[]'::jsonb),
        channels = coalesce(p_channels,'{}'::text[]),
        tone = coalesce(p_tone,'neutre'),
        brief = p_brief,
        metadata = coalesce(p_metadata,'{}'::jsonb),
        updated_at = now()
    where id = p_id
    returning id into v_id;
    if v_id is null then
      insert into public.campaign_templates(name, objective, personas, channels, tone, brief, metadata)
      values (p_name, p_objective, coalesce(p_personas,'[]'::jsonb), coalesce(p_channels,'{}'::text[]), coalesce(p_tone,'neutre'), p_brief, coalesce(p_metadata,'{}'::jsonb))
      returning id into v_id;
    end if;
  end if;
  return v_id;
end; $$;

grant execute on function public.upsert_campaign_template(text,text,uuid,jsonb,text[],text,text,jsonb) to anon, authenticated;

create or replace function public.list_campaign_templates(
  p_objective text default null,
  p_limit int default 50
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select coalesce(jsonb_agg(row_to_json(t)), '[]'::jsonb) into v
  from (
    select * from public.campaign_templates
    where (p_objective is null or objective = p_objective)
    order by created_at desc
    limit p_limit
  ) t;
  return v;
end; $$;

grant execute on function public.list_campaign_templates(text,int) to anon, authenticated;

create or replace function public.get_campaign_template(p_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select to_jsonb(t) into v from public.campaign_templates t where t.id = p_id;
  if v is null then raise exception 'template not found'; end if;
  return v;
end; $$;

grant execute on function public.get_campaign_template(uuid) to anon, authenticated;
