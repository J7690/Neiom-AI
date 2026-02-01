-- Data audit for avatar / agents / previews

-- 1) Row counts
select 'avatar_profiles' as table_name, count(*) as row_count from public.avatar_profiles;
select 'avatar_previews' as table_name, count(*) as row_count from public.avatar_previews;
select 'image_agents'    as table_name, count(*) as row_count from public.image_agents;

-- 2) Recent avatar profiles
select
  id,
  name,
  preview_image_url,
  face_reference_paths,
  created_at
from public.avatar_profiles
order by created_at desc
limit 5;

-- 3) Recent avatar previews joined with agents
select
  p.id,
  p.avatar_profile_id,
  p.image_url,
  p.is_selected,
  p.created_at,
  a.display_name as agent_display_name
from public.avatar_previews p
join public.image_agents a on a.id = p.agent_id
order by p.created_at desc
limit 10;

-- 4) Agents summary
select
  id,
  display_name,
  provider_model_id,
  kind,
  is_recommended,
  created_at
from public.image_agents
order by created_at desc
limit 10;
