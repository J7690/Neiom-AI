-- Phase A0 – Correction du pipeline de publication marketing
-- Objectif : garantir qu'un clic sur "OK – PUBLIER" crée un post préparé réel
-- et déclenche publish_prepared_post sans erreur "Post non trouvé ou non approuvé".

-- 0) Nettoyage des anciennes surcharges éventuelles
DROP FUNCTION IF EXISTS public.approve_marketing_recommendation(uuid, text);
DROP FUNCTION IF EXISTS public.approve_marketing_recommendation(uuid);
DROP FUNCTION IF EXISTS public.approve_marketing_recommendation(text);

DROP FUNCTION IF EXISTS public.reject_marketing_recommendation(uuid, text);
DROP FUNCTION IF EXISTS public.reject_marketing_recommendation(uuid);
DROP FUNCTION IF EXISTS public.reject_marketing_recommendation(text);

DROP FUNCTION IF EXISTS public.publish_prepared_post(uuid);
DROP FUNCTION IF EXISTS public.publish_prepared_post(text);

-- 1) Fonction d'approbation d'une recommandation
CREATE OR REPLACE FUNCTION public.approve_marketing_recommendation(
  p_recommendation_id text,
  p_approved_by text DEFAULT 'studio_admin'
)
RETURNS TABLE (
  success boolean,
  message text,
  prepared_post_id text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_recommendation studio_marketing_recommendations%rowtype;
  v_prepared_post_id uuid;
BEGIN
  -- Récupérer la recommandation en attente
  SELECT * INTO v_recommendation
  FROM studio_marketing_recommendations
  WHERE studio_marketing_recommendations.id = p_recommendation_id::uuid
    AND status = 'pending';

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Recommandation non trouvée ou déjà traitée', NULL::text;
    RETURN;
  END IF;

  -- Mettre à jour le statut de la recommandation
  UPDATE studio_marketing_recommendations
  SET status = 'approved',
      approved_at = now(),
      approved_by = p_approved_by
  WHERE id = v_recommendation.id;

  -- Créer le post préparé pour validation finale
  INSERT INTO studio_facebook_prepared_posts (
    recommendation_id,
    final_message,
    media_type,
    status
  ) VALUES (
    v_recommendation.id,
    COALESCE(v_recommendation.proposed_message, ''),
    COALESCE(v_recommendation.proposed_format, 'text'),
    'ready_for_validation'
  ) RETURNING studio_facebook_prepared_posts.id INTO v_prepared_post_id;

  RETURN QUERY
  SELECT true, 'Recommandation approuvée avec succès', v_prepared_post_id::text;
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_marketing_recommendation(text, text) TO anon, authenticated;

-- 2) Fonction de rejet d'une recommandation
CREATE OR REPLACE FUNCTION public.reject_marketing_recommendation(
  p_recommendation_id text,
  p_reason text DEFAULT 'Rejeté par administrateur'
)
RETURNS TABLE (
  success boolean,
  message text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid := p_recommendation_id::uuid;
BEGIN
  UPDATE studio_marketing_recommendations
  SET status = 'rejected',
      approved_at = now(),
      approved_by = 'studio_admin',
      metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object('rejection_reason', p_reason)
  WHERE id = v_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Recommandation non trouvée ou déjà traitée';
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Recommandation rejetée avec succès';
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_marketing_recommendation(text, text) TO anon, authenticated;

-- 3) Fonction de publication d'un post préparé
CREATE OR REPLACE FUNCTION public.publish_prepared_post(
  p_prepared_post_id text
)
RETURNS TABLE (
  success boolean,
  message text,
  facebook_post_id text,
  facebook_url text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_prepared_post studio_facebook_prepared_posts%rowtype;
  v_facebook_result record;
BEGIN
  -- Récupérer le post préparé en statut prêt ou approuvé
  SELECT * INTO v_prepared_post
  FROM studio_facebook_prepared_posts
  WHERE id = p_prepared_post_id::uuid
    AND status IN ('ready_for_validation', 'approved');

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Post non trouvé ou non prêt', NULL::text, NULL::text;
    RETURN;
  END IF;

  -- Appeler la RPC Facebook réelle
  SELECT * INTO v_facebook_result
  FROM facebook_publish_post(
    v_prepared_post.media_type,
    v_prepared_post.final_message,
    CASE WHEN v_prepared_post.media_type = 'image' THEN v_prepared_post.media_url ELSE NULL END,
    CASE WHEN v_prepared_post.media_type = 'video' THEN v_prepared_post.media_url ELSE NULL END
  );

  IF v_facebook_result.id IS NOT NULL THEN
    -- Mettre à jour le statut du post préparé
    UPDATE studio_facebook_prepared_posts
    SET status = 'published',
        updated_at = now()
    WHERE id = v_prepared_post.id;

    -- Mettre à jour la recommandation liée
    UPDATE studio_marketing_recommendations
    SET status = 'published',
        published_at = now(),
        published_facebook_id = v_facebook_result.post_id
    WHERE id = v_prepared_post.recommendation_id;

    RETURN QUERY
    SELECT true, 'Publication réussie', v_facebook_result.post_id::text, v_facebook_result.url::text;
  ELSE
    RETURN QUERY
    SELECT false, 'Échec de publication Facebook', NULL::text, NULL::text;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.publish_prepared_post(text) TO anon, authenticated;
