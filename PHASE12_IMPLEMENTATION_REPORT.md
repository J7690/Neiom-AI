# Phase 12 – Pipeline Runner & Settings Overview

## 1. Objectif de la phase

La Phase 12 introduit :

- Un **orchestrateur de pipeline** unique (`run_pipeline_once`) qui enchaîne routing, auto-réponse, exécution des plannings et collecte de métriques.
- Une vue **centralisée des réglages** (`settings_overview`) pour vérifier rapidement la présence des principaux secrets / paramètres applicatifs (enregistrés dans `app_settings`).

Cela permet aux équipes d’observer l’état du pipeline et de le déclencher sur une période donnée (fenêtre `p_since`) sans devoir appeler chaque RPC séparément.

## 2. Implémentation Supabase (SQL)

### 2.1 Script Phase 12 existant

- Fichier : `supabase/sql/2025-12-16_phase12_pipeline_runner.sql`
- Fonctions définies :

1. `public.run_pipeline_once(p_since interval default '1 hour', p_limit int default 100) RETURNS jsonb`
   - Exécute séquentiellement :
     - `route_unrouted_events(NULL, p_limit)` → `routed`
     - `auto_reply_recent_inbound(p_since, p_limit)` → `auto_replied`
     - `run_schedules_once()` → `schedules_run`
     - `collect_metrics_stub()` → `metrics_collected`
   - Retourne un `jsonb` avec ces 4 compteurs.
   - Déclarée en `SECURITY DEFINER` + `GRANT EXECUTE` pour `anon, authenticated`.

2. `public.settings_overview() RETURNS jsonb`
   - Retourne un `jsonb` contenant des booléens indiquant si certaines clés sont **présentes et non vides** dans `public.app_settings` :
     - `WHATSAPP_VERIFY_TOKEN`
     - `META_APP_SECRET`
     - `OPENROUTER_API_KEY`
     - `NEXIOM_DEFAULT_CHAT_MODEL`
     - `WHATSAPP_PHONE_NUMBER_ID`
     - `WHATSAPP_ACCESS_TOKEN`
     - `WHATSAPP_API_BASE_URL`
   - Déclarée en `SECURITY DEFINER` + `GRANT EXECUTE` pour `anon, authenticated`.

### 2.2 Script d'audit Phase 12

- Fichier : `audit_phase12_readiness.sql`
- Vérifie :
  - Existence des tables / vues de configuration utilisées :
    - `app_settings`, `messages`, `social_posts`, `social_schedules`.
  - Présence des fonctions :
    - `run_pipeline_once`, `settings_overview` (Phase 12),
    - `route_unrouted_events`, `auto_reply_recent_inbound`, `run_schedules_once`, `collect_metrics_stub` (dépendances antérieures).
  - Indique si `settings_overview` est disponible.

### 2.3 Scripts de tests SQL Phase 12

- `test_phase12_tables_only.sql`
  - Vérifie l’existence des tables `app_settings`, `messages`, `social_posts`, `social_schedules`.
  - Vérifie l’existence de `run_pipeline_once` et `settings_overview` dans `pg_proc`.

- `test_phase12_basic.sql`
  - Appelle `public.run_pipeline_once('1 hour', 50)` et retourne le JSON sous `pipeline_run_result`.
  - Appelle `public.settings_overview()` et retourne le JSON sous `settings`.

- `test_phase12_implementation.sql`
  - Lance deux exécutions du pipeline :
    - fenêtre `30 minutes`, limite `50` → expose les champs `routed_30m`, `auto_replied_30m`, `schedules_run_30m`, `metrics_30m`.
    - fenêtre `4 hours`, limite `100` → expose `routed_4h`, `auto_replied_4h`, `schedules_run_4h`, `metrics_4h`.
  - Projette ensuite les booléens de `settings_overview` pour toutes les clés critiques. Ces booléens peuvent être `false` si les clés ne sont pas encore configurées.

## 3. Intégration Flutter / Nexiom Studio

### 3.1 Services existants

- Fichier : `nexiom_ai_studio/lib/features/messaging/services/messaging_service.dart`
  - Méthode `runPipelineOnce({String? since, int limit = 100})` :
    - Appelle `rpc('run_pipeline_once', params: { 'p_limit': limit, 'p_since': since })`.
  - Méthode `settingsOverview()` :
    - Appelle `rpc('settings_overview')` et retourne le JSON.

Ces méthodes exposent déjà les capacités de la Phase 12 dans le Studio (pages de dev / outils internes).

## 4. Points importants sur les réglages WhatsApp

Les clés suivantes dans `settings_overview` reflètent l’état de la table `app_settings` :

- `WHATSAPP_PHONE_NUMBER_ID`
- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_API_BASE_URL`

Actuellement, ces valeurs peuvent être **absentes ou vides** dans `app_settings`, ce qui est attendu tant que la configuration WhatsApp Cloud API n’a pas été renseignée.

Elles doivent rester suivies comme **tâches inachevées** au niveau infra / devops (et non au niveau du code Supabase/Flutter qui est déjà prêt à les consommer).

## 5. Résumé d'état Phase 12

- **Supabase**
  - Script `supabase/sql/2025-12-16_phase12_pipeline_runner.sql` appliqué.
  - Scripts d’audit et de tests Phase 12 créés :
    - `audit_phase12_readiness.sql`
    - `test_phase12_tables_only.sql`
    - `test_phase12_basic.sql`
    - `test_phase12_implementation.sql`

- **Flutter / Nexiom Studio**
  - `MessagingService` expose déjà `runPipelineOnce` et `settingsOverview`.
  - Aucun nouveau service Flutter spécifique requis.

## 6. Étapes d'exécution recommandées

Pour (ré)appliquer et tester la Phase 12 :

1. Script principal Phase 12 :
   - `python tools/admin_sql.py supabase/sql/2025-12-16_phase12_pipeline_runner.sql`
2. Audit :
   - `python tools/admin_sql.py audit_phase12_readiness.sql`
3. Tests :
   - `python tools/admin_sql.py test_phase12_tables_only.sql`
   - `python tools/admin_sql.py test_phase12_basic.sql`
   - `python tools/admin_sql.py test_phase12_implementation.sql`

Après ces étapes, la Phase 12 (Pipeline Runner & Settings Overview) est **opérationnelle** côté Supabase et accessible depuis le Studio via `MessagingService`.
