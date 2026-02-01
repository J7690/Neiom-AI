-- Phase M1 – Enrichissement du contexte de marque Nexiom Group / documentation longue
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-22_phaseM1_brand_context_enrich.sql

-- Ce script n'écrase pas le contenu existant de studio_brand_context.
-- Il ajoute des champs supplémentaires dans le JSON "content" pour la marque nexium_group.

update public.studio_brand_context
set content = content || jsonb_build_object(
  'presentation_longue_markdown', $$Parfait — je te propose une **présentation structurée, claire et professionnelle de Nexiom Group**, que tu peux utiliser **telle quelle** pour :

* un dossier de partenariat,
* une présentation institutionnelle,
* un site web,
* une plaquette PDF,
* ou comme base pour Academia.

---

# **Nexiom Group**

### *Accélérateur d’accès à l’éducation, aux compétences et aux opportunités*

---

## **1. Présentation générale**

**Nexiom Group** est un groupe innovant spécialisé dans l’accompagnement éducatif, académique et professionnel.
Il agit comme **intermédiaire stratégique** entre les apprenants, les établissements de formation, les universités, les partenaires institutionnels et le monde professionnel.

Le groupe est né d’un constat simple mais structurant :
👉 *l’accès à l’éducation de qualité, à l’orientation fiable et aux opportunités professionnelles reste complexe, coûteux et mal organisé pour une grande partie de la jeunesse africaine.*

Nexiom Group apporte une réponse **structurée, technologique et humaine** à ce défi.

---

## **2. Vision**

> **Devenir un acteur de référence en Afrique de l’Ouest dans l’accès intelligent à l’éducation, aux compétences et aux opportunités professionnelles.**

Nexiom Group vise à construire un **écosystème éducatif intégré**, où :

* les étudiants font des choix éclairés,
* les établissements recrutent efficacement,
* les partenaires gagnent en visibilité et en impact,
* les talents sont valorisés et orientés vers des débouchés réels.

---

## **3. Mission**

La mission de Nexiom Group est de :

* **Faciliter l’accès à l’éducation et à la formation**,
* **Optimiser l’orientation académique et professionnelle**, 
* **Négocier et sécuriser les parcours éducatifs**, 
* **Créer des passerelles concrètes entre formation et emploi**, 
* **Utiliser la technologie et l’intelligence artificielle comme leviers d’impact.**

> 🧭 *« Nous négocions l’accès, vous construisez l’avenir. »*

---

## **4. Objectifs stratégiques**

### 🎯 Objectifs principaux

1. **Réduire l’échec académique** lié à une mauvaise orientation
2. **Démocratiser l’accès** aux universités privées et formations qualifiantes
3. **Améliorer la visibilité des établissements partenaires**
4. **Structurer les parcours étudiants** du bac à l’insertion professionnelle
5. **Créer un modèle durable de courtage académique à la performance**

### 🎯 Objectifs à moyen et long terme

* Déployer les services Nexiom Group dans plusieurs pays d’Afrique
* Développer des outils d’orientation basés sur l’IA
* Construire une base de données métiers & formations adaptée au contexte africain
* Devenir un hub régional de talents, formations et opportunités

---

## **5. Activités principales de Nexiom Group**

### 🧑‍🎓 1. Courtage académique et orientation éducative

Nexiom Group accompagne :

* les nouveaux bacheliers,
* les étudiants en réorientation,
* les professionnels en reprise d’études.

**Services proposés :**

* Analyse du profil académique et financier
* Orientation personnalisée (local / international)
* Mise en relation avec des universités et écoles partenaires
* Négociation de facilités (réductions, paiements échelonnés, conditions spéciales)
* Suivi post-inscription

👉 **Rémunération basée sur la performance** (inscriptions effectives).

---

### 📚 2. Formations, renforcement de compétences & TD

* Travaux dirigés (TD) niveau secondaire et supérieur
* Préparations aux concours (administratifs, professionnels, académiques)
* Formations pratiques (informatique, outils numériques, soft skills)
* Programmes de mise à niveau académique

---

### 🏫 3. Partenariats avec universités & établissements

Nexiom Group agit comme :

* **canal de recrutement structuré**,
* **outil marketing éducatif**, 
* **interface de gestion des candidatures**.

**Avantages pour les partenaires :**

* Accès à des étudiants qualifiés
* Réduction des coûts de prospection
* Données, statistiques et suivi
* Image institutionnelle renforcée

---

### 💼 4. Insertion professionnelle & opportunités

* Stages et opportunités professionnelles
* Mise en relation avec entreprises partenaires
* Programmes de transition études → emploi
* Valorisation des compétences locales

---

### 🤖 5. Innovation, technologie & IA éducative

Nexiom Group développe des outils numériques, dont :

* **Academia** : plateforme centrale (mobile & web)
* Orientation intelligente
* Suivi étudiant
* Messagerie encadrée
* Gamification éducative
* IA d’aide à la décision et à la communication

---

## **6. Academia : la plateforme cœur**

**Academia** est la plateforme digitale de Nexiom Group.

Elle permet :

* aux étudiants : s’orienter, postuler, suivre leurs démarches
* aux universités : publier, recruter, gérer
* aux partenaires : collaborer, suivre l’impact
* au groupe : piloter l’écosystème

👉 Academia est **la passerelle technologique** vers toutes les offres de Nexiom Group.

---

## **7. Valeurs**

* **Accessibilité** : rendre possible ce qui semblait hors de portée
* **Transparence** : information claire, processus encadrés
* **Innovation utile** : technologie au service de l’humain
* **Impact social** : éducation comme moteur de développement
* **Responsabilité** : accompagnement réel, pas de promesses vides

---

## **8. Positionnement**

Nexiom Group n’est :

* ni une simple école,
* ni une simple agence,
* ni une simple plateforme.

👉 C’est un **orchestrateur éducatif**, à la croisée de :

* l’éducation,
* la technologie,
* l’orientation,
* le partenariat,
* et l’impact social.

---

## **9. Publics cibles**

* Étudiants & bacheliers
* Parents
* Universités & écoles privées
* Centres de formation
* Entreprises & institutions
* Partenaires techniques et financiers

---

## **10. Ambition finale**

Construire un **écosystème éducatif africain structuré**, crédible et durable,
où chaque jeune peut :

* comprendre ses options,
* accéder à des formations adaptées,
* construire un avenir professionnel solide.
$$,
  'precisions_courtage_sans_bourse', $$Nexiom Group n'offre pas de bourses d'études et ne se présente pas comme un organisme boursier. Son rôle est celui d'un **courtier académique** : il négocie des réductions, des facilités de paiement et des conditions particulières d'accès aux formations auprès des universités, écoles et centres partenaires. Les avantages obtenus pour les apprenants relèvent de conditions commerciales négociées, pas de bourses financées par Nexiom Group.$$
)
where brand_key = 'nexium_group'
  and locale = 'fr';
