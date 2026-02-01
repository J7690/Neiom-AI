-- Audit global Supabase – inventaire complet des objets principaux du schéma public
-- ATTENTION : lecture seule, aucune modification.

-- 1) Liste complète des tables et vues du schéma public
SELECT
  'TABLE' AS kind,
  table_name AS name,
  table_type AS extra
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2) Liste complète des fonctions / RPC du schéma public (via information_schema.routines)
SELECT
  'FUNCTION' AS kind,
  routine_name AS name,
  routine_type AS extra,
  data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- 3) Détail supplémentaire sur les fonctions (via pg_proc) – nom + nombre d'arguments
SELECT
  'PROC' AS kind,
  p.proname AS name,
  pg_catalog.pg_get_function_arguments(p.oid) AS extra
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
ORDER BY p.proname;
