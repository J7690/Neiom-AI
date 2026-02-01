# Nexiom – Règles de travail (.windsurf)

Ce document définit les règles de rigueur à appliquer pour **toutes les tâches** réalisées avec Windsurf sur le projet **Nexiom AI Studio** (Flutter Web + Supabase + OpenRouter).

---

## 1. Objectifs des règles

- Assurer une **qualité constante** (code propre, architecture respectée).
- Protéger les **clés et secrets** (OpenRouter, Supabase, etc.).
- Garder une **UX cohérente** (comparable aux bons outils du marché : Canva, Runway, Pika…).
- Faciliter la **maintenance** et l’évolution du projet.

---

## 2. Processus standard pour chaque tâche

Pour toute nouvelle tâche (feature, bugfix, refactor, doc), suivre **strictement** ces étapes :

### 2.1. Compréhension & clarification
- Lire attentivement la demande de l’utilisateur.
- **Reformuler** en une ou deux phrases ce qui est demandé.
- Si un point est flou, **poser des questions** avant de toucher au code.

### 2.2. Planification (TODOs)
- Créer ou mettre à jour la TODO list avec l’outil dédié.
- Découper la tâche en sous-tâches claires, par exemple :
  - analyse du code existant,
  - design technique,
  - implémentation Flutter,
  - implémentation backend Supabase,
  - tests / validation.
- Marquer les TODOs comme **terminés** dès qu’une étape est finie.
 
### 2.3. Audit Flutter & Supabase (obligatoire)
- **Avant toute écriture ou modification de code**, effectuer un double audit systématique :
  - Cette étape est **obligatoire pour toutes les tâches** (feature, bugfix, refactor, doc, infra Supabase) ; aucune recommandation ni implémentation ne doit être produite sans cet audit préalable côté Flutter **et** côté Supabase.
  - **Audit Flutter** :
    - localiser précisément la page, la section, le widget et le service concernés (ex. `VideoPage`, `PromptInput`, `OpenRouterService`),
    - lire la structure du flux existant (navigation, state management, appels réseau déjà présents),
    - identifier les impacts possibles sur les autres parties de l’UI.
  - **Audit Supabase** :
    - identifier les tables, vues, RPC, fonctions Edge, buckets Storage déjà liés à la fonctionnalité (ex. `generation_jobs`, `generate-video`, `inputs`, `outputs`),
    - vérifier les permissions actuelles (rôles utilisés, usage de `service_role`, contraintes de sécurité),
    - analyser les flux existants de lecture/écriture pour éviter les doublons et les régressions,
    - lorsque des RPC d’administration existent (ex. `admin_execute_sql` ou vues d’inspection), les utiliser pour auditer le schéma, les index, les règles RLS et les objets existants plutôt que de supposer la structure.
- Documenter mentalement (ou dans la TODO) le résultat de cet audit avant de passer au design, aux recommandations ou à l’implémentation.

### 2.4. Analyse du code existant
- Utiliser les outils de recherche de code pour localiser les fichiers concernés.
- Lire les fichiers **en entier** si nécessaire (eviter de modifier sans contexte).
- Respecter la structure d’architecture existante :
  - `lib/features/...` pour le front Flutter,
  - `lib/core/...` pour les utilitaires et la config,
  - `supabase/functions/...` (ou équivalent) pour les Edge Functions.

### 2.5. Design technique rapide
- Avant d’implémenter, décider **où** mettre le code :
  - widgets → dans `features/.../widgets`,
  - pages → dans `features/.../pages`,
  - appels API → dans `services/`,
  - constantes / utils → dans `core/constants` ou `core/utils`,
  - logique backend → dans les Edge Functions Supabase.
- Vérifier que le design respecte :
  - la séparation **UI / services / modèles**, 
  - la nouvelle architecture **Supabase Edge Functions + OpenRouter**, 
  - l’utilisation de **Supabase Storage** pour les médias.

### 2.6. Implémentation
- Pour le **front Flutter** :
  - Ne jamais appeler OpenRouter directement depuis un widget.
  - Passer par un **service** (ex. `OpenRouterService`) qui lui-même appelle le backend Supabase.
  - Ne pas mettre de clé API dans le code client (même dans `env.dart`, sauf prototype local très limité).
- Pour le **backend Supabase (Edge Functions)** :
  - Une fonction = une responsabilité claire (`/generate/video`, `/generate/image`, `/generate/audio`).
  - Lire le `prompt`, les paramètres (durée, modèle, etc.), et les chemins de médias de référence.
  - Appeler OpenRouter avec la clé **stockée côté serveur** (variables d’environnement Supabase).
  - Stocker les médias générés dans **Supabase Storage** (dossier `outputs/`).
- Pour la **gestion des médias de référence (image/vidéo/voix)** :
  - Le front **upload** toujours les fichiers vers **Supabase Storage** (dossier `inputs/`).
  - Le front envoie au backend **uniquement** le chemin/URL du fichier, pas le base64 brut.
  - Le backend, si nécessaire, convertit en base64 ou télécharge le fichier pour l’envoyer à OpenRouter.

### 2.7. Validation & auto‑revue
- Relire les changements :
  - imports corrects,
  - pas de doublons,
  - pas de clé API ou secret exposé,
  - gestion des erreurs minimale (try/catch, messages clairs côté UI).
- Vérifier que les nouveaux flux respectent :
  - les limitations de durée (10–60s pour la vidéo),
  - les tailles de fichiers upload (limites raisonnables),
  - les formats prévus (MP4, PNG/JPEG, MP3, etc.).

### 2.8. Récapitulatif pour l’utilisateur
- Expliquer **brièvement** :
  - ce qui a été fait,
  - les fichiers principaux modifiés ou créés,
  - comment utiliser la nouvelle fonctionnalité (si besoin).

---

## 3. Règles spécifiques Nexiom (métier)

### 3.1. Vidéo (10–60 secondes)
- Toujours permettre à l’utilisateur de choisir une durée parmi : `10s`, `20s`, `30s`, `60s`.
- Indiquer dans l’UI que **30–60s peuvent prendre plus de temps**.
- Pour les durées longues (≥ 30s), privilégier un fonctionnement **asynchrone** côté backend (jobs en file d’attente) dès que c’est implémenté.

### 3.2. Images
- Supporter au minimum les résolutions courantes (ex. 512×512, 1024×1024) définies dans les constantes.
- Offrir un prompt textuel + éventuellement un média de référence (image uploadée).

### 3.3. Audio / Voix off / Clonage vocal
- Entrée obligatoire : texte.
- Optionnel : fichier voix de référence pour le clonage (upload → Storage → path envoyé au backend).
- Format cible par défaut : **MP3**.

### 3.4. Médias de référence (environnement)
- Pour reproduire un environnement à partir d’une **photo ou vidéo** :
  - toujours uploader le média vers Supabase Storage (`inputs/`),
  - transmettre au backend l’information de contexte (par ex. `referenceMediaPath` + une indication de type),
  - laisser le backend décider comment adapter la requête OpenRouter (URL directe ou base64).

---

## 4. Style de code & organisation

### 4.1. Pour Flutter/Dart
- Respecter la structure :
  - `features/generator/pages` pour les pages,
  - `features/generator/widgets` pour les composants réutilisables,
  - `features/generator/services` pour les appels réseau et logique de génération,
  - `features/generator/models` pour les modèles de données,
  - `core/config`, `core/constants`, `core/utils` pour la configuration et les utilitaires.
- Ne pas ajouter ni supprimer de commentaires existants, sauf demande explicite.
- Nommer les classes, fonctions et variables en **anglais clair**, par ex. `GenerationResult`, `generateVideo`, `referenceMediaPath`.

### 4.2. Pour le backend (Supabase Edge Functions)
- Une fonction par fichier, avec un point d’entrée clair (ex. `index.ts`).
- Valider les entrées :
  - présence du `prompt`,
  - durée dans les limites autorisées,
  - taille et type MIME des fichiers référencés.
- Ne jamais logguer les clés ou secrets, seulement les informations utiles au debug (ids de job, statuts, etc.).

---

## 5. Sécurité & confidentialité

- **Jamais** de clé OpenRouter ou autre secret dans le code Flutter Web.
- Utiliser uniquement les **variables d’environnement** côté Supabase (Edge Functions) pour les clés secrètes.
- Limiter la taille des uploads et vérifier le type de fichier (image, vidéo, audio) avant traitement.
- Nettoyer les données sensibles des logs (ne pas stocker de prompts trop sensibles si ce n’est pas nécessaire).

---

## 6. Bonnes pratiques UX inspirées de Canva / Runway / Pika

- Proposer des **exemples de prompts** prêts à l’emploi.
- Afficher un **loader clair** avec un message explicatif pendant la génération.
- Pour les vidéos longues, prévenir l’utilisateur que l’attente peut être de plusieurs dizaines de secondes.
- Donner la possibilité de **re-générer** ou de faire une **variante** à partir d’un résultat existant.
- Centraliser les actions de téléchargement via un helper dédié (ex. `FileDownloadHelper`).

---

## 7. Application de ces règles

- Toute nouvelle tâche Nexiom doit respecter ce document.
- Si une règle doit être ajustée, la modifier dans ce fichier `.windsurf/WORKFLOW.md` avant de changer la manière de travailler.
- Lors de la prise en charge d’une tâche, vérifier rapidement que le processus suivi est compatible avec ces règles (compréhension → TODOs → analyse → design → implémentation → validation → récapitulatif).

---

## 8. Sélection automatique des agents IA (orchestration)

Avant de commencer l’exécution d’une tâche, Windsurf doit **obligatoirement choisir automatiquement les agents IA les plus adaptés** (par exemple GPT‑5, Gemini, SWE, ou autres agents spécialisés) en fonction de la nature et de la complexité de la tâche, afin d’éviter les tâtonnements avec des agents qui ne sont pas adaptés.

### 8.1. Analyse de la tâche
- Analyser la demande utilisateur pour déterminer :
  - le **type de tâche** :
    - architecture globale / design système,
    - backend Supabase / SQL / sécurité,
    - front Flutter / UI / UX,
    - performance / optimisation,
    - refactor / bugfix complexe multi‑fichiers,
    - data / logs / observabilité.
  - le **niveau de complexité** :
    - *simple* : modification localisée, peu de dépendances,
    - *moyenne* : plusieurs fichiers liés, impact fonctionnel modéré,
    - *élevée* : touches à l’architecture, aux permissions, ou à plusieurs couches (Flutter + Supabase + OpenRouter).

### 8.2. Règles générales de sélection d’agents
- **Tâches d’architecture & design système (complexité moyenne/élevée)**
  - privilégier des agents forts en **raisonnement global** (ex. GPT‑5 ou équivalent),
  - les utiliser pour définir la structure, les schémas et les flux inter‑services.

- **Tâches de codage intensif / bugfix multi‑fichiers / refactor**
  - privilégier des agents de type **SWE / code-specialist** pour :
    - la lecture en profondeur du code,
    - la gestion des dépendances entre fichiers,
    - la correction d’erreurs complexes.

- **Tâches orientées UI/UX, prompts, multimodal (images/vidéos)**
  - privilégier des agents capables de gérer **multimodalité** et design (par ex. Gemini ou équivalent),
  - les utiliser pour proposer des prompts, des flux UX et des interactions cohérentes.

- **Tâches liées à la base de données / Supabase / sécurité**
  - privilégier des agents à l’aise avec **SQL, Postgres, RLS, IAM**, et la configuration d’APIs (Edge Functions),
  - s’assurer qu’ils respectent strictement les règles de sécurité définies dans ce document.

### 8.3. Combinaison d’agents (tâches complexes)
- Pour les tâches **multi‑couches** (par ex. nouvelle fonctionnalité impliquant Flutter + Supabase + OpenRouter) :
  - autoriser la **collaboration séquentielle** de plusieurs agents :
    - un agent orienté architecture (ex. GPT‑5) pour le design haut niveau,
    - un agent SWE pour l’implémentation détaillée et la gestion du code,
    - un agent multimodal (ex. Gemini) pour les aspects UX/prompting si nécessaire.
- Windsurf doit agir comme **coordinateur** :
  - consolider les propositions des différents agents,
  - garantir la cohérence avec les règles Flutter + Supabase + sécurité de ce document.

### 8.4. Fallback et responsabilité
- En cas d’indécision ou de conflit entre recommandations d’agents :
  - privilégier l’agent le plus adapté au **contexte technique dominant** (ex. SWE pour un refactor, agent DB pour une migration SQL),
  - toujours se conformer aux règles `.windsurf/WORKFLOW.md` (audit, sécurité, architecture) même si un agent propose un chemin plus rapide mais risqué.
- L’agent principal doit **rendre compte** à l’utilisateur des choix effectués :
  - quels types d’agents ont été mobilisés,
  - quelles décisions majeures ont été prises (architecture, schéma Supabase, flux Flutter),
  - comment cela améliore la qualité et la robustesse du code.

---

## 9. Exécution SQL Supabase via RPC administrateur (pas de CLI DB)

- Les agents Windsurf **ne doivent pas utiliser** les commandes de base de données de la Supabase CLI (`supabase db ...`) ni PowerShell pour appliquer des migrations ou exécuter du SQL sur le projet Nexiom.
- Toute exécution de SQL par Windsurf sur la base Supabase de Nexiom doit passer par **un canal unique et contrôlé** :
  - une **fonction Postgres RPC d’admin** (par ex. `public.admin_execute_sql`), appelée via REST (`/rest/v1/rpc/...`) ou via un driver, **en utilisant exclusivement la clé `service_role`**.
- Lorsqu’un nouveau besoin SQL apparaît (création de table, ajout de colonne, création de buckets Storage, etc.) :
  - Windsurf **génère** le SQL nécessaire (création/maj de la fonction RPC et/ou DDL),
  - l’utilisateur l’**exécute manuellement** une fois dans le SQL Editor du dashboard Supabase pour installer / mettre à jour la fonction RPC d’admin si elle n’existe pas encore,
  - ensuite, pour toutes les autres opérations, Windsurf utilise **uniquement** cette fonction RPC d’admin (via REST/RPC ou via des scripts Python appelant cette RPC) pour exécuter les requêtes SQL préparées ; le rôle de l’utilisateur se limite alors à **cliquer sur Run / exécuter le script** dans un environnement contrôlé, sans réécrire le SQL à la main.

### 9.1. Exemple de fonction RPC d’admin SQL (DEV uniquement)

> ATTENTION : cet exemple est puissant et doit rester **strictement limité** au contexte développement. Ne jamais l’exposer aux rôles `anon` / `authenticated`.

```sql
--- Fonction générique d’exécution SQL pour usage via service_role uniquement
create or replace function public.admin_execute_sql(sql text)
returns void
language plpgsql
security definer
set search_path = public as
$$
begin
  execute sql;
end;
$$;

--- Droits d’accès : aucun droit pour anon/authenticated
revoke all on function public.admin_execute_sql(text) from public;
revoke all on function public.admin_execute_sql(text) from anon;
revoke all on function public.admin_execute_sql(text) from authenticated;
-- Appels autorisés uniquement via service_role (Edge Function, appel REST direct `/rest/v1/rpc/admin_execute_sql`, etc.).

- Si cette fonction est mise en place par l’utilisateur :
  - Windsurf peut proposer des appels de type `rpc('admin_execute_sql', { sql: '...' })` ou des requêtes REST directes vers `/rest/v1/rpc/admin_execute_sql`,
  - en respectant toujours les règles de sécurité et en limitant les requêtes à des **migrations maîtrisées** (pas de SQL arbitraire dangereux),
  - **sans jamais utiliser** les commandes `supabase db ...` pour appliquer des changements de schéma.

### 9.2. Client standard et règle d’usage unique pour Supabase

- Pour **toute intervention sur Supabase** (audit de schéma, création/modification de tables, colonnes, index, RLS, buckets Storage, etc.), Windsurf doit **toujours** utiliser `public.admin_execute_sql` comme **canal unique** :
  - soit en appelant directement l’endpoint `/rest/v1/rpc/admin_execute_sql` depuis une Edge Function ou un script externe,
  - soit via un **client standard** (par exemple un script Python généré par Windsurf) qui encapsule cet appel.
- Aucun autre canal (autres RPC génériques d’exécution de SQL, CLI Supabase, accès direct Postgres) ne doit être utilisé pour modifier le schéma ou l’infrastructure de la base dans le contexte Nexiom ; cela évite les tâtonnements et les divergences entre environnements.
