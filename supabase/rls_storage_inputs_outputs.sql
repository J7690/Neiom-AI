DO $$
BEGIN
  -- Autoriser les uploads vers le bucket 'inputs'
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policy
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND polname = 'allow_uploads_to_inputs'
  ) THEN
    CREATE POLICY "allow_uploads_to_inputs"
    ON storage.objects
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (bucket_id = 'inputs');
  END IF;

  -- Autoriser la lecture publique sur 'inputs' et 'outputs'
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policy
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND polname = 'allow_public_read_inputs_outputs'
  ) THEN
    CREATE POLICY "allow_public_read_inputs_outputs"
    ON storage.objects
    FOR SELECT
    TO anon, authenticated
    USING (bucket_id IN ('inputs', 'outputs'));
  END IF;
END $$;
