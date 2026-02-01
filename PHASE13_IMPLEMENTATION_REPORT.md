# Phase 13 – Editorial Plan, Recent Activity & Metrics Timeseries

## 1. Objectif de la phase

La Phase 13 complète les outils de pilotage éditorial et de monitoring par :

- La génération d’un **plan éditorial multi-jours** via `create_editorial_plan_stub`.
- Une vue **activité récente** (messages, posts, plannings, leads) via `get_recent_activity`.
- Une **timeseries de métriques** sur plusieurs jours via `get_metrics_timeseries`.
- Un outil de **mise à jour de réglages** applicatifs via `upsert_setting`.

Ces capacités sont utilisées par la page Dev Tools du Studio pour piloter et observer le pipeline.

## 2. Implémentation Supabase (SQL)

### 2.1 Script Phase 13 existant

- Fichier : `supabase/sql/2025-12-16_phase13_editorial_activity_timeseries.sql`
- Fonctions définies :

1. `public.create_editorial_plan_stub(p_author_agent text, p_objective text, p_start_date timestamptz default now(), p_days int default 7, p_channels text[] default '{}'::text[], p_timezone text default 'UTC', p_tone text default 'neutre', p_length int default 120) RETURNS jsonb`
   - Pour chaque jour sur la période `p_days` :
     - Génère un contenu avec `suggest_content_stub`.
     - Crée un post via `create_social_post`.
     - Planifie la publication via `schedule_social_post` à `p_start_date + i jours`.
   - Retourne un JSON `{'items': [...]}` listant `post_id`, `schedule_id`, `scheduled_at`.

2. `public.get_recent_activity(p_limit int default 50) RETURNS jsonb`
   - Retourne un objet `jsonb` avec :
     - `messages` : derniers messages (id, sent_at, channel, direction, extrait de contenu).
     - `posts` : derniers posts (id, created_at, status, channels, extrait de contenu).
     - `schedules` : dernières planifications (id, scheduled_at, timezone).
     - `leads` : derniers leads (id, created_at, status).

3. `public.get_metrics_timeseries(p_days int default 7) RETURNS jsonb`
   - Construit une série de dates sur les `p_days` derniers jours.
   - Pour chaque date, compile :
     - `messages_in` (inbound par jour)
     - `messages_out` (outbound par jour)
     - `social_posts` (posts créés par jour)
     - `leads` (leads créés par jour)
   - Retourne un `jsonb` (tableau de points `{date, messages_in, messages_out, social_posts, leads}`).

4. `public.upsert_setting(p_key text, p_value text) RETURNS boolean`
   - Insère ou met à jour (`ON CONFLICT`) la ligne correspondante dans `public.app_settings`.
   - Retourne `true` en cas de succès.

Toutes ces fonctions sont **`SECURITY DEFINER`** et exposées à `anon, authenticated` via `GRANT EXECUTE`.

### 2.2 Script d'audit Phase 13

- Fichier : `audit_phase13_readiness.sql`
- Vérifie :
  - Existence des tables clés : `social_posts`, `social_schedules`, `messages`, `leads`, `app_settings`.
  - Existence des fonctions Phase 13 :
    - `create_editorial_plan_stub`
    - `get_recent_activity`
    - `get_metrics_timeseries`
    - `upsert_setting`
  - Retourne aussi quelques agrégats simples (totaux messages, posts, plannings, leads).

### 2.3 Scripts de tests SQL Phase 13

- `test_phase13_tables_only.sql`
  - Vérifie existence des tables et fonctions listées ci‑dessus via `to_regclass` et `pg_proc`.

- `test_phase13_basic.sql`
  - Génère un petit plan éditorial de 3 jours (`create_editorial_plan_stub`).
  - Récupère l’activité récente (`get_recent_activity(20)`).
  - Récupère une timeseries de 5 jours (`get_metrics_timeseries(5)`).
  - Fait un `upsert_setting('PHASE13_TEST_SETTING','ok')` pour vérifier l’écriture dans `app_settings`.

- `test_phase13_implementation.sql`
  - Génère un plan éditorial de 7 jours sur plusieurs canaux.
  - Récupère l’activité récente avec un `limit` plus élevé (100).
  - Récupère une timeseries de 10 jours.
  - Exécute plusieurs `upsert_setting` sur des clés déjà utilisées par d’autres phases (chat model, Meta, WhatsApp verify token) afin de s’assurer que la fonction gère correctement les mises à jour.

## 3. Intégration Flutter / Nexiom Studio

### 3.1 Services existants

- Fichier : `nexiom_ai_studio/lib/features/publishing/services/social_posts_service.dart`
  - Méthode `createEditorialPlanStub(...)` :
    - Appelle l’RPC `create_editorial_plan_stub`.

- Fichier : `nexiom_ai_studio/lib/features/messaging/services/messaging_service.dart`
  - Méthode `getRecentActivity({int limit = 50})` :
    - Appelle l’RPC `get_recent_activity`.
  - Méthode `getMetricsTimeseries({int days = 7})` :
    - Appelle l’RPC `get_metrics_timeseries`.
  - Méthode `upsertSetting({required String key, required String value})` :
    - Appelle l’RPC `upsert_setting`.

- Fichier : `nexiom_ai_studio/lib/features/dev/pages/dev_tools_page.dart`
  - Utilise ces services pour :
    - Générer un plan éditorial (`_doPlan`) via `createEditorialPlanStub`.
    - Afficher l’activité récente (`_doActivity`) via `getRecentActivity`.
    - Afficher les timeseries (`_doTimeseries`) via `getMetricsTimeseries`.
    - Mettre à jour des réglages (`_doUpsertSetting`) via `upsertSetting`.

Conclusion : côté Flutter, la Phase 13 est déjà exposée dans les outils Dev et via les services existants.

## 4. Résumé d'état Phase 13

- **Supabase**
  - Script `supabase/sql/2025-12-16_phase13_editorial_activity_timeseries.sql` définit toutes les fonctions Phase 13.
  - Scripts ajoutés :
    - `audit_phase13_readiness.sql`
    - `test_phase13_tables_only.sql`
    - `test_phase13_basic.sql`
    - `test_phase13_implementation.sql`

- **Flutter / Nexiom Studio**
  - `SocialPostsService` et `MessagingService` consomment déjà ces RPC.
  - Dev Tools fournit une UI pour plan éditorial, activité récente, métriques et upsert de réglages.

## 5. Étapes d'exécution recommandées

Pour (ré)appliquer et tester la Phase 13 :

1. Script principal Phase 13 :
   - `python tools/admin_sql.py supabase/sql/2025-12-16_phase13_editorial_activity_timeseries.sql`
2. Audit :
   - `python tools/admin_sql.py audit_phase13_readiness.sql`
3. Tests :
   - `python tools/admin_sql.py test_phase13_tables_only.sql`
   - `python tools/admin_sql.py test_phase13_basic.sql`
   - `python tools/admin_sql.py test_phase13_implementation.sql`

Après ces étapes, la Phase 13 (Plan éditorial, Activité récente, Timeseries) est **opérationnelle** côté Supabase et pleinement accessible depuis le Studio Nexiom.
