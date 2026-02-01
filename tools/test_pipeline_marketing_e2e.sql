with
inserted_reco as (
  insert into studio_marketing_recommendations(objective, recommendation_summary, reasoning, proposed_format, proposed_message, status)
  values ('notoriety', 'Test reco pipeline E2E', 'Test reasoning', 'image', 'Message test pipeline', 'pending')
  returning id as reco_id
),
approved as (
  select (approve_marketing_recommendation(inserted_reco.reco_id::text, 'studio_admin')).* from inserted_reco
),
prepared as (
  select (ensure_prepared_post_for_recommendation(inserted_reco.reco_id::text)).* from inserted_reco
),
attached as (
  select (attach_media_to_prepared_post(approved.prepared_post_id::text, 'https://example.com/e2e.jpg', 'image')).* from approved
),
published as (
  select (publish_prepared_post(approved.prepared_post_id::text)).* from approved
)
select
  (select reco_id from inserted_reco) as reco_id,
  (select prepared_post_id from approved) as post_id,
  (select row_to_json(t) from approved t) as approve_result,
  (select row_to_json(t) from prepared t) as prepared_result,
  (select row_to_json(t) from attached t) as attach_result,
  (select row_to_json(t) from published t) as publish_result;


