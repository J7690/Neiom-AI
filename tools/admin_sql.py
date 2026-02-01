import argparse
import os
import sys

import requests


def _load_env_from_file(path: str) -> None:
  """Load SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from a simple KEY=VALUE env file.

  Lines starting with # or empty lines are ignored. Existing environment
  variables are not overwritten.
  """
  if not os.path.isfile(path):
    return

  try:
    with open(path, "r", encoding="utf-8") as f:
      for raw_line in f:
        line = raw_line.strip()
        if not line or line.startswith("#"):
          continue
        if "=" not in line:
          continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()
        # Retirer d'éventuels guillemets autour de la valeur (format KEY="value")
        if (value.startswith('"') and value.endswith('"')) or (
          value.startswith("'") and value.endswith("'")
        ):
          value = value[1:-1]
        # Ici, on écrase toujours la valeur existante pour que le fichier
        # d'environnement du projet soit la source de vérité.
        if key and value:
          os.environ[key] = value
  except Exception:
    # En cas de problème de lecture, on laisse simplement les variables
    # d'environnement telles qu'elles sont.
    return


def call_rpc(rpc_name: str, rpc_args: dict) -> str:
  # Charger les variables d'environnement depuis les fichiers projet,
  # comme pour run_sql_script, afin que SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY
  # soient disponibles même si le script est lancé depuis le repo.
  project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
  supabase_env_file = os.path.join(project_root, "supabase", ".env")
  unv_env_file = os.path.join(project_root, ".unv", "supabase_admin.env")
  _load_env_from_file(unv_env_file)
  _load_env_from_file(supabase_env_file)

  supabase_url = os.environ.get("SUPABASE_URL")
  service_role_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

  if not supabase_url or not service_role_key:
    print(
      "ERROR: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set either in .unv/supabase_admin.env or in the environment.",
      file=sys.stderr,
    )
    sys.exit(1)

  endpoint = supabase_url.rstrip("/") + "/rest/v1/rpc/" + rpc_name
  headers = {
    "apikey": service_role_key,
    "Authorization": f"Bearer {service_role_key}",
    "Content-Type": "application/json",
  }
  payload = rpc_args

  try:
    resp = requests.post(endpoint, json=payload, headers=headers, timeout=60)
  except Exception as e:  # pragma: no cover
    print(f"ERROR: HTTP request failed: {e}", file=sys.stderr)
    sys.exit(1)

  if resp.status_code >= 400:
    print(f"ERROR: RPC {rpc_name} failed with status {resp.status_code}", file=sys.stderr)
    try:
      print(resp.text, file=sys.stderr)
    except Exception:
      pass
    sys.exit(1)

  try:
    return resp.text
  except Exception:
    return ""


def run_sql_script(sql_path: str) -> None:
  project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
  # Charger d'abord les variables éventuelles depuis supabase/.env, puis .unv/supabase_admin.env
  supabase_env_file = os.path.join(project_root, "supabase", ".env")
  unv_env_file = os.path.join(project_root, ".unv", "supabase_admin.env")
  _load_env_from_file(unv_env_file)
  _load_env_from_file(supabase_env_file)

  supabase_url = os.environ.get("SUPABASE_URL")
  service_role_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

  if not supabase_url or not service_role_key:
    print(
      "ERROR: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set either in .unv/supabase_admin.env or in the environment.",
      file=sys.stderr,
    )
    sys.exit(1)

  if not os.path.isfile(sql_path):
    print(f"ERROR: SQL file not found: {sql_path}", file=sys.stderr)
    sys.exit(1)

  with open(sql_path, "r", encoding="utf-8") as f:
    sql = f.read()

  if not sql.strip():
    print("ERROR: SQL file is empty.", file=sys.stderr)
    sys.exit(1)

  endpoint = supabase_url.rstrip("/") + "/rest/v1/rpc/admin_execute_sql"
  headers = {
    "apikey": service_role_key,
    "Authorization": f"Bearer {service_role_key}",
    "Content-Type": "application/json",
  }
  payload = {"sql": sql}

  try:
    resp = requests.post(endpoint, json=payload, headers=headers, timeout=60)
  except Exception as e:  # pragma: no cover
    print(f"ERROR: HTTP request failed: {e}", file=sys.stderr)
    sys.exit(1)

  if resp.status_code >= 400:
    print(f"ERROR: admin_execute_sql failed with status {resp.status_code}", file=sys.stderr)
    try:
      print(resp.text, file=sys.stderr)
    except Exception:
      pass
    sys.exit(1)

  print("OK: SQL executed successfully via admin_execute_sql.")
  try:
    # Afficher le corps de la réponse pour inspection (résultats JSON de la requête SQL).
    print(resp.text)
  except Exception:
    # Si jamais l'impression échoue, on n'interrompt pas le script.
    pass


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Outil d'administration SQL/RPC pour Supabase Nexiom.")
    parser.add_argument('--file', type=str, help='Script SQL à exécuter')
    parser.add_argument('--rpc', type=str, help='Nom de la fonction RPC à tester')
    parser.add_argument('--args', type=str, nargs='*', help='Arguments de la RPC (clé=valeur)')
    args = parser.parse_args()

    if args.file:
        run_sql_script(args.file)
    elif args.rpc:
        # Mode RPC direct pour audit
        rpc_args = {}
        if args.args:
            for arg in args.args:
                if '=' in arg:
                    k, v = arg.split('=', 1)
                    rpc_args[k] = v
        print(f"[AUDIT] Test de la fonction RPC {args.rpc} avec arguments: {rpc_args}")
        result = call_rpc(args.rpc, rpc_args)
        print("[RESULTAT RPC]", result)
    else:
        parser.print_help()
