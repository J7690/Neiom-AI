-- Seed v1.0 – Learning Insights globaux (règle d'or + anti-patterns)
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-31_seed_learning_insights_engagement_rules.sql
-- Non destructif : insère des insights dans studio_learning_insights

insert into public.studio_learning_insights (
  insight_type,
  insight_title,
  insight_description,
  confidence_score,
  impact_score,
  data_source,
  time_period,
  actionable_recommendation,
  implemented
) values
  (
    'pattern',
    'Règle d''or : réaction humaine avant l''algorithme',
    'Les posts doivent être conçus d''abord pour provoquer une réaction humaine mesurable (dwell time, commentaires, partages) chez l''étudiant / le parent, pas pour « faire plaisir à Facebook ».',
    0.98,
    0.95,
    'governance_engagement_v1',
    'global',
    'Pour chaque recommandation, le comité doit vérifier : 1) le bénéfice concret pour l''étudiant ou le parent est-il clair ? 2) la première ligne donne-t-elle envie de lire la suite ? 3) la fin de post incite-t-elle vraiment à réagir ou à partager ?',
    false
  ),
  (
    'pattern',
    'Anti-patterns Facebook Nexiom à éviter',
    'Certains comportements de publication fatiguent l''audience et envoient un mauvais signal à l''algorithme : promo directe sans valeur, trop de liens sortants, hashtags excessifs, copier-coller non adapté, absence d''interaction après publication.',
    0.96,
    0.92,
    'governance_engagement_v1',
    'global',
    'Lors de la revue des posts et des missions, vérifier systématiquement que : 1) le contenu n''est pas une promo brute, 2) les liens sortants sont limités et pertinents, 3) les hashtags sont peu nombreux et contextuels, 4) le texte est adapté à Nexiom et à l''Afrique de l''Ouest, 5) l''équipe prévoit de répondre aux commentaires les plus importants.',
    false
  );
