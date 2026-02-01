-- Nettoyage des données de test du pipeline marketing E2E

-- Supprimer les recommandations de test
delete from public.studio_marketing_recommendations
where recommendation_summary = 'Test reco pipeline E2E';

-- Supprimer les posts préparés liés au message de test
delete from public.studio_facebook_prepared_posts
where final_message = 'Message test pipeline';

-- Supprimer les posts sociaux potentiellement créés avec ce message
delete from public.social_posts
where content_text = 'Message test pipeline';

-- Supprimer les posts Facebook simulés éventuellement liés à ce message
delete from public.facebook_posts
where message = 'Message test pipeline';

-- Supprimer d'éventuels outcomes stratégiques liés explicitement à ce test
delete from public.post_strategy_outcomes
where context_notes like '%pipeline E2E%';
