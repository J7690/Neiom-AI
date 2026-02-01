# Phase 10 – Admin Observability & Comment Simulation

## 1. Objectif de la phase

La Phase 10 introduit des capacités d'**observabilité admin** et de **simulation de commentaires** pour tester le pipeline sans dépendre uniquement des webhooks externes.

Les objectifs principaux :

- Offrir un **tableau de bord pipeline** côté Supabase via `get_pipeline_stats()`.
- Permettre à l'équipe de **simuler un commentaire** entrant (`simulate_comment`) pour valider le flux ingestion → routing → analyse.
- Exposer ces capacités dans le **Studio Nexiom** (Dev Tools) pour usage par les équipes.

## 2. Implémentation Supabase (SQL)

### 2.1 Script Phase 10 existant

- Fichier : `supabase/sql/2025-12-16_phase10_admin_observability.sql`
- Fonctions créées / mises à jour :

1. `public.get_pipeline_stats()`
   - Retourne un `jsonb` avec :
     - `contacts` : COUNT(*) de `public.contacts`.
     - `contact_channels` : COUNT(*) de `public.contact_channels`.
     - `conversations` : objet JSON avec `total`, `open`, `closed`.
     - `messages` : objet JSON avec `total`, `inbound`, `outbound`.
     - `webhook_events` : objet JSON avec `total`, `unrouted`.
     - `social_posts` : total et répartition par `status`.
     - `social_schedules` : COUNT(*) de `public.social_schedules`.
     - `social_metrics` : COUNT(*) de `public.social_metrics`.
     - `leads` : répartition JSON par `status`.
   - Exposé à `anon, authenticated` via `GRANT EXECUTE`.

2. `public.simulate_comment(p_channel text, p_author_id text, p_author_name text, p_content text, p_event_id text default null, p_event_date timestamptz default now())`
   - Construit un `event_id` (`p_event_id` ou `gen_random_uuid()`).
   - Appelle `public.ingest_route_analyze(...)` avec `type = 'comment'`.
   - Retourne le `jsonb` fourni par `ingest_route_analyze`, incluant typiquement `conversation_id` et `message_id`.
   - Exposé à `anon, authenticated` via `GRANT EXECUTE`.

### 2.2 Script d'audit Phase 10

- Fichier : `audit_phase10_readiness.sql`
- Vérifie :
  - Existence des tables utilisées par `get_pipeline_stats` :
    - `contacts`, `contact_channels`, `conversations`, `messages`, `webhook_events`,
      `social_posts`, `social_schedules`, `social_metrics`, `leads`.
  - Existence des fonctions :
    - `get_pipeline_stats`
    - `simulate_comment`
    - `ingest_route_analyze` (dépendance de simulation).
  - Indique si `get_pipeline_stats` est disponible.

### 2.3 Scripts de tests SQL Phase 10

- `test_phase10_tables_only.sql`
  - Contrôle l'existence des tables listées ci‑dessus via `to_regclass`.
  - Vérifie que les fonctions `get_pipeline_stats`, `simulate_comment`, `ingest_route_analyze` sont présentes dans `pg_proc`.

- `test_phase10_basic.sql`
  - Utilise `public.simulate_comment('facebook', ...)` dans un `WITH` puis :
    - Vérifie, via SELECT, que `conversation_id` et `message_id` sont non nuls dans le JSON retourné.
  - Appelle `public.get_pipeline_stats()` et expose le résultat sous forme de colonne `pipeline_stats` (sans assertions bloquantes).

- `test_phase10_implementation.sql`
  - Simule trois commentaires sur différents canaux (`facebook`, `instagram`, `tiktok`).
  - Vérifie, via SELECT, que chaque simulation renvoie un `conversation_id` non nul.
  - Appelle `public.get_pipeline_stats()` et extrait quelques métriques clés :
    - `contacts_total`
    - `webhook_total`, `webhook_unrouted`
    - `messages_total`
    - `leads_by_status` (JSON texte)

## 3. Intégration Flutter / Nexiom Studio

### 3.1 Services existants

- Fichier : `nexiom_ai_studio/lib/features/messaging/services/messaging_service.dart`
  - Méthode existante :
    - `Future<Map<String, dynamic>> getPipelineStats()` qui appelle l'RPC `get_pipeline_stats` côté Supabase et retourne le JSON casté en `Map<String, dynamic>`.

- Fichier : `nexiom_ai_studio/lib/features/dev/pages/dev_tools_page.dart`
  - Utilise `getPipelineStats()` pour afficher les statistiques pipeline.
  - Appelle directement `Supabase.instance.client.rpc('simulate_comment', ...)` dans `_doSimComment()` pour simuler un commentaire de test.

### 3.2 Conclusion côté Flutter

- Aucune nouvelle classe de service dédiée n'est nécessaire pour la Phase 10 :
  - `MessagingService` couvre déjà `getPipelineStats()`.
  - La page `DevToolsPage` déclenche `simulate_comment` pour la simulation manuelle.

## 4. Résumé d'état Phase 10

- **Supabase**
  - Script `supabase/sql/2025-12-16_phase10_admin_observability.sql` :
    - Définit `get_pipeline_stats()` et `simulate_comment(...)`.
  - Scripts Phase 10 créés :
    - `audit_phase10_readiness.sql`
    - `test_phase10_tables_only.sql`
    - `test_phase10_basic.sql`
    - `test_phase10_implementation.sql`

- **Flutter / Nexiom Studio**
  - `MessagingService` expose `getPipelineStats()`.
  - `DevToolsPage` utilise `simulate_comment` et `getPipelineStats` pour outiller les développeurs / ops.

## 5. Étapes d'exécution recommandées

Pour valider et rejouer la Phase 10 :

1. Appliquer / réappliquer le script principal :
   - `python tools/admin_sql.py supabase/sql/2025-12-16_phase10_admin_observability.sql`
2. Audit :
   - `python tools/admin_sql.py audit_phase10_readiness.sql`
3. Tests :
   - `python tools/admin_sql.py test_phase10_tables_only.sql`
   - `python tools/admin_sql.py test_phase10_basic.sql`
   - `python tools/admin_sql.py test_phase10_implementation.sql`

Après ces étapes, la Phase 10 (Admin Observability & Comment Simulation) est **opérationnelle** côté Supabase et pleinement accessible depuis le Studio Nexiom.
