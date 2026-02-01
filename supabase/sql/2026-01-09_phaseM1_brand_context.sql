-- Phase M1 – Contexte de marque Nexium Group / courtage académique
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-09_phaseM1_brand_context.sql

-- 1) Table de contexte de marque pour le cerveau marketing
create table if not exists public.studio_brand_context (
  id uuid primary key default gen_random_uuid(),
  brand_key text not null,
  locale text not null default 'fr',
  content jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (brand_key, locale)
);

-- 2) Trigger de mise à jour automatique du champ updated_at
-- La fonction set_updated_at() est déjà définie dans create_marketing_tables.sql

drop trigger if exists set_studio_brand_context_updated_at on public.studio_brand_context;
create trigger set_studio_brand_context_updated_at
  before update on public.studio_brand_context
  for each row
  execute function public.set_updated_at();

-- 3) Contexte structuré pour Nexium Group (courtier académique / plateforme Academia)
insert into public.studio_brand_context (brand_key, locale, content)
values (
  'nexium_group',
  'fr',
  jsonb_build_object(
    'presentation', $$Nexiom Group est une entreprise de droit burkinabè spécialisée dans la formation permanente, le courtage académique et l'accompagnement des élèves, étudiants et professionnels dans leur parcours de formation et de développement des compétences. Nexiom Group se présente comme l'une des premières entreprises de courtage académique structurées au Burkina Faso. Son rôle n'est pas d'octroyer des bourses d'études, mais d'agir comme facilitateur et négociateur entre les apprenants et les universités ou centres de formation partenaires.$$,
    'courtage_academique', $$Le courtage académique, tel que pratiqué par Nexiom Group, repose sur un mécanisme de réductions négociées et de facilités de paiement. Nexiom Group négocie avec des universités, centres de formation et structures habilitées afin d'obtenir pour ses clients des réductions sur les frais de formation, des échéanciers de paiement adaptés et des conditions d'inscription plus accessibles. Il ne s'agit pas de bourses d'études financées par un tiers, mais bien de réductions commerciales et de conditions particulières obtenues grâce au rôle de courtier de Nexiom Group.$$,
    'formations', $$Nexiom Group propose des formations internes ("formations maison") sanctionnées par des attestations, et assure le courtage de formations certifiantes et diplômantes pour le compte d'universités, de centres de formation professionnelle et de structures étatiques habilitées. Les domaines couverts incluent notamment les cours d'appui (lycée, université – premier cycle), la préparation aux concours académiques et professionnels, la préparation aux examens nationaux, les formations professionnelles pratiques, l'agriculture et l'élevage, les formations de courte durée ne nécessitant pas de diplôme préalable, ainsi que des formations continues et des formations initiales.$$,
    'plateforme_academia', $$Nexium Group a développé la plateforme numérique Academia, qui centralise le catalogue des formations, les inscriptions, les calendriers et horaires, les modalités de paiement et les informations détaillées sur les programmes proposés, qu'ils soient internes ou issus du courtage. Academia agit comme une vitrine intelligente reliant les offreurs de formation (universités, centres, organismes) et les demandeurs de formation (élèves, étudiants, professionnels, parents).$$,
    'vision_positionnement', $$Nexium Group se positionne comme un démarcheur académique structuré, un catalyseur de formations et une plateforme d'intelligence et de mise en relation dans le domaine de la formation. L'entreprise se veut un acteur légal et pionnier du courtage académique au Burkina Faso, avec pour vision de rendre la formation plus accessible aux Burkinabè et, plus largement, aux Africains, en regroupant les offres, en informant les publics et en facilitant l'accès aux formations adaptées à chaque profil.$$,
    'public_cible', $$Le public cible principal de Nexium Group comprend les élèves du secondaire, les étudiants du premier cycle universitaire, les jeunes diplômés, les professionnels en reconversion ou en recherche de montée en compétences, les parents d'élèves et d'étudiants, ainsi que les centres de formation et universités partenaires qui souhaitent toucher ces publics de manière structurée.$$,
    'mission_1_titre', $$Mission n°1 : Notoriété et Communauté$$,
    'mission_1_description', $$La mission marketing prioritaire consiste à accroître la visibilité de Nexium Group et de la plateforme Academia, à constituer une base d'abonnés qualifiés sur les réseaux sociaux (notamment Facebook), à créer une communauté engagée autour de la formation et du courtage académique, et à préparer le terrain pour les conversions futures (inscriptions, partenariats, demandes d'information). La logique est : visibilité → abonnés → communauté → confiance → conversions.$$
  )
)
on conflict (brand_key, locale)
do update set content = excluded.content, updated_at = now();
