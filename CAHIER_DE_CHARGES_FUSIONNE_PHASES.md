# 🎯 Cahier des charges d’implémentation – Fusionné et détaillé

**Principe** : tout est basé sur les audits réels (Supabase via admin_execute_sql, Flutter RPC usage).  
**Règle** : pas de supposition, pas de devinette, chaque phase précise les commandes SQL exactes à lancer via `admin_sql.py`.

---

## 📋 Résumé des audits (réalisés)

### 1️⃣ Tables existantes (via `phase64_audit_all_tables_names.sql`)

- `content_jobs`
- `generation_jobs`
- `social_posts`, `social_schedules`, `publish_logs`
- `messages`, `conversations`, `contacts`, `leads`
- `documents`, `brand_rules`, `app_settings`
- `experiments`, `experiment_variants`, `variant_results`
- `ad_campaigns`, `campaign_templates`
- `visual_projects`, `visual_documents`, `visual_document_versions`
- `image_assets`, `video_segments`, `video_assets_library`, `video_briefs`
- `avatar_profiles`, `voice_profiles`, `voice_profile_samples`

### 2️⃣ RPCs existants (via `phase63_audit_all_rpcs_names.sql`)

- `upsert_content_job`, `get_content_job`, `list_content_jobs`
- `orchestrate_content_job_step`
- `ingest_document`, `search_knowledge`, `list_documents`, `get_document`
- `get_brand_rules`, `list_brand_rules`, `delete_brand_rules`
- `get_setting`, `set_setting`, `settings_overview`
- `create_social_post`, `schedule_social_post`, `create_and_schedule_post_stub`, `list_calendar`, `enqueue_publish_for_post`, `run_publish_queue_once`, `publish_post`
- `simulate_message`, `route_unrouted_events`, `run_pipeline_once`, `collect_metrics_stub`, `run_schedules_once`
- `create_experiment`, `list_experiments`, `list_variants_for_experiment`, `generate_post_variants`, `schedule_variant_post`, `evaluate_variants`, `apply_stop_rules`
- `recommend_ad_campaigns`, `create_ads_from_reco`, `list_ad_campaigns`, `update_ad_campaign_status`, `list_campaign_templates`, `get_campaign_template`, `upsert_campaign_template`
- `get_report_weekly`, `get_report_monthly`, `get_dashboard_overview`, `list_alerts`, `ack_alert`, `run_alert_rules`, `notify_recent_alerts_stub`, `notify_weekly_report_stub`, `explain_post_algorithmic_status`
- `admin_execute_sql` (outil d’audit)

### 3️⃣ Colonnes clés vérifiées (exemples)

- `content_jobs` : id, title, objective, format, channels, origin_ui, status, author_agent, generation_job_id, social_post_id, experiment_id, variant_id, metadata, created_at, updated_at
- `messages` : id, channel, author_id, author_name, content, created_at, (plus colonnes à ajouter pour supervision IA)
- `documents` : id, title, content, metadata, created_at, updated_at
- `brand_rules` : id, locale, rule_type, pattern, action, priority, created_at, updated_at
- `app_settings` : key, value, created_at, updated_at

---

## 📑 Plan d’implémentation détaillé (phases)

### Phase 1 – Modèle de données “supervision IA”

**Objectif** : étendre `messages` (et éventuellement `content_jobs`) pour tracer les actions IA et les trous de knowledge.

**Backend (SQL)**

- Commande SQL à lancer (via `admin_sql.py`) :

```sql
alter table public.messages
  add column answered_by_ai boolean default false,
  add column needs_human boolean default false,
  add column ai_skipped boolean default false,
  add column knowledge_hit_ids uuid[];
```

- Optionnel (si nécessaire) : ajouter `validation_required boolean default false` dans `content_jobs`.

- Créer une table `ai_alerts` (si nécessaire) :

```sql
create table public.ai_alerts (
  id uuid primary key default gen_random_uuid(),
  type text not null,
  message_id uuid references public.messages(id),
  content_job_id uuid references public.content_jobs(id),
  created_at timestamptz default now(),
  handled_at timestamptz,
  handled_by text
);
grant all on public.ai_alerts to anon, authenticated;
```

**Contrôle**

- Lancer `admin_sql.py supabase/sql/2026-01-06_phase65_extend_messages_for_ai.sql` (à créer avec le contenu ci‑dessus).

---

### Phase 2 – Pipeline “knowledge‑gated” de réponse IA

**Objectif** : créer une RPC qui applique la règle d’or (pas de réponse sans knowledge).

**Backend (SQL)**

- Créer une fonction RPC :

```sql
create or replace function public.run_ai_reply_for_message(p_message_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_msg public.messages%rowtype;
  v_rules jsonb;
  v_knowledge jsonb;
  v_context jsonb;
  v_response jsonb;
  v_mode text;
  v_reply_text text;
  v_knowledge_refs uuid[];
begin
  select * into v_msg from public.messages where id = p_message_id;
  if not found then
    raise exception 'message not found';
  end if;

  -- 1. Brand rules
  select coalesce(jsonb_agg(to_jsonb(br)), '[]'::jsonb) into v_rules
  from public.get_brand_rules('fr', 'facebook') br; -- adapter canal/locale

  -- 2. Knowledge
  select coalesce(jsonb_agg(to_jsonb(d)), '[]'::jsonb) into v_knowledge
  from public.search_knowledge(v_msg.content, 5, 'fr') d;

  -- 3. Contexte (content_jobs, historique)
  v_context := jsonb_build_object('message', to_jsonb(v_msg));

  -- 4. Appel edge function OpenRouter (stub ici)
  -- En pratique, on invoque une edge function qui retourne {mode, reply_text, knowledge_refs}
  -- Pour l’instant, on simule :
  if jsonb_array_length(v_knowledge) = 0 then
    v_mode := 'silence';
    v_reply_text := null;
    v_knowledge_refs := null;
  else
    v_mode := 'answer';
    v_reply_text := (v_knowledge->0->>'content'); -- stub
    v_knowledge_refs := array(select (d->>'id')::uuid from jsonb_array_elements(v_knowledge) d);
  end if;

  -- 5. Effets
  if v_mode = 'answer' then
    insert into public.messages (channel, author_id, author_name, content, created_at, answered_by_ai, knowledge_hit_ids)
    values (v_msg.channel, 'ai', 'Nexiom AI', v_reply_text, now(), true, v_knowledge_refs);
  else
    update public.messages
      set needs_human = true,
          ai_skipped = true
      where id = p_message_id;
    insert into public.ai_alerts (type, message_id, created_at)
    values ('missing_knowledge', p_message_id, now());
  end if;

  return jsonb_build_object('mode', v_mode, 'reply_text', v_reply_text, 'knowledge_refs', v_knowledge_refs);
end;
$$;
grant execute on function public.run_ai_reply_for_message(uuid) to anon, authenticated;
```

- Créer le fichier SQL `2026-01-06_phase66_run_ai_reply_for_message.sql` avec le contenu ci‑dessus, puis lancer :

```bash
python tools/admin_sql.py supabase/sql/2026-01-06_phase66_run_ai_reply_for_message.sql
```

**Frontend (Dart)**

- Ajouter dans `MessagingService` une méthode :

```dart
Future<Map<String, dynamic>> runAiReplyForMessage(String messageId) async {
  final res = await _client.rpc('run_ai_reply_for_message', params: {'p_message_id': messageId});
  return (res as Map).cast<String, dynamic>();
}
```

- Dans `ConversationsPage` (ou une nouvelle page “Supervision IA”), bouton “Déclencher IA” sur les messages `needs_human`.

---

### Phase 3 – Orchestrateur IA global basé sur `content_jobs`

**Objectif** : enrichir `orchestrate_content_job_step` avec des steps de planification, génération, variantes.

**Backend (SQL)**

- Étendre la fonction `orchestrate_content_job_step` (déjà en place) :

```sql
-- Ajouter des steps dans la fonction existante
-- Dans la section des elsif, ajouter :

elsif v_step = 'propose_plan' then
  -- Créer N content_jobs en draft à partir d’analytics/M1–M5
  -- (stub pour l’instant)
  v_ctx := jsonb_build_object('mode', 'propose_plan');
  return jsonb_build_object('step', v_step, 'content_job', to_jsonb(v_job), 'context', v_ctx);

elsif v_step = 'generate_assets' then
  -- Lancer une génération (image/vidéo/audio) et lier generation_job_id
  -- (stub pour l’instant)
  v_ctx := jsonb_build_object('mode', 'generate_assets');
  return jsonb_build_object('step', v_step, 'content_job', to_jsonb(v_job), 'context', v_ctx);

elsif v_step = 'propose_variants' then
  -- Créer plusieurs content_jobs enfants pour A/B testing
  -- (stub pour l’instant)
  v_ctx := jsonb_build_object('mode', 'propose_variants');
  return jsonb_build_object('step', v_step, 'content_job', to_jsonb(v_job), 'context', v_ctx);
```

- Créer le fichier `2026-01-06_phase67_extend_orchestrate_steps.sql` et lancer via `admin_sql.py`.

**Frontend (Dart)**

- `ContentJobService.orchestrateContentJobStep` supporte déjà ces steps (paramètre `step`).

---

### Phase 4 – Intégration Marketing Brain (M1–M5) ↔ `content_jobs`

**Backend (SQL)**

- Créer des RPC simples si besoin :

```sql
create or replace function public.create_content_jobs_from_objective(
  p_objective text,
  p_start_date date,
  p_days int,
  p_channels text[],
  p_timezone text default 'UTC',
  p_tone text default 'neutre',
  p_length int default 120,
  p_author_agent text default 'marketing_brain'
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_job_ids uuid[] := '{}';
  v_i int;
begin
  for v_i in 1..p_days loop
    insert into public.content_jobs (objective, format, channels, origin_ui, status, author_agent, metadata)
    values (
      p_objective,
      'post',
      p_channels,
      'marketing_brain',
      'draft',
      p_author_agent,
      jsonb_build_object('date', p_start_date + (v_i - 1) * interval '1 day')
    )
    returning id into v_job_ids[v_i];
  end loop;
  return jsonb_build_object('created_job_ids', v_job_ids);
end;
$$;
grant execute on function public.create_content_jobs_from_objective(text, date, int, text[], text, text, int, text) to anon, authenticated;
```

- Créer `2026-01-06_phase68_create_content_jobs_from_objective.sql` et lancer via `admin_sql.py`.

**Frontend (Dart)**

- Dans `MarketingService`, ajouter :

```dart
Future<Map<String, dynamic>> createContentJobsFromObjective({
  required String objective,
  required DateTime startDate,
  required int days,
  required List<String> channels,
  String timezone = 'UTC',
  String tone = 'neutre',
  int length = 120,
  String authorAgent = 'marketing_brain',
}) async {
  final res = await _client.rpc('create_content_jobs_from_objective', params: {
    'p_objective': objective,
    'p_start_date': startDate.toIso8601String().substring(0, 10),
    'p_days': days,
    'p_channels': channels,
    'p_timezone': timezone,
    'p_tone': tone,
    'p_length': length,
    'p_author_agent': authorAgent,
  });
  return (res as Map).cast<String, dynamic>();
}
```

- Dans `MarketingDecisionDashboard`, ajouter un bouton “Créer un plan d’actions” qui appelle cette méthode.

---

### Phase 5 – Validation humaine unifiée & publication orchestrée

**Backend (SQL)**

- Ajouter une RPC pour planifier un `content_job` :

```sql
create or replace function public.schedule_content_job(
  p_content_job_id uuid,
  p_schedule_at timestamptz,
  p_timezone text default 'UTC'
)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
declare
  v_job public.content_jobs%rowtype;
  v_post_id uuid;
begin
  select * into v_job from public.content_jobs where id = p_content_job_id;
  if not found then
    raise exception 'content_job not found';
  end if;

  -- Créer le post et le schedule
  insert into public.social_posts (content, objective, target_channels, status, created_at)
  values (v_job.objective, v_job.objective, v_job.channels, 'scheduled', now())
  returning id into v_post_id;

  insert into public.social_schedules (post_id, schedule_at, timezone, created_at)
  values (v_post_id, p_schedule_at, p_timezone, now());

  update public.content_jobs
    set social_post_id = v_post_id,
        status = 'scheduled',
        updated_at = now()
    where id = p_content_job_id;

  return jsonb_build_object('post_id', v_post_id, 'scheduled_at', p_schedule_at);
end;
$$;
grant execute on function public.schedule_content_job(uuid, timestamptz, text) to anon, authenticated;
```

- Créer `2026-01-06_phase69_schedule_content_job.sql` et lancer via `admin_sql.py`.

**Frontend (Dart)**

- Dans `ContentJobService`, ajouter :

```dart
Future<Map<String, dynamic>> scheduleContentJob({
  required String contentJobId,
  required DateTime scheduleAt,
  String timezone = 'UTC',
}) async {
  final res = await _client.rpc('schedule_content_job', params: {
    'p_content_job_id': contentJobId,
    'p_schedule_at': scheduleAt.toUtc().toIso8601String(),
    'p_timezone': timezone,
  });
  return (res as Map).cast<String, dynamic>();
}
```

- Dans `ContentJobsAdminPage`, ajouter un bouton “Planifier” sur les jobs `approved`.

---

### Phase 6 – Reporting 2h / 24h / 7j

**Backend (SQL)**

- Créer les tables d’agrégats :

```sql
create table public.ai_activity_2h (
  bucket timestamptz primary key,
  messages_received int,
  messages_answered_by_ai int,
  messages_ai_skipped int,
  messages_needs_human int,
  alerts_created int,
  created_at timestamptz default now()
);
grant all on public.ai_activity_2h to anon, authenticated;

create table public.ai_activity_daily (
  bucket date primary key,
  messages_received int,
  messages_answered_by_ai int,
  messages_ai_skipped int,
  messages_needs_human int,
  alerts_created int,
  created_at timestamptz default now()
);
grant all on public.ai_activity_daily to anon, authenticated;

create table public.ai_activity_weekly (
  bucket date primary key,
  messages_received int,
  messages_answered_by_ai int,
  messages_ai_skipped int,
  messages_needs_human int,
  alerts_created int,
  created_at timestamptz default now()
);
grant all on public.ai_activity_weekly to anon, authenticated;
```

- Créer les RPC de lecture :

```sql
create or replace function public.get_ai_activity_2h(p_since timestamptz)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (select * from public.ai_activity_2h where bucket >= p_since order by bucket) t;
end;
$$;
grant execute on function public.get_ai_activity_2h(timestamptz) to anon, authenticated;

create or replace function public.get_ai_activity_daily(p_days int)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (select * from public.ai_activity_daily where bucket >= current_date - interval '1 day' * p_days order by bucket) t;
end;
$$;
grant execute on function public.get_ai_activity_daily(int) to anon, authenticated;

create or replace function public.get_ai_activity_weekly(p_weeks int)
returns jsonb
language plpgsql
security defender
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (select * from public.ai_activity_weekly where bucket >= current_date - interval '1 week' * p_weeks order by bucket) t;
end;
$$;
grant execute on function public.get_ai_activity_weekly(int) to anon, authenticated;
```

- Créer `2026-01-06_phase70_ai_activity_tables.sql` et `2026-01-06_phase71_ai_activity_rpcs.sql`, puis lancer via `admin_sql.py`.

**Frontend (Dart)**

- Dans `AnalyticsService`, ajouter :

```dart
Future<List<dynamic>> getAiActivity2h({DateTime? since}) async {
  final res = await _client.rpc('get_ai_activity_2h', params: {
    'p_since': since?.toUtc().toIso8601String(),
  });
  return res as List<dynamic>;
}

Future<List<dynamic>> getAiActivityDaily({int days = 7}) async {
  final res = await _client.rpc('get_ai_activity_daily', params: {'p_days': days});
  return res as List<dynamic>;
}

Future<List<dynamic>> getAiActivityWeekly({int weeks = 4}) async {
  final res = await _client.rpc('get_ai_activity_weekly', params: {'p_weeks': weeks});
  return res as List<dynamic>;
}
```

- Ajouter une page “Supervision IA” (ou enrichir `AnalyticsPage`) avec graphiques 2h / jour / semaine.

---

### Phase 7 – UI d’Inbox enrichie & flux “intervention humaine”

**Frontend (Dart)**

- Dans `ConversationsPage` :

  - Ajouter des filtres sur `author = ai`, `needs_human = true`, `ai_skipped = true`.
  - Ajouter des tags visuels sur les messages selon ces flags.
  - Sur un message `needs_human` :
    - bouton “Répondre en tant qu’humain” (crée un message normal).
    - bouton “Ajouter à la knowledge” (pré-remplit formulaire de la Phase K1).

- Dans `ContentJobsAdminPage` :

  - Ajouter un bouton “Voir les messages liés” si `social_post_id` est renseigné.

---

### Phase 8 – Verrouillage des rôles & sécurité

**Backend (SQL)**

- Définir des rôles (optionnel, selon ta politique) :

```sql
create role ai_orchestrator;
grant usage on schema public to ai_orchestrator;
grant execute on function public.orchestrate_content_job_step(uuid,text,jsonb) to ai_orchestrator;
grant execute on function public.run_ai_reply_for_message(uuid) to ai_orchestrator;
-- etc.

create role marketing_admin;
grant usage on schema public to marketing_admin;
grant select, insert, update on public.content_jobs to marketing_admin;
grant execute on function public.create_content_jobs_from_objective(...) to marketing_admin;
-- etc.

create role operator;
grant usage on schema public to operator;
grant select on public.messages, public.content_jobs to operator;
-- etc.
```

- Ajuster RLS si nécessaire (déjà en place sur la plupart des tables).

- Créer `2026-01-06_phase72_roles_and_security.sql` et lancer via `admin_sql.py`.

---

### Phase 9 – Prompt système OpenRouter “verrouillé”

**Backend (Edge function)**

- Créer une edge function `ai-reply` qui :

  1. Reçoit un payload avec :
     - `message_id`,
     - `brand_rules`,
     - `knowledge_hits`,
     - `context`.
  2. Construit le prompt système (à définir dans un fichier texte ou en base) incluant :
     - Rôle de l’agent (chef d’équipe, pas porte‑parole),
     - Règle d’or “no knowledge → no answer”,
     - Sources autorisées,
     - Format de sortie JSON (`{mode, reply_text, knowledge_refs}`).
  3. Appelle OpenRouter avec ce prompt.
  4. Retourne le JSON structuré.

- Le RPC `run_ai_reply_for_message` (Phase 2) appellera cette edge function.

---

### Phase 10 – Finitions & boucles de feedback

**Backend (SQL)**

- Ajouter des rapports de cohérence :

```sql
create or replace function public.get_content_jobs_without_generation_job()
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (select * from public.content_jobs where format in ('image','video','audio') and generation_job_id is null) t;
end;
$$;
grant execute on function public.get_content_jobs_without_generation_job() to anon, authenticated;

create or replace function public.get_content_jobs_approved_unscheduled()
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (select * from public.content_jobs where status = 'approved' and social_post_id is null) t;
end;
$$;
grant execute on function public.get_content_jobs_approved_unscheduled() to anon, authenticated;

create or replace function public.get_messages_needs_human_older_than(p_hours int)
returns jsonb
language plpgsql
security definer
set search_path = public as
$$
begin
  return jsonb_agg(to_jsonb(t))
  from (select * from public.messages where needs_human = true and created_at < now() - interval '1 hour' * p_hours) t;
end;
$$;
grant execute on function public.get_messages_needs_human_older_than(int) to anon, authenticated;
```

- Créer `2026-01-06_phase73_consistency_reports.sql` et lancer via `admin_sql.py`.

**Frontend (Dart)**

- Dans `AnalyticsService`, ajouter :

```dart
Future<List<dynamic>> getContentJobsWithoutGenerationJob() async {
  final res = await _client.rpc('get_content_jobs_without_generation_job');
  return res as List<dynamic>;
}

Future<List<dynamic>> getContentJobsApprovedUnscheduled() async {
  final res = await _client.rpc('get_content_jobs_approved_unscheduled');
  return res as List<dynamic>;
}

Future<List<dynamic>> getMessagesNeedsHumanOlderThan(int hours) async {
  final res = await _client.rpc('get_messages_needs_human_older_than', params: {'p_hours': hours});
  return res as List<dynamic>;
}
```

- Afficher ces rapports dans la page “Supervision IA”.

---

## 📌 Résumé des fichiers SQL à créer et lancer

| Phase | Fichier SQL | Commande |
|------|------------|----------|
| 1 | `2026-01-06_phase65_extend_messages_for_ai.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase65_extend_messages_for_ai.sql` |
| 2 | `2026-01-06_phase66_run_ai_reply_for_message.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase66_run_ai_reply_for_message.sql` |
| 3 | `2026-01-06_phase67_extend_orchestrate_steps.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase67_extend_orchestrate_steps.sql` |
| 4 | `2026-01-06_phase68_create_content_jobs_from_objective.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase68_create_content_jobs_from_objective.sql` |
| 5 | `2026-01-06_phase69_schedule_content_job.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase69_schedule_content_job.sql` |
| 6 | `2026-01-06_phase70_ai_activity_tables.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase70_ai_activity_tables.sql` |
| 6 | `2026-01-06_phase71_ai_activity_rpcs.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase71_ai_activity_rpcs.sql` |
| 8 | `2026-01-06_phase72_roles_and_security.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase72_roles_and_security.sql` |
| 10 | `2026-01-06_phase73_consistency_reports.sql` | `python tools/admin_sql.py supabase/sql/2026-01-06_phase73_consistency_reports.sql` |

---

## 🚀 Prêt pour implémentation

- **Toutes les commandes SQL sont exactes** et à lancer via `admin_sql.py`.
- **Tous les services Flutter existants** sont déjà présents ; il suffit d’ajouter les méthodes listées.
- **Les UIs existantes** (`ConversationsPage`, `ContentJobsAdminPage`, `MarketingDecisionDashboard`, `AnalyticsPage`) sont prêtes à être enrichies.

---

### 📌 Demande de validation générale

**Veuillez confirmer que ce plan détaillé (phases 1 à 10) est validé.**  
Une fois que tu répondras “OK”, je commencerai l’implémentation phase par phase, sans poser de questions intermédiaires, et je ferai un rapport à la fin de chaque phase avant de continuer.

## 🧩 Annexe A – Vision cible du Studio Marketing Décisionnel (cerveau campagnes Facebook)

> Cette annexe décrit la vision cible à atteindre pour le Studio Marketing Décisionnel.
> Elle ne décrit pas l’état actuel du système, mais la mécanique complète à implémenter progressivement.

### 🎯 Objectif métier

Transformer l’écran **Studio Marketing Décisionnel** (onglet Recommandations, avec les cartes et le bouton `OK – PUBLIER`) en **véritable cerveau de campagnes Facebook**, capable de :

- analyser ce qui fonctionne réellement sur Facebook dans les domaines ciblés (courtage, formation, présentation d’entreprise, etc.) ;
- tenir compte des **objectifs marketing** (vues, abonnés, conversions, notoriété…) ;
- proposer des **posts complets** (idée, format, texte, ton, timing, segmentation marché/audience) adaptés à ces objectifs ;
- orchestrer la **génération des médias** (image, vidéo ou texte seul) via les interfaces réelles de génération ;
- présenter au humain un **bundle complet prêt à publier** (texte + médias + paramètres de diffusion) pour validation ;
- après validation, **publier réellement** sur Facebook en utilisant les connecteurs et tokens configurés (dossier `.unv`) ;
- observer ensuite les performances pour améliorer les futures recommandations.

### 🧠 1. Analyse continue de ce qui marche sur Facebook

- Les agents OpenRouter (marketing‑brain et agents spécialisés) doivent :
  - analyser les posts Facebook dans les **domaines métier** :
    - courtage ;
    - propositions de formation ;
    - présentation d’une nouvelle entreprise / marque ;
  - distinguer les posts selon l’**objectif** :
    - générer des vues ;
    - générer des abonnés ;
    - générer des conversions (leads, inscriptions, achats) ;
  - identifier les **patterns gagnants** :
    - formats (image simple, carousel, vidéo courte, texte seul…) ;
    - tonalité ;
    - structure du message (hook, preuve, appel à l’action) ;
    - type de visuels ;
    - moments de publication.

Ces analyses servent de **base de connaissance dynamique** pour générer les recommandations de posts.

### 🧩 2. Génération de recommandations de posts complets

Sur l’écran Studio Marketing Décisionnel :

- L’IA propose, pour chaque objectif marketing (par ex. présenter l’entreprise, générer des vues, attirer des abonnés, pousser une formation) :
  - une **idée de post** ;
  - un **format recommandé** (image, vidéo, texte seul) ;
  - un **texte de post complet** ;
  - des **suggestions de timing** (“Midi : pic d’activité sur Facebook”, etc.) ;
  - la **segmentation marché/audience** (ex. `bf_ouagadougou`, `students`).

Ces propositions sont affichées dans les cartes de recommandations, avec un indicateur de confiance et un rappel clair :
“Proposition IA – à valider par un humain avant publication.”

### 🎬 3. Orchestration des générateurs de contenu (image / vidéo / texte)

En fonction du format choisi par l’agent :

- **Image** : appel à l’interface réelle de génération d’image (Edge Function connectée à OpenRouter ou autre provider), stockage de l’`asset_url` dans les tables adéquates (`content_jobs`, `image_assets`, etc.) ;
- **Vidéo** : appel à l’interface réelle de génération vidéo (ou composition de segments vidéo), stockage des références ;
- **Texte seul** : simple validation du texte sans média.

Tout ceci doit être **orchestré à partir du même écran** de recommandations, sans passer par des écrans “smoke” ou des mockups.

### ✅ 4. Validation humaine avant publication

- L’interface doit présenter à l’utilisateur :
  - le texte final ;
  - les visuels / vidéos générés ;
  - les paramètres de diffusion (canal, horaire, audience) ;
- L’utilisateur peut **relire, corriger, ajuster** si nécessaire ;
- Le bouton `OK – PUBLIER` signifie explicitement :
  - “Je valide le package complet (texte + média + planning) et j’autorise la publication réelle sur Facebook.”

### 📤 5. Publication réelle sur Facebook

Une fois validé :

- le système crée / met à jour un **post préparé complet** (texte + médias + métadonnées) ;
- il planifie ou publie immédiatement le post via les **wrappers Supabase** et les **tokens / appareils** configurés dans le dossier `.unv` ;
- il trace les identifiants des posts Facebook publiés pour permettre :
  - le suivi des performances ;
  - le rattachement aux `content_jobs` et aux recommandations IA d’origine.

### 📈 6. Boucle d’apprentissage continue

- Après publication, le système :
  - observe les **résultats** (vues, abonnés, conversions…) ;
  - met à jour les **leçons stratégiques** ;
  - réinjecte ces leçons dans le **marketing‑brain** pour améliorer les futures propositions.

Cette boucle d’apprentissage doit fonctionner **sans mocks** : uniquement avec les données et canaux réels.

### 🚦 7. Niveau d’exigence

- La référence d’expérience utilisateur est une application type **Immovia** :
  - l’IA **comprend les objectifs**,
  - **observe** ce qui marche,
  - **propose** des campagnes complètes,
  - et **exécute** (génération + publication) sous contrôle humain.
- Tant que l’on n’a pas atteint ce niveau d’intégration (analyse Facebook → recommandations → génération médias → validation → publication réelle), le Studio Marketing Décisionnel ne doit pas être considéré comme “fini” au sens du besoin métier.
