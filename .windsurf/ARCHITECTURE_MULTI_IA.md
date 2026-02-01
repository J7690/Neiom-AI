# Nexiom AI Studio – Architecture multi‑IA (vidéo ultra‑réaliste)

Ce document décrit comment Nexiom gère plusieurs fournisseurs IA (Sora, Veo, Runway, Kling, etc.) pour la génération de vidéos, en s’appuyant sur Supabase comme orchestrateur backend et Flutter Web comme frontend.

## 1. Objectif

- Permettre à Nexiom de se connecter à **plusieurs moteurs de génération vidéo** (OpenAI Sora, Google Veo 3, Runway Gen‑3/Gen‑4, Kling, Luma Dream Machine, etc.).
- Offrir un **niveau de qualité configurable** (standard, cinematic, ultra_realistic).
- Masquer cette complexité côté front : Flutter continue d’appeler **un seul endpoint** Supabase (`/generate/video`).

## 2. Vue d’ensemble

### 2.1. Frontend (Flutter Web)

- Pages : `HomePage`, `VideoPage`, `ImagePage`, `AudioPage`.
- Pour la vidéo :
  - Envoie un appel à Supabase Edge Function `generate-video` avec :
    - `prompt`,
    - `durationSeconds`,
    - `referenceMediaPath` (média de référence uploadé dans `inputs/`),
    - `qualityTier` (par ex. `standard | cinematic | ultra_realistic`),
    - éventuellement `provider` (optionnel, si l’utilisateur force un fournisseur).
- Ne connaît pas les détails de chaque moteur IA (Sora, Runway, etc.).

### 2.2. Orchestrateur backend (Supabase)

- Edge Function `generate-video` = **point d’entrée unique**.
- Rôle :
  - Valider les paramètres (prompt, durée, média),
  - Choisir le **fournisseur IA** en fonction de `qualityTier` + configuration interne,
  - Créer un enregistrement dans `generation_jobs` avec `provider`, `quality_tier`, etc.,
  - Appeler l’API du fournisseur (asynchrone),
  - Stocker le résultat (via `outputs/` + `result_url`),
  - Retourner au front un `jobId` + éventuellement un `resultUrl` direct si la génération est synchrone.

### 2.3. Base de données (Supabase Postgres)

- Table `generation_jobs` (déjà existante, enrichie) :
  - `id` (uuid)
  - `type` (`video | image | audio`)
  - `prompt`
  - `model`
  - `duration_seconds`
  - `reference_media_path`
  - `status` (`pending | processing | completed | failed`)
  - `result_url`
  - `error_message`
  - `provider` (**nouveau**)
  - `provider_job_id` (**nouveau**)
  - `quality_tier` (**nouveau**)
  - `provider_metadata` (jsonb, **nouveau**) pour stocker des détails spécifiques (paramètres, raw payload, logs, etc.).

## 3. Choix des fournisseurs IA

### 3.1. Fournisseurs cibles (vidéo ultra‑réaliste)

- **OpenAI Sora**
  - Usage : vidéos photoréalistes jusqu’à 60 s.
  - Intégration : API OpenAI, modèle text‑to‑video, généralement asynchrone (job → status → result URL).

- **Google Veo 3**
  - Usage : vidéos cinématographiques, fort contrôle caméra.
  - Intégration : via Google Cloud / Vertex AI ou API partenaire.

- **Kling 2.1**
  - Usage : longues vidéos (jusqu’à 2 min), 1080p, 30 fps.
  - Intégration : API propriétaire, idéal pour `qualityTier = ultra_realistic` + durée longue.

- **Runway Gen‑3 / Gen‑4**
  - Usage : clips 5–10 s, très bons pour publicité / création rapide.
  - Intégration : API Runway, excellente base pour une **première intégration pro**.

- **Luma Dream Machine, Seedance, Hunyuan Video**
  - Usage : alternatives / compléments.
  - Hunyuan est open source → possibilité de self‑hosting.

### 3.2. Règles de sélection (exemple)

En pseudo‑logique à l’intérieur de `generate-video` :

- Si `qualityTier = ultra_realistic` et que Sora/Kling sont disponibles :
  - choisir `provider = sora` ou `kling` selon la config.
- Sinon si `qualityTier = cinematic` :
  - choisir `provider = runway` ou `veo`.
- Sinon (`qualityTier` non défini ou `standard`) :
  - choisir un modèle plus léger (Runway, Luma, ou un modèle vidéo via OpenRouter si disponible).

Le champ `provider` dans `generation_jobs` garde la trace de ce choix.

## 4. Flux complet pour la vidéo (multi‑fournisseur)

1. **Frontend Flutter (VideoPage)**
   - Upload d’une vidéo ou image de référence dans Supabase Storage (`inputs/`).
   - Récupération du `path` (ex. `video_reference/1721837465_scene.mp4`).
   - Appel à `generate-video` avec :
     - `prompt`,
     - `durationSeconds`,
     - `referenceMediaPath`,
     - `qualityTier` (et éventuellement `provider`).

2. **Edge Function `generate-video` (Supabase)**
   - Valide les entrées.
   - Effectue un **audit Supabase** (tables et storage déjà effectués par la conception).
   - Choisit le `provider` à utiliser.
   - Crée un job dans `generation_jobs` avec :
     - `type = 'video'`,
     - `status = 'processing'`,
     - `provider`, `quality_tier`, etc.
   - Construit un payload adapté au provider :
     - prompt + durée + URL du média de référence (via `getPublicUrl`).
   - Envoie la requête au provider (HTTP POST).
   - Deux cas :
     - **Synchronous** (réponse directe avec URL vidéo ou base64) :
       - Enregistre le fichier dans `outputs` si besoin → met `result_url` → `status = 'completed'` → renvoie `resultUrl` + `jobId`.
     - **Asynchronous** (job externe) :
       - Le provider renvoie seulement un `provider_job_id` et un statut :
         - met à jour le job (`provider_job_id`, `status = 'pending'` ou `processing`),
         - renvoie au front uniquement `jobId`.

3. **Workers / fonctions de polling provider** (future étape)
   - Edge Function planifiée (cron) ou job externe qui interroge périodiquement les APIs des providers :
     - récupère l’état des jobs (`provider_job_id` → status + result URL),
     - quand c’est `completed` :
       - stocke la vidéo dans `outputs` si nécessaire,
       - met à jour `generation_jobs.result_url`, `status = 'completed'`.

4. **Frontend Flutter – suivi des jobs longs**
   - Utilise la RPC `get_generation_job(jobId)` pour vérifier périodiquement :
     - `status` (`processing`, `completed`, `failed`),
     - `result_url`.
   - Tant que `status != 'completed'`, affiche un loader + message.
   - Dès que `status = 'completed'`, charge la vidéo dans `ResultViewer` et permet le téléchargement.

## 5. Rôle d’OpenRouter dans cette architecture

À court terme, Nexiom utilise OpenRouter pour la génération vidéo simple via `modalities: ["video"]` (comme dans la première version de `generate-video`).

Dans un contexte multi‑IA :

- OpenRouter devient un **provider parmi d’autres**, avec des avantages :
  - API unifiée pour certains modèles multimodaux (images, vidéos, texte),
  - utilisation possible pour des tâches annexes (analyse vidéo, résumé, etc.).
- `provider = 'openrouter'` reste le **provider par défaut** tant que Sora / Veo / Runway ne sont pas encore intégrés.

## 6. Sécurité, coûts et gouvernance

- Toutes les clés API des providers sont stockées **côté Supabase** (Edge Functions), jamais exposées au front Flutter.
- Le champ `provider_metadata` permet de journaliser :
  - les paramètres d’appel (sans secrets),
  - les identifiants de ressources côté provider,
  - des informations utiles pour l’audit ou le debug.
- Des quotas et limites peuvent être appliqués par `qualityTier` :
  - `standard` → modèles plus économiques,
  - `ultra_realistic` → réservé à certains rôles / comptes internes.

## 7. Résumé

- **Frontend** : reste simple, appelle `generate-video` avec quelques paramètres (prompt, durée, qualité, référence média).
- **Supabase** : devient un **orchestrateur multi‑fournisseur**, tenant de route tous les jobs, providers, ids externes et URLs finales.
- **Providers IA** : peuvent être ajoutés progressivement (Runway, Luma, Seedance, Sora, Veo, Kling, Hunyuan…), sans casser l’API côté Flutter.

Cette architecture est conçue pour que Nexiom puisse monter graduellement en qualité, jusqu’à atteindre de la vidéo quasi indifférenciable du réel, tout en gardant une base robuste et maîtrisée.
