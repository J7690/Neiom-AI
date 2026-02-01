# Phase 11 – Outils sans secrets (Content, Auto-planification, Seed, Auto-reply)

## 1. Objectif de la phase

La Phase 11 fournit des **outils d’aide au marketing** qui ne nécessitent **aucun secret externe** (pas de tokens d’API) :

- Génération d’un **texte de post** simplifié (`suggest_content_stub`).
- Création et **planification automatique d’un post** (`create_and_schedule_post_stub`).
- Injection de **messages inbound aléatoires** pour tester le pipeline (`seed_random_messages`).
- Exécution d’**auto-réponses en batch** sur les messages inbound récents (`auto_reply_recent_inbound`).

Ces outils sont pensés pour les équipes marketing / dev afin de tester, démo et exercer le pipeline complet sans dépendre d’intégrations externes.

## 2. Implémentation Supabase (SQL)

### 2.1 Script Phase 11 existant

- Fichier : `supabase/sql/2025-12-16_phase11_no_secrets_tools.sql`
- Fonctions définies :

1. `public.suggest_content_stub(p_objective text, p_tone text default 'neutre', p_length int default 120) RETURNS text`
   - Construit un texte de post simple à partir de :
     - un **tone** (`neutre`, `enthousiaste`, `professionnel`, `convivial`),
     - un **objectif** (`p_objective`),
     - une **longueur cible** (`p_length`).
   - Applique une intro en fonction du ton, concatène l’objectif + un CTA générique.
   - Tronque le texte si nécessaire.
   - Exposé via `GRANT EXECUTE` à `anon, authenticated`.

2. `public.create_and_schedule_post_stub(p_author_agent text, p_objective text, p_target_channels text[], p_schedule_at timestamptz default now(), p_timezone text default 'UTC', p_tone text default 'neutre', p_length int default 120) RETURNS jsonb`
   - Utilise `suggest_content_stub` pour générer un contenu.
   - Appelle `public.create_social_post(...)` pour créer une entrée dans `social_posts`.
   - Appelle `public.schedule_social_post(...)` pour créer une entrée dans `social_schedules`.
   - Retourne un JSON avec `post_id`, `schedule_id`, `content`.
   - Exposé à `anon, authenticated`.

3. `public.seed_random_messages(p_channels text[] default array['whatsapp','facebook','instagram','tiktok','youtube'], p_count int default 10) RETURNS int`
   - Boucle `p_count` fois :
     - Tire un canal aléatoire dans `p_channels`.
     - Génére un nom/prénom aléatoire et un message court.
     - Appelle `public.simulate_message(...)` pour injecter un inbound dans le pipeline.
   - Retourne le nombre de messages injectés.
   - Exposé à `anon, authenticated`.

4. `public.auto_reply_recent_inbound(p_since interval default '1 hour', p_limit int default 50) RETURNS int`
   - Parcourt les messages inbound récents (`direction = 'inbound'`, `sent_at >= now() - p_since`) limités à `p_limit`.
   - Pour chaque message, appelle `public.auto_reply_stub(m.id)` dans un bloc `begin/exception` pour ne pas casser le batch.
   - Incrémente un compteur de réponses et le retourne.
   - Exposé à `anon, authenticated`.

### 2.2 Script d'audit Phase 11

- Fichier : `audit_phase11_readiness.sql`
- Vérifie :
  - Existence des tables :
    - `social_posts`, `social_schedules`, `messages`, `leads`.
  - Présence des fonctions Phase 11 et dépendances :
    - `suggest_content_stub`, `create_and_schedule_post_stub`, `seed_random_messages`, `auto_reply_recent_inbound`,
    - `create_social_post`, `schedule_social_post`, `simulate_message`, `auto_reply_stub`.
  - Retourne également quelques métriques agrégées :
    - `messages_total`, `social_posts_total`, `social_schedules_total`.

### 2.3 Scripts de tests SQL Phase 11

- `test_phase11_tables_only.sql`
  - Vérifie l’existence des tables cibles.
  - Vérifie la présence des 4 fonctions principales Phase 11 dans `pg_proc`.

- `test_phase11_basic.sql`
  - Appelle `suggest_content_stub` avec un objectif Phase 11 et récupère le texte.
  - Appelle `create_and_schedule_post_stub` pour créer + planifier un post sur `facebook`/`instagram`.
  - Appelle `seed_random_messages` pour injecter quelques messages inbound.
  - Appelle `auto_reply_recent_inbound` sur une petite fenêtre (1 heure) pour obtenir un compteur de réponses.

- `test_phase11_implementation.sql`
  - Génère plusieurs contenus avec des tones différents (`neutre`, `enthousiaste`, `professionnel`, `convivial`).
  - Crée et planifie deux posts de test Phase 11 sur `facebook` et `instagram`.
  - Lance `seed_random_messages` sur quelques canaux, puis `auto_reply_recent_inbound` sur une fenêtre élargie (2 heures).

## 3. Intégration Flutter / Nexiom Studio

### 3.1 Services existants

- Fichier : `nexiom_ai_studio/lib/features/publishing/services/social_posts_service.dart`
  - Méthode `suggestContentStub(...)`
    - Appelle l’RPC `suggest_content_stub` avec `p_objective`, `p_tone`, `p_length`.
  - Méthode `createAndSchedulePostStub(...)`
    - Appelle l’RPC `create_and_schedule_post_stub` pour générer et planifier un post.

- Fichier : `nexiom_ai_studio/lib/features/messaging/services/messaging_service.dart`
  - Méthode `seedRandomMessages(...)`
    - Appelle l’RPC `seed_random_messages` pour injecter des messages inbound.
  - Méthode `autoReplyRecentInbound(...)`
    - Appelle l’RPC `auto_reply_recent_inbound` pour exécuter les auto-réponses.

Conclusion : les RPC Phase 11 sont **déjà exposées** dans les services Flutter existants, aucune nouvelle classe de service n’est requise.

## 4. Résumé d'état Phase 11

- **Supabase**
  - Script `supabase/sql/2025-12-16_phase11_no_secrets_tools.sql` : fonctions Phase 11 définies et `GRANT EXECUTE` appliqué.
  - Scripts ajoutés :
    - `audit_phase11_readiness.sql`
    - `test_phase11_tables_only.sql`
    - `test_phase11_basic.sql`
    - `test_phase11_implementation.sql`

- **Flutter / Nexiom Studio**
  - `SocialPostsService` : génération et auto-planification de posts via RPC Phase 11.
  - `MessagingService` : injection de messages aléatoires et auto-réponse récente.

## 5. Étapes d'exécution recommandées

Pour (ré)appliquer et tester la Phase 11 :

1. Script principal Phase 11 :
   - `python tools/admin_sql.py supabase/sql/2025-12-16_phase11_no_secrets_tools.sql`
2. Audit :
   - `python tools/admin_sql.py audit_phase11_readiness.sql`
3. Tests :
   - `python tools/admin_sql.py test_phase11_tables_only.sql`
   - `python tools/admin_sql.py test_phase11_basic.sql`
   - `python tools/admin_sql.py test_phase11_implementation.sql`

Après ces étapes, la Phase 11 (No-secrets Tools) est **opérationnelle** côté Supabase et directement utilisable depuis le Studio Nexiom.
