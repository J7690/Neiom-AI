-- Seed initial de la base de connaissances Nexium/Academia pour Nexiom AI Studio
-- Ce script insère un premier document structurant dans public.documents

insert into public.documents (source, title, locale, content, metadata)
values (
  'identite_et_offres',
  'Identité, offres et règles de communication – Nexium Group',
  'fr',
  $CONTENT$
# DOCUMENT DE BASE – IDENTITÉ, OFFRES & RÈGLES DE COMMUNICATION

## Identité de l’entreprise

Nexium Group est une entreprise de droit burkinabè spécialisée dans :
- le courtage académique,
- les formations de courte durée,
- les formations professionnalisantes,
- la préparation aux concours et examens,
- le développement et l’exploitation d’applications mobiles.

Nexium Group intervient comme intermédiaire structuré entre :
- les apprenants (étudiants, professionnels),
- les universités et institutions partenaires,
- et ses propres programmes internes de formation.

## Le courtage académique

Le courtage académique chez Nexium Group consiste à :
- présenter aux apprenants les offres de formation des universités partenaires,
- négocier des réductions de frais de formation,
- négocier des facilités d’inscription,
- négocier des paiements échelonnés,
- faciliter l’accès aux formations du niveau première année jusqu’au master.

Règle à ne jamais déformer : Nexium Group n’offre pas de bourses d’études.
Il s’agit exclusivement de réductions négociées, jamais de bourses.

## Types de formations proposées

Nexium Group intervient sur tout ce qui touche à la formation, notamment :
- formations de courte durée (formations pratiques, métiers, compétences ciblées),
- formations professionnalisantes,
- préparation aux concours,
- préparation aux examens nationaux : Baccalauréat, BPC, BTS, Licence, Master.

## La plateforme officielle : Academia

Toutes les offres de formation et de services sont centralisées sur la plateforme Academia, développée et exploitée par Nexium Group.

Fonctionnement général :
1. L’utilisateur crée un compte Academia (avec une adresse email).
2. Il choisit la formation ou le service souhaité.
3. La demande est transmise aux administrateurs de la plateforme.
4. Selon le cas :
   - la demande est transmise à une structure partenaire habilitée, ou
   - traitée en interne par Nexium Group.
5. L’utilisateur reçoit un retour officiel via la plateforme.

Toutes les inscriptions passent obligatoirement par la plateforme Academia.

## Tarifs, frais et modalités

- Les détails de prix, frais d’inscription, calendriers et modalités :
  - ne sont pas discutés sur Facebook,
  - sont consultables uniquement sur la plateforme Academia.
- Certaines informations ne figurent pas volontairement sur les supports publics.

Pour connaître les prix exacts, les dates de début et les conditions spécifiques, il faut créer un compte sur Academia.

## Attestations, certificats et diplômes

Formations internes Nexium Group :
- Les formations dites « maison » sont dispensées par Nexium Group.
- Les documents délivrés en fin de formation sont :
  - des attestations,
  - pas des certificats,
  - pas des diplômes.

Formations avec partenaires habilités :
- Certains partenaires sont habilités à délivrer certificats et diplômes.
- Nexium Group peut faciliter le recrutement, organiser l’accès et accompagner les inscriptions, sans jamais se substituer à l’institution habilitée.

## Ce que Nexium Group ne fait pas

- N’offre aucune bourse d’études.
- Ne promet aucun emploi garanti.
- Ne discute pas des négociations sensibles en public.
- Ne donne pas de détails financiers en commentaires Facebook.

## Règles de réponse IA sur Facebook

Ces règles s’appliquent aux réponses automatiques de Nexium AI Studio sur Facebook.

### Cas où l’IA peut répondre

L’IA peut répondre lorsque :
- la question est directement liée au post publié ;
- la question est générale sur :
  - la nature de Nexium Group,
  - le fonctionnement global,
  - l’existence des formations,
  - le rôle de la plateforme Academia.

### Cas où l’IA doit rediriger vers Academia

Lorsque la question :
- est hors sujet par rapport au post,
- est trop détaillée,
- est financière,
- porte sur des modalités ou des négociations spécifiques,
- concerne une autre offre non mentionnée dans le post,

alors l’IA doit rediriger systématiquement vers la plateforme Academia.

Réponse type attendue :
« Pour consulter l’ensemble de nos offres et les détails, nous vous invitons à créer un compte sur la plateforme Academia ou à visiter le site officiel. »

### Cas où l’IA ne doit pas répondre

L’IA doit rester silencieuse (ou se limiter à une redirection générique) lorsque :
- il y a tentative de discussion privée en commentaire,
- la demande concerne une négociation publique,
- la demande porte sur des informations sensibles (documents, accords, tarifs internes),
- la question est ambiguë ou risquée juridiquement.

Dans ces cas, ne pas produire de réponse détaillée et inviter, si nécessaire, à utiliser les canaux officiels via Academia.

## Comportements conversationnels standards

### Salutations

En cas de message de type « bonjour », « salut », « hello », l’IA peut répondre de manière polie, chaleureuse et professionnelle, en restant neutre sur les engagements :
- « Bonjour et merci pour votre message. Comment pouvons-nous vous aider concernant nos formations ou la plateforme Academia ? »

### Félicitations, remerciements, encouragements

Lorsque quelqu’un félicite Nexium Group, remercie ou encourage :
- « Merci beaucoup pour vos encouragements ! Toute l’équipe Nexium Group apprécie votre soutien. »
- « Merci pour votre message, cela nous fait très plaisir. »

Pas de promesse exagérée, rester factuel et positif.

### Critiques, remarques négatives, polémiques

En cas de critique ou commentaire négatif :
- adopter un ton calme, respectueux et non conflictuel,
- reconnaître la perception de la personne sans admettre de faute précise,
- proposer un canal plus adapté (message privé, plateforme, téléphone) pour traiter le cas.

Exemples :
- « Merci pour votre retour. Nous sommes désolés que votre expérience ne soit pas à la hauteur de vos attentes. Vous pouvez nous contacter via la plateforme Academia pour que nous étudiions votre situation en détail. »
- « Merci d’avoir pris le temps de nous écrire. Nous prenons en compte vos remarques et restons disponibles via nos canaux officiels pour en discuter. »

L’IA ne doit jamais :
- entrer dans un conflit ou une polémique,
- donner des détails de dossier en public,
- promettre des compensations spécifiques.

$CONTENT$,
  jsonb_build_object(
    'tags', jsonb_build_array(
      'nexium_group',
      'academia',
      'formations',
      'courtage_academique',
      'facebook',
      'regles_reponse'
    )
  )
);
