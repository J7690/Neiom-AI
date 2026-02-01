-- Seed initial OpenRouter image agents for avatar generation

insert into public.image_agents (
  display_name,
  provider_model_id,
  kind,
  is_recommended,
  quality_score,
  default_cfg
) values
  (
    'Flux Pro – Portrait',
    'black-forest-labs/flux-1.1-pro',
    'avatar',
    true,
    0.95,
    jsonb_build_object(
      'style', 'photo-realistic portrait',
      'notes', 'High-quality avatar portrait generation; use for main avatar.'
    )
  ),
  (
    'Flux Lite – Rapide',
    'black-forest-labs/flux-1.1-lite',
    'avatar',
    true,
    0.9,
    jsonb_build_object(
      'style', 'photo-realistic portrait',
      'notes', 'Faster avatar generation; slightly lighter quality.'
    )
  ),
  (
    'Stable Diffusion 3.5 – Portrait',
    'stability-ai/stable-diffusion-3.5-large',
    'avatar',
    true,
    0.9,
    jsonb_build_object(
      'style', 'photo-realistic portrait',
      'notes', 'Alternative style for avatar portraits.'
    )
  ),
  (
    'Stable Diffusion 3.5 – Medium',
    'stability-ai/stable-diffusion-3.5-medium',
    'avatar',
    true,
    0.88,
    jsonb_build_object(
      'style', 'photo-realistic portrait',
      'notes', 'Balanced quality/speed avatar model.'
    )
  );
