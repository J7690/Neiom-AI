-- Phase FB – Contexte de publication Facebook
-- Objectif : permettre de stocker un texte libre de contexte de publication
-- lié aux studio_facebook_prepared_posts et l'exposer aux pipelines IA.
-- A exécuter avec : python tools/admin_sql.py --file supabase/sql/2026-01-31_phaseFB_publication_context.sql

-- 1) Ajouter une colonne de contexte aux posts préparés
alter table public.studio_facebook_prepared_posts
  add column if not exists publication_context text;

-- 2) RPC pour mettre à jour le contexte de publication d'un prepared_post
create or replace function public.set_publication_context_for_prepared_post(
  p_prepared_post_id text,
  p_publication_context text
)
returns table (
  success boolean,
  message text,
  publication_context text
)
language plpgsql
security definer
set search_path = public as
$$
declare
  v_id uuid := p_prepared_post_id::uuid;
begin
  update public.studio_facebook_prepared_posts
  set publication_context = p_publication_context,
      updated_at = now()
  where id = v_id;

  if not found then
    return query
    select false,
           'Prepared post not found',
           null::text;
    return;
  end if;

  return query
  select true,
         'Publication context updated',
         publication_context
  from public.studio_facebook_prepared_posts
  where id = v_id;
end;
$$;

grant execute on function public.set_publication_context_for_prepared_post(text, text) to anon, authenticated;
