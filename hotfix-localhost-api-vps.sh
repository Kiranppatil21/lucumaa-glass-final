#!/usr/bin/env bash
set -euo pipefail

# Hotfix: Replace baked-in localhost API URLs inside the currently deployed frontend build.
# This is safe and reversible (backs up files first).

TARGET_ORIGIN="${TARGET_ORIGIN:-https://lucumaaglass.in}"

# Known deployment paths (we'll patch whichever exists)
ROOTS=(
  "/var/www/lucumaa/frontend/build"
  "/var/www/glass-erp"
)

pick_root=""
for r in "${ROOTS[@]}"; do
  if [[ -d "$r" ]]; then
    pick_root="$r"
    break
  fi
done

if [[ -z "$pick_root" ]]; then
  echo "ERROR: Could not find frontend build directory in: ${ROOTS[*]}" >&2
  exit 1
fi

stamp="$(date +%Y%m%d-%H%M%S)"

# Patch main JS and its sourcemap(s)
files=(
  $(ls -1 "$pick_root"/static/js/main.*.js 2>/dev/null || true)
  $(ls -1 "$pick_root"/static/js/main.*.js.map 2>/dev/null || true)
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "ERROR: No main.*.js files found under $pick_root/static/js" >&2
  exit 1
fi

echo "Patching build in: $pick_root"
for f in "${files[@]}"; do
  cp -a "$f" "$f.bak.$stamp"
  # Replace any hardcoded localhost API origin
  perl -pi -e "s|https?://localhost:8000|$TARGET_ORIGIN|g; s|https?://127\\.0\\.0\\.1:8000|$TARGET_ORIGIN|g" "$f"
  echo "- patched: $f (backup: $f.bak.$stamp)"
done

# Reload nginx if present
if command -v systemctl >/dev/null 2>&1; then
  systemctl reload nginx || systemctl restart nginx || true
fi

echo "OK: Hotfix applied. Open https://lucumaaglass.in/login with hard refresh (Cmd+Shift+R)."