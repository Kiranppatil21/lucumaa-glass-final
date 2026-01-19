#!/usr/bin/env bash
set -euo pipefail

# Deploys the React build to the current lucumaa VPS layout.
# Assumes nginx serves: /var/www/lucumaa/frontend/build

VPS_HOST="${VPS_HOST:-root@147.79.104.84}"
REMOTE_BUILD_DIR="${REMOTE_BUILD_DIR:-/var/www/lucumaa/frontend/build}"
SKIP_BUILD="${SKIP_BUILD:-0}"
FRONTEND_BACKEND_URL="${FRONTEND_BACKEND_URL:-https://lucumaaglass.in}"

if [[ "$SKIP_BUILD" != "1" ]]; then
  echo "Building frontend (production)…"
  # Guardrail: force a sane backend URL at build time so we never bake localhost into production.
  (cd frontend && REACT_APP_BACKEND_URL="$FRONTEND_BACKEND_URL" npm run build)

  # Guardrail: if the build accidentally embeds localhost API URLs, don't deploy it.
  if grep -R "http://localhost:8000\|http://127.0.0.1:8000\|https://localhost:8000\|https://127.0.0.1:8000" -n frontend/build/static/js/main*.js >/dev/null 2>&1; then
    echo "ERROR: Build output still contains localhost:8000 API URLs."
    echo "Fix REACT_APP_BACKEND_URL for production and rebuild before deploying."
    exit 1
  fi
fi

if [[ ! -d "frontend/build" ]]; then
  echo "ERROR: frontend/build not found. Run with SKIP_BUILD=0 (default)." >&2
  exit 1
fi

echo "Uploading build to $VPS_HOST:$REMOTE_BUILD_DIR …"
# Stream a tarball over SSH to avoid slow scp of many small files

tar -C frontend/build -czf - . | ssh "$VPS_HOST" "bash -lc 'set -e; mkdir -p \"$REMOTE_BUILD_DIR\"; rm -rf \"$REMOTE_BUILD_DIR\"/*; tar -xzf - -C \"$REMOTE_BUILD_DIR\"; chown -R www-data:www-data \"$REMOTE_BUILD_DIR\" || true; chmod -R 755 \"$REMOTE_BUILD_DIR\" || true; systemctl reload nginx || systemctl restart nginx'"

echo "OK: Deployed frontend build to $REMOTE_BUILD_DIR"
