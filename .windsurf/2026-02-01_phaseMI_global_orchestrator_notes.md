# Phase MI – Audit & Impl Orchestrateur Global

Ce fichier sert de trace pour l’audit Supabase et l’implémentation de l’orchestrateur global de publication, exécutés via `tools/admin_sql.py`.

## 1. Scripts SQL exécutés

1. **Audit (lecture seule)**  
   Fichier : `supabase/sql/2026-02-01_phaseMI_global_orchestrator_audit.sql`  
   Commande exécutée :

   ```bash
   python tools/admin_sql.py --file supabase/sql/2026-02-01_phaseMI_global_orchestrator_audit.sql
   ```

   Remarque : côté Supabase, ce script est exécuté via `admin_execute_sql`, qui ne renvoie pas directement les lignes des `SELECT`. Il sert à vérifier la présence et la cohérence des tables / indexes / RPC dans l’instance réelle.

2. **Implémentation orchestrateur & RPC mission-aware**  
   Fichier : `supabase/sql/2026-02-01_phaseMI_global_orchestrator_impl.sql`  
   Commande exécutée :

   ```bash
   python tools/admin_sql.py --file supabase/sql/2026-02-01_phaseMI_global_orchestrator_impl.sql
   ```

## 2. Nouveaux RPC côté Supabase

- `list_content_jobs_for_mission(p_mission_id uuid, p_status text, p_limit int) returns jsonb`  
  Liste les `content_jobs` liés à une mission donnée.

- `list_mission_calendar(p_mission_id uuid, p_start_date date, p_days int) returns jsonb`  
  Calque de `list_calendar`, mais filtré sur une mission (jointure `content_jobs` → `social_posts` → `social_schedules`).

- `get_mission_intelligence_summary(p_mission_id uuid) returns jsonb`  
  Retourne le dernier `report` de `studio_mission_intelligence_reports` pour une mission.  
  Droits : exécutable par `anon` et `authenticated`.

- `orchestrate_global_publishing(p_channel text, p_date date, p_max_posts_per_day int, p_timezone text) returns jsonb`  
  Orchestrateur global multi-missions : choisit et planifie des `content_jobs` pour une date / canal en respectant :
  - un cap global de posts / jour / canal,  
  - au plus un post par mission pour ce jour (en tenant compte de l’existant),  
  - la priorité de l’objectif (`high|medium|low`),  
  - la phase (`intro|nurture|closing`) et les dates de mission.

- Index ajoutés (non destructifs) :
  - `content_jobs_mission_id_idx`
  - `content_jobs_mission_phase_status_idx`
  - `studio_marketing_missions_status_channel_dates_idx`

## 3. Ajustement Facebook – propagation mission_id

Dans `supabase/sql/2026-01-09_phaseFB_schedule_facebook_publication.sql` :

- Le `insert into public.content_jobs` dans `schedule_facebook_publication` a été modifié pour inclure `mission_id` lorsque le `studio_facebook_prepared_posts` source a un `mission_id` non nul.

Cela permet de relier les `content_jobs` issus des posts préparés Facebook à leur mission marketing.

## 4. Intégration Flutter (service seulement)

Dans `lib/features/marketing/services/marketing_service.dart` :

- Ajout de méthodes :
  - `listContentJobsForMission(...)` → RPC `list_content_jobs_for_mission`
  - `listMissionCalendar(...)` → RPC `list_mission_calendar`
  - `getMissionIntelligenceSummary(...)` → RPC `get_mission_intelligence_summary`
  - `orchestrateGlobalPublishing(...)` → RPC `orchestrate_global_publishing`

- Les méthodes existantes :
  - `hasMissionIntelligenceReport(...)`
  - `getLatestMissionIntelligenceReport(...)`

  utilisent désormais le RPC public `get_mission_intelligence_summary` au lieu de `get_latest_mission_intelligence_report` (qui reste restreint côté SQL).

## 5. Prochaines intégrations possibles (UI)

- Ajouter dans `DevToolsPage` une section pour appeler `orchestrate_global_publishing` (canal + date + max/jour) afin de tester facilement l’orchestrateur global.
- Exposer, dans l’onglet Missions / Calendrier, des vues basées sur `list_content_jobs_for_mission` et `list_mission_calendar` (filtre par mission, résumé des jobs planifiés / publiés par mission).
