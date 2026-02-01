-- Phase 19 – Analytics & Reports + Ads Recommendations (NON DESTRUCTIF)

-- 1) Ads schema
create table if not exists public.ad_accounts (
  id uuid primary key default gen_random_uuid(),
  platform text not null default 'meta',
  account_id text,
  display_name text,
  currency text default 'XOF',
  status text not null default 'active' check (status in ('active','paused','disabled')),
  provider_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ad_campaigns (
  id uuid primary key default gen_random_uuid(),
  account_id uuid references public.ad_accounts(id) on delete cascade,
  name text not null,
  objective text not null check (objective in ('messages','leads','traffic')),
  status text not null default 'draft' check (status in ('draft','active','paused','completed')),
  daily_budget numeric,
  start_date date,
  end_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ad_sets (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.ad_campaigns(id) on delete cascade,
  name text not null,
  target_locale text,
  age_min int,
  age_max int,
  interests text[] not null default '{}'::text[],
  placements text[] not null default '{}'::text[],
  status text not null default 'draft' check (status in ('draft','active','paused','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ad_ads (
  id uuid primary key default gen_random_uuid(),
  ad_set_id uuid not null references public.ad_sets(id) on delete cascade,
  name text not null,
  creative_post_id uuid references public.social_posts(id) on delete set null,
  status text not null default 'draft' check (status in ('draft','active','paused','completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ad_metrics (
  id uuid primary key default gen_random_uuid(),
  level text not null check (level in ('campaign','adset','ad')),
  ref_id uuid not null,
  day date not null,
  impressions bigint,
  clicks bigint,
  ctr numeric,
  cpc numeric,
  spend numeric,
  leads integer,
  messages integer,
  cpl numeric,
  cpm numeric,
  created_at timestamptz not null default now(),
  unique(level, ref_id, day)
);

create index if not exists ad_metrics_ref_day_idx on public.ad_metrics(level, ref_id, day);

alter table public.ad_accounts enable row level security;
alter table public.ad_campaigns enable row level security;
alter table public.ad_sets enable row level security;
alter table public.ad_ads enable row level security;
alter table public.ad_metrics enable row level security;

revoke all on table public.ad_accounts from anon;
revoke all on table public.ad_campaigns from anon;
revoke all on table public.ad_sets from anon;
revoke all on table public.ad_ads from anon;
revoke all on table public.ad_metrics from anon;

grant select on table public.ad_accounts to authenticated;
grant select on table public.ad_campaigns to authenticated;
grant select on table public.ad_sets to authenticated;
grant select on table public.ad_ads to authenticated;
grant select on table public.ad_metrics to authenticated;

-- 2) Reports (weekly/monthly)
create or replace function public.get_report_weekly(p_start date default date_trunc('week', now())::date)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare
  v_start date := p_start;
  v_end date := p_start + interval '7 days';
  v_top_posts jsonb := '[]'::jsonb;
  v_summary jsonb := '{}'::jsonb;
  v_best_hours jsonb := '[]'::jsonb;
begin
  select coalesce(jsonb_agg(x order by x->>'score' desc), '[]'::jsonb) into v_top_posts
  from (
    select jsonb_build_object(
      'post_id', p.id,
      'channels', p.target_channels,
      'content', left(coalesce(p.content_text,''), 160),
      'score', coalesce(sum(coalesce(m.likes,0)+coalesce(m.comments,0)+coalesce(m.shares,0))::numeric, 0)
    ) as x
    from public.social_posts p
    left join public.social_metrics m on m.post_id = p.id and m.fetched_at >= v_start and m.fetched_at < v_end
    where p.created_at >= v_start - interval '30 days'
    group by p.id
    limit 10
  ) t;

  select jsonb_build_object(
    'messages_in', (select count(*) from public.messages where direction='inbound' and sent_at >= v_start and sent_at < v_end),
    'messages_out', (select count(*) from public.messages where direction='outbound' and sent_at >= v_start and sent_at < v_end),
    'posts_created', (select count(*) from public.social_posts where created_at >= v_start and created_at < v_end),
    'leads', (select count(*) from public.leads where created_at >= v_start and created_at < v_end)
  ) into v_summary;

  select coalesce(jsonb_agg(jsonb_build_object('hour', h, 'count', c) order by c desc), '[]'::jsonb) into v_best_hours
  from (
    select extract(hour from s.scheduled_at)::int as h, count(*) as c
    from public.social_schedules s
    where s.scheduled_at >= v_start and s.scheduled_at < v_end
    group by 1
  ) t;

  return jsonb_build_object(
    'period', jsonb_build_object('start', v_start, 'end', v_end),
    'summary', v_summary,
    'top_posts', v_top_posts,
    'best_hours', v_best_hours
  );
end; $$;

grant execute on function public.get_report_weekly(date) to anon, authenticated;

create or replace function public.get_report_monthly(p_month_start date default date_trunc('month', now())::date)
returns jsonb
language plpgsql
security definer
stable
set search_path = public as
$$
declare
  v_start date := p_month_start;
  v_end date := (p_month_start + interval '1 month');
  v_top_posts jsonb := '[]'::jsonb;
  v_summary jsonb := '{}'::jsonb;
  v_best_days jsonb := '[]'::jsonb;
begin
  select coalesce(jsonb_agg(x order by x->>'score' desc), '[]'::jsonb) into v_top_posts
  from (
    select jsonb_build_object(
      'post_id', p.id,
      'channels', p.target_channels,
      'content', left(coalesce(p.content_text,''), 160),
      'score', coalesce(sum(coalesce(m.likes,0)+coalesce(m.comments,0)+coalesce(m.shares,0))::numeric, 0)
    ) as x
    from public.social_posts p
    left join public.social_metrics m on m.post_id = p.id and m.fetched_at >= v_start and m.fetched_at < v_end
    where p.created_at >= v_start - interval '30 days'
    group by p.id
    limit 10
  ) t;

  select jsonb_build_object(
    'messages_in', (select count(*) from public.messages where direction='inbound' and sent_at >= v_start and sent_at < v_end),
    'messages_out', (select count(*) from public.messages where direction='outbound' and sent_at >= v_start and sent_at < v_end),
    'posts_created', (select count(*) from public.social_posts where created_at >= v_start and created_at < v_end),
    'leads', (select count(*) from public.leads where created_at >= v_start and created_at < v_end)
  ) into v_summary;

  select coalesce(jsonb_agg(jsonb_build_object('date', d, 'count', c) order by c desc), '[]'::jsonb) into v_best_days
  from (
    select date(s.scheduled_at) as d, count(*) as c
    from public.social_schedules s
    where s.scheduled_at >= v_start and s.scheduled_at < v_end
    group by 1
  ) t;

  return jsonb_build_object(
    'period', jsonb_build_object('start', v_start, 'end', v_end),
    'summary', v_summary,
    'top_posts', v_top_posts,
    'best_days', v_best_days
  );
end; $$;

grant execute on function public.get_report_monthly(date) to anon, authenticated;

-- 3) Ads recommendations (stub based on organic performance)
create or replace function public.recommend_ad_campaigns(
  p_objective text,
  p_budget numeric,
  p_days int default 7,
  p_locales text[] default array['fr_BF'],
  p_interests text[] default '{}'::text[],
  p_channels text[] default array['facebook','instagram']
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_end timestamptz := now();
  v_start timestamptz := now() - interval '14 days';
  v_posts jsonb := '[]'::jsonb;
  v_daily numeric := case when p_days > 0 then (p_budget / p_days) else p_budget end;
  v_per_locale numeric := case when array_length(p_locales,1) > 0 then (v_daily / array_length(p_locales,1)) else v_daily end;
  v_reco jsonb;
begin
  select coalesce(jsonb_agg(x order by (x->>'score')::numeric desc), '[]'::jsonb) into v_posts
  from (
    select jsonb_build_object(
      'post_id', p.id,
      'content', left(coalesce(p.content_text,''), 160),
      'channels', p.target_channels,
      'score', coalesce(sum(coalesce(m.likes,0)+coalesce(m.comments,0)+coalesce(m.shares,0))::numeric, 0),
      'engagement_rate', round(avg(m.engagement_rate)::numeric,4)
    ) as x
    from public.social_posts p
    left join public.social_metrics m on m.post_id = p.id and m.fetched_at >= v_start and m.fetched_at <= v_end
    where p.created_at >= v_start - interval '7 days'
    group by p.id
    limit 5
  ) t;

  v_reco := jsonb_build_object(
    'objective', p_objective,
    'budget_total', p_budget,
    'days', p_days,
    'daily_budget', v_daily,
    'locales', p_locales,
    'interests', p_interests,
    'channels', p_channels,
    'top_creatives', v_posts,
    'proposal', jsonb_build_object(
      'campaign_name', 'Auto-'+ p_objective || '-' || to_char(now(),'YYYYMMDD'),
      'ad_sets', coalesce((
        select jsonb_agg(jsonb_build_object(
          'name', 'AS-'||loc,
          'target_locale', loc,
          'daily_budget', v_per_locale,
          'placements', p_channels,
          'interests', p_interests,
          'ads', coalesce((select jsonb_agg(jsonb_build_object(
            'name','AD-'||substring((tp->>'post_id') from 1 for 8),
            'creative_post_id', (tp->>'post_id')::uuid
          ) order by (tp->>'engagement_rate')::numeric desc) from jsonb_array_elements(v_posts) as tp), '[]'::jsonb)
        )) from unnest(p_locales) loc
      ), '[]'::jsonb)
    )
  );

  return v_reco;
end; $$;

grant execute on function public.recommend_ad_campaigns(text,numeric,int,text[],text[],text[]) to anon, authenticated;

-- 4) Optional: stub collector for ad metrics
create or replace function public.collect_ad_metrics_stub()
returns int
language plpgsql
security definer
set search_path = public as
$$
declare v int := 0; begin
  return v;
end; $$;

grant execute on function public.collect_ad_metrics_stub() to anon, authenticated;
