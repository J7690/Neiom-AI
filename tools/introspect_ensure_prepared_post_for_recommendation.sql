SELECT pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname = 'ensure_prepared_post_for_recommendation';
