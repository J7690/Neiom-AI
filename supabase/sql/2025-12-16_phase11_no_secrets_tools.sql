-- Phase 11 – Outils sans secrets: génération de contenu, auto-planification, seed messages (NON DESTRUCTIF)

create or replace function public.suggest_content_stub(
  p_objective text,
  p_tone text default 'neutre',
  p_length int default 120
)
returns text
language plpgsql
security definer
set search_path = public as
$$
declare
  v_intro text;
  v_body text;
  v_cta text;
  v_text text;
begin
  v_intro := case lower(coalesce(p_tone,'neutre'))
    when 'enthousiaste' then '🚀 Grande nouvelle!'
    when 'professionnel' then 'Mise à jour:'
    when 'convivial' then 'Hey 👋'
    else 'Info:'
  end;
  v_body := coalesce(p_objective, 'Découvrez nos nouveautés.');
  v_cta := ' Dites-nous ce que vous en pensez.';
  v_text := trim(v_intro || ' ' || v_body || v_cta);
  if length(v_text) > greatest(40, coalesce(p_length,120)) then
    v_text := substr(v_text, 1, greatest(40, coalesce(p_length,120)) - 3) || '...';
  end if;
  return v_text;
end;
$$;

grant execute on function public.suggest_content_stub(text,text,int) to anon, authenticated;

create or replace function public.create_and_schedule_post_stub(
  p_author_agent text,
  p_objective text,
  p_target_channels text[],
  p_schedule_at timestamptz default now(),
  p_timezone text default 'UTC',
  p_tone text default 'neutre',
  p_length int default 120
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_content text;
  v_post uuid;
  v_sched uuid;
begin
  v_content := public.suggest_content_stub(p_objective, p_tone, p_length);
  v_post := public.create_social_post(p_author_agent, p_objective, v_content, p_target_channels, '{}'::text[]);
  v_sched := public.schedule_social_post(v_post, p_schedule_at, p_timezone);
  return jsonb_build_object('post_id', v_post, 'schedule_id', v_sched, 'content', v_content);
end;
$$;

grant execute on function public.create_and_schedule_post_stub(text,text,text[],timestamptz,text,text,int) to anon, authenticated;

create or replace function public.seed_random_messages(
  p_channels text[] default array['whatsapp','facebook','instagram','tiktok','youtube'],
  p_count int default 10
)
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_i int := 0;
  v_ch text;
  v_author_id text;
  v_author_name text;
  v_msg text;
  v_names text[] := array['Alice','Bob','Chloé','David','Emma','Farid','Gaston','Hana','Imane','Jo'];
  v_msgs text[] := array[
    'Bonjour!','J''ai une question.','C''est urgent svp','Merci pour votre aide','On peut en discuter?','Top 👍','Je rencontre un souci','Comment procéder?','Intéressant','Disponible quand?'
  ];
begin
  while v_i < coalesce(p_count,10) loop
    v_ch := (select unnest(p_channels) order by random() limit 1);
    v_author_name := v_names[1 + floor(random()*array_length(v_names,1))::int];
    v_author_id := lower(substr(v_author_name,1,1)) || '_' || substr(gen_random_uuid()::text,1,8);
    v_msg := v_msgs[1 + floor(random()*array_length(v_msgs,1))::int];
    perform public.simulate_message(v_ch, v_author_id, v_author_name, v_msg, null, now());
    v_i := v_i + 1;
  end loop;
  return v_i;
end;
$$;

grant execute on function public.seed_random_messages(text[],int) to anon, authenticated;

create or replace function public.auto_reply_recent_inbound(
  p_since interval default interval '1 hour',
  p_limit int default 50
)
returns int
language plpgsql
security definer
set search_path = public as
$$
declare
  v_count int := 0;
  rec record;
begin
  for rec in
    select m.id from public.messages m
    where m.direction = 'inbound'
      and m.sent_at >= now() - p_since
    order by m.sent_at desc
    limit p_limit
  loop
    begin
      perform public.auto_reply_stub(rec.id);
      v_count := v_count + 1;
    exception when others then
      -- ignorer erreurs isolées pour ne pas interrompre le batch
      continue;
    end;
  end loop;
  return v_count;
end;
$$;

grant execute on function public.auto_reply_recent_inbound(interval,int) to anon, authenticated;
