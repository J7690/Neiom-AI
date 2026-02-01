update public.image_agents
set provider_model_id = 'black-forest-labs/flux.2-pro'
where provider_model_id in (
  'black-forest-labs/flux-1.1-pro',
  'stability-ai/stable-diffusion-3.5-large'
)
  and kind = 'avatar';

update public.image_agents
set provider_model_id = 'black-forest-labs/flux.2-flex'
where provider_model_id in (
  'black-forest-labs/flux-1.1-lite',
  'stability-ai/stable-diffusion-3.5-medium'
)
  and kind = 'avatar';
