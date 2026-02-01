import argparse
import json
import os
import sys

import requests


def _load_env_from_file(path: str) -> None:
    """Charge SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY depuis un fichier KEY=VALUE.

    Même logique que dans admin_sql.py pour éviter d'exposer les clés dans les commandes.
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
                if (value.startswith('"') and value.endswith('"')) or (
                    value.startswith("'") and value.endswith("'")
                ):
                    value = value[1:-1]
                if key and value:
                    os.environ[key] = value
    except Exception:
        return


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Invoquer une Edge Function Supabase en utilisant SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY du projet.",
    )
    parser.add_argument("--name", required=True, help="Nom de la fonction (slug), ex: marketing-knowledge-ingest")
    parser.add_argument(
        "--body",
        type=str,
        default="{}",
        help="Corps JSON à envoyer en POST (sous forme de chaîne)",
    )
    parser.add_argument(
        "--body-file",
        type=str,
        default=None,
        help="Chemin vers un fichier JSON à envoyer en POST (recommandé sous PowerShell)",
    )
    args = parser.parse_args()

    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    supabase_env_file = os.path.join(project_root, "supabase", ".env")
    unv_env_file = os.path.join(project_root, ".unv", "supabase_admin.env")

    _load_env_from_file(unv_env_file)
    _load_env_from_file(supabase_env_file)

    supabase_url = os.environ.get("SUPABASE_URL")
    service_role_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

    if not supabase_url or not service_role_key:
        print(
            "ERROR: SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY doivent être définies dans supabase/.env ou .unv/supabase_admin.env",
            file=sys.stderr,
        )
        sys.exit(1)

    # Construire l'URL des Edge Functions: https://<project-ref>.functions.supabase.co/<name>
    if ".supabase.co" not in supabase_url:
        print(f"ERROR: SUPABASE_URL inattendue: {supabase_url}", file=sys.stderr)
        sys.exit(1)

    functions_base = supabase_url.rstrip("/").replace(".supabase.co", ".functions.supabase.co")
    function_url = f"{functions_base}/{args.name}"

    if args.body_file:
        if not os.path.isfile(args.body_file):
            print(f"ERROR: Fichier JSON introuvable: {args.body_file}", file=sys.stderr)
            sys.exit(1)
        try:
            with open(args.body_file, "r", encoding="utf-8") as f:
                json_body = json.load(f)
        except Exception as e:
            print(f"ERROR: Impossible de lire le JSON depuis {args.body_file}: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        try:
            json_body = json.loads(args.body)
        except json.JSONDecodeError as e:
            print(f"ERROR: Corps JSON invalide: {e}", file=sys.stderr)
            sys.exit(1)

    headers = {
        "apikey": service_role_key,
        "Authorization": f"Bearer {service_role_key}",
        "Content-Type": "application/json",
    }

    print(f"[INFO] Calling {function_url} with body: {json.dumps(json_body)}", file=sys.stderr)

    try:
        resp = requests.post(function_url, headers=headers, json=json_body, timeout=120)
    except Exception as e:
        print(f"ERROR: HTTP request failed: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"[INFO] Status: {resp.status_code}", file=sys.stderr)
    try:
        print(resp.text)
    except Exception:
        pass

    if resp.status_code >= 400:
        sys.exit(1)


if __name__ == "__main__":
    main()
