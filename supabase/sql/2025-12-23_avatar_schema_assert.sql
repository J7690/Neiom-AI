-- Assert that all expected avatar-related tables and columns exist.

-- 1) avatar_profiles columns
select
  id,
  name,
  description,
  face_reference_paths,
  environment_reference_paths,
  face_strength,
  environment_strength,
  is_primary,
  preview_image_url,
  preferred_agent_id,
  height_cm,
  body_type,
  complexion,
  age_range,
  gender,
  hair_description,
  clothing_style,
  created_at
from public.avatar_profiles
limit 0;

-- 2) image_agents columns
select
  id,
  display_name,
  provider_model_id,
  kind,
  is_recommended,
  quality_score,
  default_cfg,
  created_at
from public.image_agents
limit 0;

-- 3) avatar_previews columns
select
  id,
  avatar_profile_id,
  agent_id,
  image_url,
  is_selected,
  created_at
from public.avatar_previews
limit 0;
