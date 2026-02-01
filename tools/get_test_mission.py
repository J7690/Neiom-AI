import json
import os
import sys

import requests


def _load_env_from_file(path: str) -> None:
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
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    supabase_env_file = os.path.join(project_root, "supabase", ".env")
    unv_env_file = os.path.join(project_root, ".unv", "supabase_admin.env")

    _load_env_from_file(unv_env_file)
    _load_env_from_file(supabase_env_file)

    supabase_url = os.environ.get("SUPABASE_URL")
    service_role_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

    if not supabase_url or not service_role_key:
        print("ERROR: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY", file=sys.stderr)
        sys.exit(1)

    url = f"{supabase_url.rstrip('/')}/rest/v1/studio_marketing_missions"
    params = {
        "select": "id,objective_id,channel,activity_ref,status,created_at",
        "status": "eq.active",
        "activity_ref": "ilike.*cours*",
        "order": "created_at.desc",
        "limit": "5",
    }
    headers = {
        "apikey": service_role_key,
        "Authorization": f"Bearer {service_role_key}",
    }

    try:
        resp = requests.get(url, headers=headers, params=params, timeout=30)
        resp.raise_for_status()
        missions = resp.json()
        print(json.dumps(missions, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
