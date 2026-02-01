-- Phase 4 – Thématisation & segmentation (marchés africains)
-- A exécuter avec : python tools/admin_sql.py supabase/sql/2026-01-07_phase74_marketing_segments.sql

-- 1) Ajouter des colonnes de segmentation sur studio_marketing_recommendations (si non présentes)
alter table if exists public.studio_marketing_recommendations
  add column if not exists market text,
  add column if not exists locale text,
  add column if not exists audience_segment text;

-- 2) Initialiser les valeurs manquantes avec des défauts raisonnables pour Nexiom/Academia
update public.studio_marketing_recommendations
set
  locale = coalesce(locale, 'fr'),
  market = coalesce(market, 'bf_ouagadougou'),
  audience_segment = coalesce(audience_segment, 'students')
where locale is null
   or market is null
   or audience_segment is null;

-- 3) Index simples pour filtrer par marché / locale
create index if not exists studio_marketing_recommendations_market_idx
  on public.studio_marketing_recommendations(market);

create index if not exists studio_marketing_recommendations_locale_idx
  on public.studio_marketing_recommendations(locale);
