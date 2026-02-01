# CAHIER DES CHARGES DÉFINITIF
Système d’assistants IA multicanal pour Academia & Nexiom  
Version : 1.0  
Auteur : Wendend  
Projet : Nexiom AI Assistants (modèle Limova adapté à Academia / Burkina Faso)

---

## 1. CONTEXTE & VISION

Le groupe **Nexiom** exploite notamment :
- **Academia** : plateforme éducative (formation, admissions).
- **Bobodo** : assistant pédagogique.
- **Nexiom AI Studio** : studio IA de création de contenus marketing (images, vidéos, voix, templates) déjà opérationnel (Flutter + Supabase + OpenRouter).

Aujourd’hui :
- Academia IA se concentre sur la **génération de médias** (images, micro-vidéos publicitaires, voix off).
- Il n’existe pas encore de **système unifié** pour :
  - répondre automatiquement aux messages sur **WhatsApp, Facebook, Instagram, TikTok, YouTube** ;
  - analyser les performances des campagnes ;
  - recommander des **stratégies marketing** adaptées.

**Contexte local** :
- Projet situé au **Burkina Faso**, avec une audience principalement active sur :
  - **Facebook**,
  - **TikTok**,
  - **WhatsApp**,
  - puis Instagram / YouTube.
- Objectif : se différencier fortement de la concurrence (écoles/universités utilisant déjà un marketing digital classique).

**Vision** : créer une **équipe d’assistants IA spécialisés**, à la manière de Limova, qui :
- **tiennent réellement les pages et les conversations** (pas de messages pré-enregistrés),
- génèrent et publient les contenus marketing,
- conseillent l’équipe sur les **campagnes les plus efficaces**,
- pilotent les conversions vers **inscriptions Academia**.

---

## 2. OBJECTIFS DU PROJET

### 2.1 Objectif principal

Mettre en place un **écosystème d’assistants IA multicanal** pour Nexiom / Academia capable de :

- gérer les **conversations en temps réel** sur WhatsApp, Facebook, Instagram, TikTok, YouTube (commentaires, messages privés),
- **tenir les pages** comme un community manager humain,
- créer et publier des contenus marketing via **Nexiom AI Studio**,
- analyser les performances et **recommander des actions**,
- augmenter significativement les **inscriptions à Academia**.

### 2.2 Objectifs secondaires

- **Réduire la charge opérationnelle** (réponses, modération, publication).
- **Standardiser la qualité** des interactions (ton, information correcte).
- **Adapter** la communication au contexte Burkina / Afrique (langage, horaires, réseaux prioritaires).
- Permettre à Nexiom de **se différencier fortement** de la concurrence locale.

---

## 3. PÉRIMÈTRE FONCTIONNEL
  (-)
### 3.1 Agents IA (concept "équipe d’assistants")

Le système repose sur plusieurs **agents IA spécialisés**, inspirés de Limova :

- **Agent 1 – IA Marketing Réseaux Sociaux (type "John")**
  - Crée des posts (texte + image/vidéo) via Nexiom AI Studio.
  - Programme et publie sur **Facebook, TikTok, Instagram, YouTube**.
  - Propose un **calendrier éditorial** adapté à Academia.

- **Agent 2 – IA Support & Admissions (type "Mickael")**
  - Répond aux **messages** et **commentaires** sur :
    - WhatsApp Business,
    - Facebook (page, Messenger),
    - Instagram (DM, commentaires),
    - TikTok (commentaires),
    - YouTube (commentaires).
  - Réponses **non pré-enregistrées**, générées par IA :
    - ton humain,
    - personnalisées,
    - basées sur la **connaissance Academia** (programmes, tarifs, admissions).
  - Collecte les données prospects et les envoie au **CRM Academia**.

- **Agent 3 – Secrétariat Vocal IA (type "Tom")**
  - Gère les appels entrants :
    - comprend la demande,
    - donne les informations nécessaires,
    - oriente (admissions, info programme, horaires),
    - prend des rendez-vous.
  - Résume chaque appel (texte) et le log dans le dashboard.

- **Agent 4 – Conseiller Marketing IA (Advisor)**
  - Analyse les **campagnes** et performances sur :
    - Facebook, TikTok, Instagram, YouTube, WhatsApp.
  - Produit des **rapports** et des **recommandations** :
    - quoi publier,
    - à quel moment,
    - sur quel réseau,
    - avec quel angle pour maximiser **inscriptions** et notoriété.

### 3.2 Canaux couverts

- **WhatsApp Business**
  - Interface principale de contact (Burkina).
  - Chatbot IA pour prospects / étudiants.
  - Interface interne pour l’équipe Nexiom (pilotage par messages WhatsApp).

- **Facebook**
  - Gestion des **pages** Université / Academia.
  - Gestion des **posts, commentaires, messages**.

- **Instagram**
  - Gestion des posts / stories / commentaires / DM.
  - Programmation de contenus.

- **TikTok**
  - Gestion des **commentaires**,
  - Proposition et création de scripts vidéo,
  - Analyse des performances de vidéos.

- **YouTube**
  - Gestion / analyse des **commentaires**,
  - Génération de scripts / descriptions / titres optimisés.

---

## 4. FONCTIONNALITÉS DÉTAILLÉES

### 4.1 Conversations IA (pas de messages pré-enregistrés)

- Les réponses ne sont **pas** de simples messages pré-définis.
- Exigences :
  - Utilisation de **modèles IA conversationnels** (LLM) pour générer des réponses :
    - en français,
    - ton humain, chaleureux, professionnel,
    - adaptées au contexte (historique de la conversation, canal, profil).
  - Accès à une **base de connaissances Academia** (programmes, tarifs, admissions, calendrier, FAQ).
  - Capacité à :
    - reformuler,
    - poser des questions de clarification,
    - proposer l’offre la plus pertinente (formation, pack, promo).

- **Escalade vers humain** :
  - Si la demande est sensible / trop complexe :
    - l’agent IA transfère à un agent humain (tag + notification).
    - l’humain peut reprendre la conversation dans le dashboard.

### 4.2 Gestion des commentaires & messages par réseau

- **Facebook / Instagram / TikTok / YouTube** :
  - Lecture en continu des commentaires et messages via APIs.
  - Classification :
    - question d’info,
    - demande d’admission,
    - plainte / insatisfaction,
    - spam.
  - Réponse IA adaptée, avec objectifs :
    - informer correctement,
    - rediriger vers WhatsApp ou site pour conversion,
    - calmer les tensions en cas d’avis négatif,
    - rediriger au support humain si nécessaire.

- **WhatsApp Business** :
  - Réception et traitement des messages entrants (24/7).
  - Dialogues IA complets pour :
    - expliquer les programmes,
    - aider à choisir une formation,
    - donner les tarifs, modalités de paiement,
    - envoyer des liens (formulaire, site).
  - Création automatique de **fiches lead** (nom, contact, intérêt, canal).

### 4.3 Création & planification de contenus (Nexiom AI Studio)

- Réutilisation de **Nexiom AI Studio** comme moteur créatif :
  - Génération de **micro-vidéos publicitaires** (VGL).
  - Génération de **visuels** pour réseaux sociaux.
  - Génération de **voix off** & scripts.

- L’Agent Marketing :
  - peut être appelé via :
    - le **dashboard**,  
    - ou **WhatsApp interne** (commande texte).
  - propose un **calendrier éditorial** (semaine / mois) avec :
    - thème,
    - réseau cible,
    - type de contenu (image, vidéo, story, live),
    - objectif (notoriété, inscription, rappel deadline).

### 4.4 Conseiller Marketing IA (Analytics & recommandations)

- Collecte des métriques :
  - par post / vidéo / campagne :
    - vues, clics, likes, commentaires, partages,
    - taux d’engagement,
    - si connecté aux Ads : coût par résultat.
  - Liens avec les **inscriptions Academia** (si possible) :
    - pour mesurer quelles campagnes amènent de vraies conversions.

- Rapports IA :
  - **Rapport hebdomadaire** (texte simple + graphiques sur le dashboard) :
    - top contenus,
    - réseaux les plus efficaces,
    - heures / jours performants.
  - **Synthèses IA** envoyées par e-mail / WhatsApp interne.

- Recommandations actionnables :
  - Suggestions de contenus :
    - "3 vidéos TikTok à produire cette semaine sur le thème X."
  - Suggestions de boost / budget :
    - "Cette publication Facebook performe bien, à booster."
  - Conseils pour améliorer les **messages IA** ou les **pages**.

---

## 5. ARCHITECTURE TECHNIQUE CIBLE

### 5.1 Socle existant réutilisé

- **Frontend Studio** : Flutter (`nexiom_ai_studio`).
- **Backend IA de génération** :
  - **Supabase** (Postgres + Storage + Auth).
  - **Supabase Edge Functions** (TypeScript/Deno) :
    - `generate-video`, `generate-image`, `generate-audio`.
  - **OpenRouter** comme passerelle vers modèles IA (OpenAI, etc.).

### 5.2 Noyau d’orchestration multicanal

- **Backend orchestrateur** (proposé) :
  - Étendre les **Edge Functions Supabase** existantes ou ajouter un backend complémentaires pour :
    - gérer les webhooks Meta (WhatsApp, Facebook, Instagram).
    - gérer TikTok, YouTube.
    - router les événements vers les bons agents IA.

- **Composants clés** :
  - Service "Connecteurs Canaux" (WhatsApp, FB, IG, TikTok, YouTube).
  - Service "Orchestrateur Conversationnel" (routage, intents, contexte).
  - Service "Analytics & Reporting".
  - Base de données unifiée (Supabase) pour :
    - conversations,
    - leads,
    - campagnes,
    - performances.

### 5.3 IA & Base de connaissances

- **Modèles IA** :
  - Modèles de chat (OpenAI / Claude / Llama 3 via OpenRouter).
  - Prompting adapté au contexte Academia.

- **Base de connaissances** :
  - Données Academia :
    - programmes, fiches de cours,
    - tarifs, bourses, promotions,
    - calendrier académique,
    - FAQ.
  - Mécanisme type **RAG** (Recherche + génération) recommandé.

---

## 6. EXIGENCES NON FONCTIONNELLES

- **Sécurité & conformité**
  - Respect des règles Meta / TikTok / YouTube.
  - Protection des données étudiants / prospects.
  - Chiffrement des conversations sensibles.

- **Performance**
  - Temps de réponse moyen cible :
    - < 3 secondes sur WhatsApp / Messenger / Instagram DM.
  - Temps de génération de contenus dépendant des modèles, mais :
    - feedback d’état (en cours / prêt).

- **Disponibilité**
  - Objectif : 99 % sur les heures ouvrées.
  - Dégradé : en cas de panne IA, fournir des messages de fallback ou basculer vers humain.

- **Scalabilité**
  - Capable de gérer au départ :
    - **5 000+ conversations / mois**, 
    - 100–200 posts / mois.
  - Architecture extensible (ajout de nouveaux agents IA / canaux).

---

## 7. ROADMAP PROPOSÉE

- **Phase 0 – Consolidation Nexiom AI Studio (1–2 semaines)**
  - Stabiliser génération vidéo / image / audio.
  - Documenter les APIs internes.

- **Phase 1 – Fondations multicanal (2–4 semaines)**
  - Mise en place des webhooks & connecteurs :
    - WhatsApp Business,
    - Facebook + Instagram,
    - TikTok,
    - YouTube (min. commentaires).
  - Stockage conversations & messages.

- **Phase 2 – Agent Support & Admissions (2–3 semaines)**
  - IA conversationnelle sur WhatsApp + Facebook + Instagram.
  - Escalade vers humain.
  - Création de leads dans CRM Academia.

- **Phase 3 – Agent Marketing Réseaux Sociaux (2–3 semaines)**
  - Génération et planification de posts via Nexiom AI Studio.
  - Publication sur Facebook / Instagram / TikTok / YouTube.

- **Phase 4 – Conseiller Marketing IA (2–4 semaines)**
  - Collecte des métriques.
  - Rapports IA + recommandations.
  - Intégration avec WhatsApp interne (demande de rapport par message).

- **Phase 5 – Secrétariat Vocal IA (3–5 semaines)**
  - Intégration voix (Twilio / Vonage / ElevenLabs).
  - Appels entrants + résumés.

- **Phase 6 – Dashboard & Analytics avancés (2–4 semaines)**
  - Interface unifiée :
    - conversations,
    - leads,
    - campagnes,
    - rapports.

- **Phase 7 – Intégration finale dans Academia (2–3 semaines)**
  - Séparation claire :
    - **Bobodo académique** (pédagogie),
    - **Nexiom AI Assistant** (marketing, admissions, support).
  - Tests finaux, déploiement.

---

## 8. LIVRABLES ATTENDUS

- **Backend multicanal opérationnel** (WhatsApp, Facebook, Instagram, TikTok, YouTube).
- **Agents IA** :
  - Support & Admissions,
  - Marketing Réseaux Sociaux,
  - Conseiller Marketing IA,
  - Secrétariat vocal.
- **Dashboard Web** pour :
  - suivi des conversations,
  - gestion des leads,
  - pilotage des campagnes,
  - rapports & recommandations IA.
- **Documentation technique & fonctionnelle**.
- **Manuel utilisateur** (équipe marketing / admissions).
- **Scripts & procédures** d’intégration (APIs, tokens Meta, etc.).

---

## 9. NEXIOM AI STUDIO – RÉFÉRENCE VISAGE & ENVIRONNEMENT (IMG2IMG AVANCÉ)

### 9.1 Objectif fonctionnel (non négociable)

Lorsque l’utilisateur fournit **une ou plusieurs images de référence**, Nexiom AI Studio doit être capable de :

- **Reproduire un visage avec une forte ressemblance**, quasi indiscernable pour un utilisateur novice.
- **Reproduire fidèlement un environnement / décor** (bureau, salle de réunion, cadre institutionnel) fourni en référence.
- Ne modifier que ce qui est explicitement demandé (posture, accessoires, visiteurs, texte, branding…).

Il ne s’agit pas d’une simple "inspiration", mais d’un **mode img2img contrôlé**, image par image, avec **forte fidélité visuelle** (visage + décor).

### 9.2 Exigences back-end (Supabase + OpenRouter)

- Le back-end doit implémenter un **vrai flux img2img** dans la fonction Edge `generate-image` :
  - Télécharger les images de référence depuis Supabase Storage (bucket `inputs`).
  - Encoder ces images en **base64** (`data:image/...;base64,...`).
  - Les envoyer au modèle OpenRouter comme **inputs réels** (`input_image`), et non comme simples URLs texte.

- Les entrées JSON supportées par `generate-image` incluent :
  - `faceReferencePaths: string[]` – chemins vers 0..N images de visage.
  - `environmentReferencePaths: string[]` – chemins vers 0..N images d’environnement / décor.
  - `faceStrength: number (0..1)` – niveau de fidélité du visage.
  - `environmentStrength: number (0..1)` – niveau de fidélité de l’environnement.

- Les jobs sont tracés dans `generation_jobs` et `image_assets` sans nouvelle migration :
  - `generation_jobs.job_mode = 'face_ref'` pour ces générations.
  - `generation_jobs.provider_metadata` contient au minimum :
    - `face_reference_paths`, `environment_reference_paths`,
    - `face_strength`, `environment_strength`,
    - `img2img: true`, `model_used`.
  - `image_assets.variant_type = 'img2img'` pour ces rendus.
  - `image_assets.metadata` contient les mêmes informations (références + strengths).

- Le prompt envoyé au modèle doit inclure des **règles dures** du type :

> *Preserve the exact identity of the person in the face reference image(s).*
> *Do not change facial features, skin tone, or facial proportions.*
> *Preserve as much as possible the global layout, camera angle and lighting style of the environment reference image(s).*
> *Only modify elements that are explicitly requested in the prompt (pose, accessories, visitors, text, etc.).*

- Le choix des modèles OpenRouter doit privilégier ceux qui :
  - supportent `input_image` + paramètres de **strength / denoise**,
  - gèrent correctement plusieurs images de référence,
  - respectent les contraintes légales et les TOS (pas de deepfake hors cadre autorisé).

### 9.3 Exigences UI (Flutter – page Génération d’image)

Sur l’écran de génération d’image Nexiom AI Studio, l’utilisateur doit disposer :

- De zones distinctes pour :
  - **Images de référence – visage** (1 à n portraits).
  - **Images de référence – environnement / décor** (1 à n images de bureau, lieux réels…).

- De deux sliders clairs :
  - **"Fidélité du visage"** → mappé à `faceStrength (0..1)`.
  - **"Fidélité de l’environnement"** → mappé à `environmentStrength (0..1)`.

- Comportement attendu :
  - Si au moins une image de référence (visage ou décor) est fournie → activer automatiquement un mode img2img / `face_ref` (utilisation réelle des images côté modèle).
  - Si aucune image de référence n’est fournie → comportement de génération classique (text2img / autres modes) inchangé.

Les nouveaux champs sont **optionnels** et ne doivent pas casser les usages existants.

### 9.4 Paramétrage recommandé

Pour les cas d’usage institutionnels Nexiom (dirigeants, conseillers, bureaux réels) :

- **Preset recommandé "Identité forte Nexiom"** :
  - `faceStrength ≈ 0.25–0.35`  (forte fidélité visage).
  - `environmentStrength ≈ 0.30–0.40`  (forte fidélité décor).

Ces valeurs peuvent être ajustées après calibration, mais doivent être documentées comme valeurs de référence.

### 9.5 Critères de succès & QA

Pour valider la fonctionnalité :

- Sur un jeu de test interne (au moins 10 portraits + 10 environnements réels) :
  - **≥ 80 %** des images générées sont jugées comme représentant "la même personne" que le portrait de référence par au moins 3 testeurs internes.
  - **≥ 80 %** des environnements générés sont jugés "très proches" du décor réel (bureau, cadrage, lumière) utilisé en référence.

- Aucun cas ne doit présenter :
  - de fortes déformations du visage (yeux, bouche, peau),
  - un changement complet de décor non demandé (bureau → plage, etc.).

- Une campagne de QA doit couvrir :
  - Visage seul (référence visage uniquement).
  - Décor seul (référence environnement uniquement).
  - Visage + décor combinés (cas Nexiom conseillé).
  - Variations de strengths pour évaluer la stabilité.

Les limitations connues (ex. capacité réelle du modèle, angles extrêmes, éclairage difficile) doivent être documentées dans la documentation technique.
