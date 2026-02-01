-- Phase 21 – Alerts advanced + Ads orchestration (NON DESTRUCTIF)

-- 1) Alerts rules runner (simple thresholds)
create or replace function public.run_alert_rules()
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v int := 0;
  v_days int := 7;
  v_min_posts int := coalesce((select (public.get_setting('ALERT_MIN_POSTS_7D'))::int), 1);
  v_min_leads int := coalesce((select (public.get_setting('ALERT_MIN_LEADS_7D'))::int), 1);
  v_start timestamptz := now() - make_interval(days => v_days);
  n_posts int;
  n_leads int;
begin
  select count(*) into n_posts from public.social_posts p where p.created_at >= v_start;
  if n_posts < v_min_posts then
    perform public.record_alert('low_posts','warning','Nombre de posts insuffisant sur 7j', jsonb_build_object('count', n_posts, 'min', v_min_posts));
    v := v + 1;
  end if;

  select count(*) into n_leads from public.leads l where l.created_at >= v_start;
  if n_leads < v_min_leads then
    perform public.record_alert('low_leads','warning','Nombre de leads insuffisant sur 7j', jsonb_build_object('count', n_leads, 'min', v_min_leads));
    v := v + 1;
  end if;

  return v;
end; $$;

grant execute on function public.run_alert_rules() to anon, authenticated;

-- 2) Ads orchestration from recommendation (mock)
create or replace function public.create_ads_from_reco(
  p_objective text,
  p_budget numeric,
  p_days int,
  p_locales text[],
  p_interests text[],
  p_channels text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_reco jsonb;
  v_account uuid;
  v_campaign uuid;
  v_sets jsonb := '[]'::jsonb;
  v_ads jsonb := '[]'::jsonb;
  v_day_budget numeric := case when p_days > 0 then p_budget / p_days else p_budget end;
  v_row jsonb;
  it jsonb;
  loc text;
  ad_obj jsonb;
  adset_id uuid;
  ad_id uuid;
  i int := 0;
begin
  -- pick or create a default ad account
  select id into v_account from public.ad_accounts order by created_at asc limit 1;
  if v_account is null then
    insert into public.ad_accounts(platform, account_id, display_name, currency)
    values ('meta', null, 'Default Account', 'XOF') returning id into v_account;
  end if;

  v_reco := public.recommend_ad_campaigns(p_objective, p_budget, p_days, p_locales, p_interests, p_channels);

  insert into public.ad_campaigns(account_id, name, objective, status, daily_budget, start_date, end_date)
  values (v_account, (v_reco->'proposal'->>'campaign_name'), p_objective, 'draft', v_day_budget, current_date, current_date + (p_days||' days')::interval)
  returning id into v_campaign;

  -- create ad sets per locale
  for loc in select unnest(p_locales) loop
    insert into public.ad_sets(campaign_id, name, target_locale, age_min, age_max, interests, placements, status)
    values (v_campaign, 'AS-'||loc, loc, null, null, coalesce(p_interests,'{}'::text[]), coalesce(p_channels,'{}'::text[]), 'draft')
    returning id into adset_id;
    v_sets := v_sets || jsonb_build_array(adset_id);

    -- create up to 3 ads from top creatives
    i := 0;
    for ad_obj in select * from jsonb_array_elements(coalesce(v_reco->'top_creatives','[]'::jsonb)) loop
      exit when i >= 3;
      insert into public.ad_ads(ad_set_id, name, creative_post_id, status)
      values (adset_id, 'AD-'||substring((ad_obj->>'post_id') from 1 for 8), (ad_obj->>'post_id')::uuid, 'draft')
      returning id into ad_id;
      v_ads := v_ads || jsonb_build_array(ad_id);
      i := i + 1;
    end loop;
  end loop;

  v_row := jsonb_build_object(
    'account_id', v_account,
    'campaign_id', v_campaign,
    'ad_set_ids', v_sets,
    'ad_ids', v_ads
  );

  return v_row;
end; $$;

grant execute on function public.create_ads_from_reco(text,numeric,int,text[],text[],text[]) to anon, authenticated;
