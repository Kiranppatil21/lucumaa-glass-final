#!/usr/bin/env bash
set -euo pipefail

# Forces browsers to fetch fresh JS/CSS by adding a version querystring
# and adds a non-blank fallback inside #root.

VERSION="$(date +%Y%m%d-%H%M%S)"

candidates=(
  "/var/www/lucumaa/frontend/build/index.html"
  "/var/www/glass-erp/index.html"
)

picked=""
for f in "${candidates[@]}"; do
  if [[ -f "$f" ]]; then
    picked="$f"
    break
  fi
done

if [[ -z "$picked" ]]; then
  echo "ERROR: Could not find index.html in expected locations:" >&2
  printf ' - %s\n' "${candidates[@]}" >&2
  exit 1
fi

cp -a "$picked" "$picked.bak.$VERSION"

# Cache-bust build assets (append ?v=... to main.*.js/css)
if command -v perl >/dev/null 2>&1; then
  perl -pi -e "s|(/static/js/main\.[^\"\?]+\.js)(?!\?)|\$1?v=$VERSION|g" "$picked"
  perl -pi -e "s|(/static/css/main\.[^\"\?]+\.css)(?!\?)|\$1?v=$VERSION|g" "$picked"
else
  # Fallback for environments without perl (uses known current build filenames)
  sed -i "s|/static/js/main\\.79ae5e35\\.js|/static/js/main.79ae5e35.js?v=$VERSION|g" "$picked"
  sed -i "s|/static/css/main\\.62b91195\\.css|/static/css/main.62b91195.css?v=$VERSION|g" "$picked"
fi

# Ensure the page is never visually blank even if JS fails to execute.
# Replace the empty root div if present.
sed -i 's|<div id="root"></div>|<div id="root" style="padding:16px;font-family:system-ui">Loading… If this stays blank, hard refresh (Cmd+Shift+R). If it still fails, check DevTools Console/Network.</div>|g' "$picked"

# Reload nginx if present
if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nginx; then
  systemctl reload nginx
fi

# If multiple server blocks exist, reload may not apply; try a restart if reload fails.
if command -v systemctl >/dev/null 2>&1; then
  systemctl reload nginx || systemctl restart nginx || true
fi

echo "OK: Updated $picked"
echo "- Backup: $picked.bak.$VERSION"
echo "- Version: $VERSION"
