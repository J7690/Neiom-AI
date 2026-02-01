# Phase 9 – Batch Routing for Webhook Events

## 1. Objectif de la phase

Phase 9 renforce le pipeline de messagerie en ajoutant :

- **Routage unitaire et batch** des `webhook_events` vers `contacts` / `conversations` / `messages`.
- **Idempotence** sur les événements déjà routés ou déjà convertis en messages.
- **Marquage explicite** des événements routés via la colonne `webhook_events.routed_at`.

Cette phase s'appuie sur la base d'ingestion (Phase 4) et sur les capacités d'analyse / auto‑reply (Phases 8+), pour fiabiliser le flux "event → conversation → message".

## 2. Implémentation Supabase (SQL)

### 2.1 Script existant de référence

- Fichier : `supabase/sql/2025-12-16_phase9_event_routing_batch.sql`
- Contenu clé :
  - `ALTER TABLE IF EXISTS public.webhook_events ADD COLUMN IF NOT EXISTS routed_at timestamptz;`
  - Fonction `public.route_webhook_event(p_channel text, p_event_id text)` (version enrichie) :
    - Récupère l'événement dans `public.webhook_events`.
    - Résout / crée le `contact` et le `contact_channels` associé.
    - Résout / crée la `conversation` ouverte pour ce contact et ce canal.
    - Insère un `message` inbound correspondant au contenu de l'événement.
    - Met à jour `public.conversations.last_message_at`.
    - **NOUVEAU Phase 9** : met à jour `public.webhook_events.conversation_id` + `routed_at`.
    - Retourne `jsonb_build_object('conversation_id', ..., 'message_id', ...)`.
  - Fonction `public.route_unrouted_events(p_channel text default null, p_limit integer default 100)` :
    - Parcourt les événements `webhook_events` avec `routed_at IS NULL` (filtrés par canal optionnel).
    - Si un `message` existe déjà pour `(channel, event_id)`, marque simplement `routed_at` et `conversation_id`.
    - Sinon, appelle `public.route_webhook_event(...)`.
    - Retourne le nombre d'événements traités.

Ces fonctions sont **`SECURITY DEFINER`** et exposées à `anon, authenticated` via `GRANT EXECUTE`.

### 2.2 Script d'audit Phase 9

- Fichier : `audit_phase9_readiness.sql`
- Vérifie :
  - Existence des tables : `webhook_events`, `contacts`, `contact_channels`, `conversations`, `messages`, `message_analysis`.
  - Présence de la colonne `webhook_events.routed_at`.
  - Existence des fonctions :
    - `ingest_webhook_event`
    - `route_webhook_event`
    - `analyze_message_simple`
    - `route_unrouted_events`
  - Présence (optionnelle) des fonctions Phase 8 :
    - `ingest_instagram_webhook`
    - `ai_reply_template`
    - `auto_reply_stub`
  - Compte d'événements non routés (`routed_at IS NULL`).

### 2.3 Scripts de tests SQL Phase 9

- `test_phase9_tables_only.sql`
  - Vérifie l'existence des tables cœur et de la colonne `webhook_events.routed_at`.
  - Vérifie l'existence des fonctions `ingest_webhook_event`, `route_webhook_event`, `route_unrouted_events`.

- `test_phase9_basic.sql`
  - Invoque `public.ingest_webhook_event(...)` pour créer un événement `phase9_test_evt_basic_1`.
  - Appelle `public.route_webhook_event('instagram', 'phase9_test_evt_basic_1')`.
  - Contrôle :
    - L'événement a `conversation_id` non nul et `routed_at` non nul.
    - Au moins un `message` existe dans `public.messages` avec `provider_message_id = 'phase9_test_evt_basic_1'`.

- `test_phase9_implementation.sql`
  - Ingère trois événements `phase9_test_evt_batch_1..3`.
  - Réinitialise `routed_at` et `conversation_id` pour ces événements (test ré‑exécutable).
  - Appelle `public.route_unrouted_events(NULL, 50)`.
  - Contrôle :
    - Chaque événement batch a `routed_at` non nul et un `conversation_id` non nul.
    - Affiche le nombre de `messages` créés par `provider_message_id`.

## 3. Implémentation Flutter / Nexiom Studio

### 3.1 Services existants

- Fichier : `nexiom_ai_studio/lib/features/messaging/services/messaging_service.dart`
- Méthode clé déjà présente :
  - `Future<int> routeUnroutedEvents({String? channel, int limit = 100})` qui appelle l'RPC `route_unrouted_events` côté Supabase.
- Le reste des méthodes (`simulateMessage`, `autoReplyForMessage`, etc.) s'appuie déjà sur les RPC d'ingestion / analyse existantes.

Conclusion : **aucun nouveau service Flutter dédié n'est nécessaire pour Phase 9**, la fonctionnalité étant déjà exposée via `MessagingService`.

## 4. Résumé d'état Phase 9

- **Supabase**
  - Script `2025-12-16_phase9_event_routing_batch.sql` : définit / met à jour `route_webhook_event` et `route_unrouted_events`, ajoute `webhook_events.routed_at`.
  - Script `audit_phase9_readiness.sql` : prêt pour audit ciblé Phase 9.
  - Scripts `test_phase9_tables_only.sql`, `test_phase9_basic.sql`, `test_phase9_implementation.sql` : prêts pour validation fonctionnelle.

- **Flutter / Nexiom Studio**
  - `MessagingService` expose déjà `routeUnroutedEvents` et peut piloter le batch routing.
  - Aucune modification supplémentaire imposée pour Phase 9.

- **Limitations / Points à noter**
  - La qualité des données en entrée (structure de `webhook_events`) dépend toujours des intégrations amont (Meta/Instagram/WhatsApp, etc.).
  - Le comportement en batch (`route_unrouted_events`) est volontairement **idempotent** sur `(channel, event_id)` et sur les messages déjà créés.

## 5. Étapes suivantes

- Exécuter via `tools/admin_sql.py` :
  - `supabase/sql/2025-12-16_phase9_event_routing_batch.sql`
  - `audit_phase9_readiness.sql`
  - `test_phase9_tables_only.sql`
  - `test_phase9_basic.sql`
  - `test_phase9_implementation.sql`

Après ces exécutions, Phase 9 (Batch Routing) est considérée comme **opérationnelle** côté Supabase et pilotable depuis le Studio via `MessagingService`.
