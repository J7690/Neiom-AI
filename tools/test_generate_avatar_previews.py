import os
import textwrap

import requests


def load_env_from_file(path: str) -> None:
    """Load SUPABASE_URL / SUPABASE_ANON_KEY from a KEY=VALUE env file.

    Mirrors the behaviour of tools/admin_sql.py so that we target the same
    Supabase project as the Edge Functions and Flutter app.
    """
    if not os.path.isfile(path):
        return
    with open(path, "r", encoding="utf-8") as f:
        for raw_line in f:
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip()
            if (value.startswith('"') and value.endswith('"')) or (
                value.startswith("'") and value.endswith("'")
            ):
                value = value[1:-1]
            if key and value:
                # Override any pre-existing value so that supabase/.env is the
                # single source of truth for SUPABASE_URL / SUPABASE_ANON_KEY,
                # matching the behaviour of tools/admin_sql.py.
                os.environ[key] = value


def main() -> None:
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    # Reuse the same .env as Edge Functions / Flutter
    load_env_from_file(os.path.join(project_root, "supabase", ".env"))

    supabase_url = os.environ.get("SUPABASE_URL")
    anon_key = os.environ.get("SUPABASE_ANON_KEY")

    if not supabase_url or not anon_key:
        print("MISSING_ENV SUPABASE_URL or SUPABASE_ANON_KEY")
        raise SystemExit(1)

    endpoint = supabase_url.rstrip("/") + "/functions/v1/generate-avatar-previews"
    headers = {
        "apikey": anon_key,
        "Authorization": f"Bearer {anon_key}",
        "Content-Type": "application/json",
    }

    # We intentionally use dummy ids here: the goal is to check that the
    # Edge Function endpoint is reachable (HTTP status, CORS headers),
    # not that the input payload is valid.
    payload = {"avatarProfileId": "test-avatar-id", "agentIds": ["test-agent-id"]}

    print(f"Testing Edge Function endpoint: {endpoint}")

    try:
        resp = requests.post(endpoint, json=payload, headers=headers, timeout=30)
    except Exception as e:  # pragma: no cover
        print("HTTP_ERROR", repr(e))
        raise SystemExit(1)

    print("STATUS", resp.status_code)
    cors_headers = {
        k: v
        for k, v in resp.headers.items()
        if k.startswith("Access-Control") or k == "Content-Type"
    }
    print("CORS_HEADERS", cors_headers)

    body = resp.text or ""
    if len(body) > 800:
        body = body[:800] + "..."
    body = body.replace("\n", " ")
    print("BODY_SNIPPET", textwrap.shorten(body, width=800, placeholder="..."))


if __name__ == "__main__":
    main()
