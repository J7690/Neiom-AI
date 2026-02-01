-- Phase 17 – RAG + A/B + Calendrier (NON DESTRUCTIF)

-- 1) RAG minimal basé sur full-text (sans secrets)
create or replace function public.ingest_document(
  p_source text,
  p_title text,
  p_locale text,
  p_content text,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public as
$$
declare v_id uuid; begin
  insert into public.documents(source, title, locale, content, metadata)
  values (p_source, p_title, lower(p_locale), p_content, coalesce(p_metadata,'{}'::jsonb))
  returning id into v_id;
  return v_id;
end; $$;

grant execute on function public.ingest_document(text,text,text,text,jsonb) to anon, authenticated;

create or replace function public.search_knowledge(
  p_query text,
  p_locale text default null,
  p_top_k int default 5
)
returns jsonb
language sql
security definer
stable
set search_path = public as
$$
  with q as (
    select plainto_tsquery('simple', coalesce(p_query,'')) as ts
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', d.id,
    'title', d.title,
    'score', ts_rank_cd(to_tsvector('simple', d.content), q.ts),
    'snippet', ts_headline('simple', d.content, q.ts, 'StartSel=<b>,StopSel=</b>,MaxFragments=1, MaxWords=25'),
    'locale', d.locale
  ) order by ts_rank_cd(to_tsvector('simple', d.content), q.ts) desc), '[]'::jsonb)
  from public.documents d, q
  where (p_locale is null or lower(d.locale) = lower(p_locale))
    and length(coalesce(p_query,'')) > 0
  limit p_top_k;
$$;

grant execute on function public.search_knowledge(text,text,int) to anon, authenticated;

-- 2) A/B Testing structures
create table if not exists public.experiments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  objective text,
  hypothesis text,
  target_channels text[] not null default '{}'::text[],
  status text not null default 'draft' check (status in ('draft','running','stopped','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.experiment_variants (
  id uuid primary key default gen_random_uuid(),
  experiment_id uuid not null references public.experiments(id) on delete cascade,
  variant_index int not null,
  content_text text not null,
  target_channels text[] not null default '{}'::text[],
  status text not null default 'draft' check (status in ('draft','scheduled','running','stopped','published','failed')),
  post_id uuid references public.social_posts(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists experiment_variants_exp_idx on public.experiment_variants(experiment_id, variant_index);

create table if not exists public.variant_results (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.experiment_variants(id) on delete cascade,
  day date not null,
  impressions bigint,
  likes bigint,
  comments bigint,
  shares bigint,
  engagement_rate numeric,
  created_at timestamptz not null default now(),
  unique(variant_id, day)
);

alter table public.experiments enable row level security;
alter table public.experiment_variants enable row level security;
alter table public.variant_results enable row level security;

-- 3) RPCs Experiments
create or replace function public.create_experiment(
  p_name text,
  p_objective text,
  p_hypothesis text,
  p_channels text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare v_row public.experiments%rowtype; begin
  insert into public.experiments(name, objective, hypothesis, target_channels, status)
  values (p_name, p_objective, p_hypothesis, coalesce(p_channels,'{}'::text[]), 'draft')
  returning * into v_row;
  return to_jsonb(v_row);
end; $$;

grant execute on function public.create_experiment(text,text,text,text[]) to anon, authenticated;

create or replace function public.list_experiments(
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
  select coalesce(jsonb_agg(row_to_json(e)), '[]'::jsonb) into v
  from (
    select * from public.experiments
    where (p_status is null or status = p_status)
    order by created_at desc
    limit p_limit
  ) e;
  return v;
end; $$;

grant execute on function public.list_experiments(text,int) to anon, authenticated;

create or replace function public.list_variants_for_experiment(
  p_experiment_id uuid
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  select coalesce(jsonb_agg(row_to_json(vr)), '[]'::jsonb)
  into v
  from (
    select * from public.experiment_variants where experiment_id = p_experiment_id order by variant_index asc
  ) vr;
  return v;
end; $$;

grant execute on function public.list_variants_for_experiment(uuid) to anon, authenticated;

create or replace function public.generate_post_variants(
  p_experiment_id uuid,
  p_count int default 3,
  p_tones text[] default array['neutre','enthousiaste','professionnel'],
  p_length int default 120
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_exp record;
  v_created jsonb := '[]'::jsonb;
  i int := 1;
  v_text text;
  v_tone text;
  v_idx int;
begin
  select * into v_exp from public.experiments where id = p_experiment_id;
  if not found then raise exception 'experiment not found'; end if;
  while i <= greatest(1, p_count) loop
    v_tone := coalesce(p_tones[((i-1) % greatest(1, array_length(p_tones,1)))+1], 'neutre');
    v_text := public.suggest_content_stub(coalesce(v_exp.objective,'Objectif'), v_tone, p_length);
    select coalesce(max(variant_index),0)+1 into v_idx from public.experiment_variants where experiment_id = p_experiment_id;
    insert into public.experiment_variants(experiment_id, variant_index, content_text, target_channels, status)
    values (p_experiment_id, v_idx, v_text, v_exp.target_channels, 'draft');
    v_created := v_created || jsonb_build_array(jsonb_build_object('variant_index', v_idx, 'tone', v_tone, 'content_text', v_text));
    i := i + 1;
  end loop;
  update public.experiments set status = 'running', updated_at = now() where id = p_experiment_id;
  return v_created;
end; $$;

grant execute on function public.generate_post_variants(uuid,int,text[],int) to anon, authenticated;

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
  v_post_id := public.create_social_post('agent:ab', coalesce((select objective from public.experiments where id = v_var.experiment_id),'AB Test'), v_var.content_text, '{}'::text[], v_var.target_channels);
  v_sched_id := public.schedule_social_post(v_post_id, p_schedule_at, p_timezone);
  update public.experiment_variants set post_id = v_post_id, status = 'scheduled', updated_at = now() where id = p_variant_id;
  return jsonb_build_object('post_id', v_post_id, 'schedule_id', v_sched_id);
end; $$;

grant execute on function public.schedule_variant_post(uuid,timestamptz,text) to anon, authenticated;

create or replace function public.evaluate_variants(
  p_experiment_id uuid
)
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cnt int := 0;
  rec record;
  agg record;
begin
  for rec in select id from public.experiment_variants where experiment_id = p_experiment_id and post_id is not null loop
    select 
      sum(impressions) as impressions,
      sum(likes) as likes,
      sum(comments) as comments,
      sum(shares) as shares,
      null::numeric as engagement
    into agg
    from public.social_metrics
    where post_id = (select post_id from public.experiment_variants where id = rec.id);

    if agg.impressions is not null and agg.impressions > 0 then
      agg.engagement := coalesce((coalesce(agg.likes,0)+coalesce(agg.comments,0)+coalesce(agg.shares,0))::numeric/nullif(agg.impressions,0), 0);
    else
      agg.engagement := null;
    end if;

    insert into public.variant_results(variant_id, day, impressions, likes, comments, shares, engagement_rate)
    values (rec.id, now()::date, agg.impressions, agg.likes, agg.comments, agg.shares, agg.engagement)
    on conflict (variant_id, day) do update set
      impressions = excluded.impressions,
      likes = excluded.likes,
      comments = excluded.comments,
      shares = excluded.shares,
      engagement_rate = excluded.engagement_rate;

    v_cnt := v_cnt + 1;
  end loop;
  return v_cnt;
end; $$;

grant execute on function public.evaluate_variants(uuid) to anon, authenticated;

create or replace function public.apply_stop_rules(
  p_experiment_id uuid,
  p_min_impressions bigint default 100,
  p_engagement_threshold numeric default 0.01
)
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_cnt int := 0;
  rec record;
  agg record;
begin
  for rec in select id from public.experiment_variants where experiment_id = p_experiment_id and coalesce(status,'') not in ('stopped','failed') loop
    select 
      sum(impressions) as impressions,
      sum(coalesce(likes,0)+coalesce(comments,0)+coalesce(shares,0))::numeric as engages
    into agg
    from public.variant_results
    where variant_id = rec.id;

    if coalesce(agg.impressions,0) >= p_min_impressions and coalesce(agg.engages,0)/nullif(agg.impressions,0) < p_engagement_threshold then
      update public.experiment_variants set status = 'stopped', updated_at = now() where id = rec.id;
      v_cnt := v_cnt + 1;
    end if;
  end loop;
  return v_cnt;
end; $$;

grant execute on function public.apply_stop_rules(uuid,bigint,numeric) to anon, authenticated;

-- 4) Calendrier RPC
create or replace function public.list_calendar(
  p_start_date date default now()::date,
  p_days int default 30
)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare v jsonb; begin
  with items as (
    select 
      date(s.scheduled_at) as d,
      jsonb_build_object(
        'schedule_id', s.id,
        'time', to_char(s.scheduled_at, 'HH24:MI'),
        'post_id', s.post_id,
        'status', s.status,
        'channels', p.target_channels,
        'content', left(coalesce(p.content_text,''), 140)
      ) as item
    from public.social_schedules s
    join public.social_posts p on p.id = s.post_id
    where s.scheduled_at >= p_start_date
      and s.scheduled_at < p_start_date + (p_days || ' days')::interval
    order by s.scheduled_at asc
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'date', d::date,
    'items', coalesce((select jsonb_agg(item) from items i where i.d = d), '[]'::jsonb)
  ) order by d asc), '[]'::jsonb)
  into v
  from generate_series(p_start_date, p_start_date + (p_days::text || ' days')::interval, '1 day') as d;
  return v;
end; $$;

grant execute on function public.list_calendar(date,int) to anon, authenticated;
