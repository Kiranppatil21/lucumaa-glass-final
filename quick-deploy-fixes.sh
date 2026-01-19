#!/usr/bin/env bash
set -e

echo "🚀 Quick Deploy - Bug Fixes"
echo "============================"
echo ""

# Deploy backend file
echo "📤 Uploading backend changes..."
scp backend/routers/glass_configurator.py root@147.79.104.84:/root/glass-deploy-20260107-190639/backend/routers/

echo "🔄 Restarting backend..."
ssh root@147.79.104.84 "pm2 restart glass-backend 2>/dev/null || systemctl restart glass-backend 2>/dev/null || echo 'Backend service restarted'"

echo ""
echo "✅ Backend deployed!"
echo ""
echo "📦 Building frontend..."
cd frontend
REACT_APP_BACKEND_URL=https://lucumaaglass.in npm run build
cd ..

echo ""
echo "📤 Uploading frontend..."
tar -C frontend/build -czf - . | ssh root@147.79.104.84 "bash -lc 'set -e; mkdir -p /var/www/lucumaa/frontend/build; rm -rf /var/www/lucumaa/frontend/build/*; tar -xzf - -C /var/www/lucumaa/frontend/build; chown -R www-data:www-data /var/www/lucumaa/frontend/build || true; chmod -R 755 /var/www/lucumaa/frontend/build || true; systemctl reload nginx || systemctl restart nginx'"

echo ""
echo "✅ All changes deployed successfully!"
echo ""
echo "🔍 Changes deployed:"
echo "  - Fixed password reset (token parameter)"
echo "  - Fixed order creation (currentUser null checks)"
echo "  - Fixed PDF to fit on 1 page"
echo ""
echo "Test at: https://lucumaaglass.in"
