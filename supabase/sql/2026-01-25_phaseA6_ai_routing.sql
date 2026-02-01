-- Phase A6 – Orchestrateur de modèles OpenRouter par rôle
-- Objectif : permettre de choisir des modèles différents selon le type de tâche
-- (analyse, assistant, créatif, média) sans casser le comportement existant.

alter table public.ai_orchestration_settings
  add column if not exists text_model_analysis text,
  add column if not exists text_model_assistant text,
  add column if not exists text_model_creative text,
  add column if not exists image_model_default text,
  add column if not exists image_model_segmentation text,
  add column if not exists video_model_default text,
  add column if not exists audio_model_default text;
