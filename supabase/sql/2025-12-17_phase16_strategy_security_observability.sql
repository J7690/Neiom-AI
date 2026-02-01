-- Phase 16 – Sécurité/Observabilité + Fondations Stratégie (NON DESTRUCTIF)

create extension if not exists pgcrypto;

-- 1) Tables stratégie et connaissances (RAG-ready)
create table if not exists public.marketing_strategies (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  objective text,
  personas jsonb not null default '[]'::jsonb,
  channels text[] not null default '{}'::text[],
  kpis text[] not null default '{}'::text[],
  hypotheses text[] not null default '{}'::text[],
  timezone text not null default 'Africa/Ouagadougou',
  status text not null default 'draft' check (status in ('draft','approved','rejected')),
  approval_reason text,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.brand_rules (
  id uuid primary key default gen_random_uuid(),
  locale text not null,
  forbidden_terms text[] not null default '{}'::text[],
  required_disclaimers text[] not null default '{}'::text[],
  escalate_on_keywords text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(locale)
);

create table if not exists public.playbooks (
  id uuid primary key default gen_random_uuid(),
  scope text not null check (scope in ('global','local')),
  locale text,
  content jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  source text,
  title text,
  locale text,
  content text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- 2) Observabilité
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  severity text not null default 'info',
  message text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.alert_events (
  id uuid primary key default gen_random_uuid(),
  alert_type text not null,
  severity text not null default 'warning',
  message text not null,
  metadata jsonb not null default '{}'::jsonb,
  acknowledged boolean not null default false,
  created_at timestamptz not null default now()
);

-- 3) RLS (lecture via RPCs uniquement)
alter table public.marketing_strategies enable row level security;
alter table public.brand_rules enable row level security;
alter table public.playbooks enable row level security;
alter table public.documents enable row level security;
alter table public.audit_logs enable row level security;
alter table public.alert_events enable row level security;

-- 4) RPCs Stratégie
create or replace function public.create_strategy_plan(
  p_title text,
  p_objective text,
  p_personas jsonb default '[]'::jsonb,
  p_channels text[] default '{}'::text[],
  p_kpis text[] default '{}'::text[],
  p_hypotheses text[] default '{}'::text[],
  p_timezone text default 'Africa/Ouagadougou'
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_row public.marketing_strategies%rowtype;
begin
  insert into public.marketing_strategies(title, objective, personas, channels, kpis, hypotheses, timezone)
  values (p_title, p_objective, coalesce(p_personas,'[]'::jsonb), coalesce(p_channels,'{}'::text[]), coalesce(p_kpis,'{}'::text[]), coalesce(p_hypotheses,'{}'::text[]), coalesce(p_timezone,'Africa/Ouagadougou'))
  returning * into v_row;
  return to_jsonb(v_row);
end;
$$;

grant execute on function public.create_strategy_plan(text,text,jsonb,text[],text[],text[],text) to anon, authenticated;

create or replace function public.get_strategy_plan(
  p_id uuid
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select to_jsonb(ms) into v from public.marketing_strategies ms where ms.id = p_id;
  if v is null then raise exception 'strategy not found'; end if;
  return v;
end; $$;

grant execute on function public.get_strategy_plan(uuid) to anon, authenticated;

create or replace function public.list_strategy_plans(
  p_status text default null,
  p_limit int default 50
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select coalesce(jsonb_agg(row_to_json(ms)), '[]'::jsonb)
  into v
  from (
    select * from public.marketing_strategies
    where (p_status is null or status = p_status)
    order by created_at desc
    limit p_limit
  ) ms;
  return v;
end; $$;

grant execute on function public.list_strategy_plans(text,int) to anon, authenticated;

create or replace function public.approve_strategy_plan(
  p_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = public as
$$
begin
  update public.marketing_strategies
  set status = case when p_approve then 'approved' else 'rejected' end,
      approval_reason = p_reason,
      approved_at = case when p_approve then now() else null end,
      updated_at = now()
  where id = p_id;
  if not found then raise exception 'strategy not found'; end if;
  return true;
end; $$;

grant execute on function public.approve_strategy_plan(uuid,boolean,text) to anon, authenticated;

-- 5) Content policy guard
create or replace function public.upsert_brand_rules(
  p_locale text,
  p_forbidden_terms text[] default '{}'::text[],
  p_required_disclaimers text[] default '{}'::text[],
  p_escalate_on text[] default '{}'::text[]
)
returns boolean
language plpgsql
security definer
set search_path = public as
$$
begin
  insert into public.brand_rules(locale, forbidden_terms, required_disclaimers, escalate_on_keywords)
  values (lower(p_locale), coalesce(p_forbidden_terms,'{}'::text[]), coalesce(p_required_disclaimers,'{}'::text[]), coalesce(p_escalate_on,'{}'::text[]))
  on conflict (locale) do update set
    forbidden_terms = excluded.forbidden_terms,
    required_disclaimers = excluded.required_disclaimers,
    escalate_on_keywords = excluded.escalate_on_keywords,
    updated_at = now();
  return true;
end; $$;

grant execute on function public.upsert_brand_rules(text,text[],text[],text[]) to anon, authenticated;

create or replace function public.content_policy_check(
  p_text text,
  p_locale text default null
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare
  v_rules record;
  v_locale text := coalesce(p_locale, coalesce(public.get_setting('DEFAULT_LOCALE'), 'fr_BF'));
  v_allowed boolean := true;
  v_reasons text[] := '{}'::text[];
begin
  select * into v_rules from public.brand_rules where locale = lower(v_locale) limit 1;
  if v_rules is not null then
    if array_length(v_rules.forbidden_terms,1) is not null then
      if exists (
        select 1 from unnest(v_rules.forbidden_terms) kw where lower(coalesce(p_text,'')) like ('%'||lower(kw)||'%')
      ) then
        v_allowed := false;
        v_reasons := array_append(v_reasons, 'forbidden_term');
      end if;
    end if;
    if array_length(v_rules.escalate_on_keywords,1) is not null and v_allowed then
      if exists (
        select 1 from unnest(v_rules.escalate_on_keywords) kw where lower(coalesce(p_text,'')) like ('%'||lower(kw)||'%')
      ) then
        v_reasons := array_append(v_reasons, 'escalate_on_keyword');
      end if;
    end if;
  end if;
  return jsonb_build_object('allowed', v_allowed, 'reasons', v_reasons, 'locale', v_locale);
end; $$;

grant execute on function public.content_policy_check(text,text) to anon, authenticated;

-- 6) Observability RPCs
create or replace function public.log_event(
  p_category text,
  p_severity text,
  p_message text,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare v_id uuid; begin
  insert into public.audit_logs(category, severity, message, metadata)
  values (p_category, p_severity, p_message, coalesce(p_metadata,'{}'::jsonb))
  returning id into v_id;
  return v_id;
end; $$;

grant execute on function public.log_event(text,text,text,jsonb) to anon, authenticated;

create or replace function public.record_alert(
  p_alert_type text,
  p_severity text,
  p_message text,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare v_id uuid; begin
  insert into public.alert_events(alert_type, severity, message, metadata)
  values (p_alert_type, p_severity, p_message, coalesce(p_metadata,'{}'::jsonb))
  returning id into v_id;
  return v_id;
end; $$;

grant execute on function public.record_alert(text,text,text,jsonb) to anon, authenticated;

-- 7) Renforcer receive_meta_webhook avec alerte signature invalide
create or replace function public.receive_meta_webhook(
  signature_header text,
  body jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  if not public.verify_meta_signature(signature_header, body::text) then
    perform public.record_alert('meta_webhook_invalid_signature','error','Invalid Meta signature', jsonb_build_object('signature_header', signature_header));
    raise exception 'invalid signature';
  end if;
  return public.ingest_meta_webhook(body);
end;
$$;

grant execute on function public.receive_meta_webhook(text,jsonb) to anon, authenticated;
