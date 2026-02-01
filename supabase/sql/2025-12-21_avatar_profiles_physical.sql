alter table if exists public.avatar_profiles
  add column if not exists height_cm integer,
  add column if not exists body_type text,
  add column if not exists complexion text,
  add column if not exists age_range text,
  add column if not exists gender text,
  add column if not exists hair_description text,
  add column if not exists clothing_style text;
