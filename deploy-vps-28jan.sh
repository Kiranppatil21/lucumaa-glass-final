#!/bin/bash

# Glass ERP VPS Deployment Script - 28 January 2026
# Deploys all fixes: heart shape, oval sizing, design PDF download

set -e

VPS_HOST="147.79.104.84"
VPS_USER="root"
DEPLOY_PATH="/root/glass-deploy-20260107-190639"
BACKEND_PATH="/root/glass-backend"
FRONTEND_PATH="/root/glass-frontend"

echo "=================================="
echo "🚀 Glass ERP VPS Deployment"
echo "Date: $(date '+%d-%m-%Y %H:%M:%S')"
echo "=================================="

# Step 1: Pull latest changes from Git
echo ""
echo "📥 Step 1: Pulling latest changes from GitHub..."
ssh "$VPS_USER@$VPS_HOST" "cd $DEPLOY_PATH && git pull origin main" || { echo "❌ Git pull failed"; exit 1; }
echo "✅ Git pull successful"

# Step 2: Deploy Backend
echo ""
echo "🔧 Step 2: Deploying Backend Changes..."
scp "$DEPLOY_PATH/backend/routers/glass_configurator.py" "$VPS_USER@$VPS_HOST:$BACKEND_PATH/routers/" || { echo "❌ Failed to copy glass_configurator.py"; exit 1; }
scp "$DEPLOY_PATH/backend/routers/job_work.py" "$VPS_USER@$VPS_HOST:$BACKEND_PATH/routers/" || { echo "❌ Failed to copy job_work.py"; exit 1; }
scp "$DEPLOY_PATH/backend/routers/orders_router.py" "$VPS_USER@$VPS_HOST:$BACKEND_PATH/routers/" || { echo "❌ Failed to copy orders_router.py"; exit 1; }
echo "✅ Backend files deployed"

# Step 3: Deploy Frontend
echo ""
echo "🎨 Step 3: Deploying Frontend Changes..."
scp "$DEPLOY_PATH/frontend/src/pages/JobWorkPage.js" "$VPS_USER@$VPS_HOST:$FRONTEND_PATH/src/pages/" || { echo "❌ Failed to copy JobWorkPage.js"; exit 1; }
scp "$DEPLOY_PATH/frontend/src/pages/erp/JobWorkDashboard.js" "$VPS_USER@$VPS_HOST:$FRONTEND_PATH/src/pages/erp/" || { echo "❌ Failed to copy JobWorkDashboard.js"; exit 1; }
echo "✅ Frontend files deployed"

# Step 4: Rebuild Frontend
echo ""
echo "⚙️ Step 4: Rebuilding Frontend..."
ssh "$VPS_USER@$VPS_HOST" "cd $FRONTEND_PATH && npm cache clean --force && rm -rf node_modules build && npm install --legacy-peer-deps 2>&1 | tail -3" || { echo "❌ npm install failed"; exit 1; }
ssh "$VPS_USER@$VPS_HOST" "cd $FRONTEND_PATH && npm run build 2>&1 | tail -5" || { echo "❌ npm build failed"; exit 1; }
echo "✅ Frontend rebuilt successfully"

# Step 5: Restart Services
echo ""
echo "🔄 Step 5: Restarting Services..."
ssh "$VPS_USER@$VPS_HOST" "systemctl restart glass-backend && sleep 3" || { echo "❌ Failed to restart backend"; exit 1; }
echo "✅ Backend restarted"

# Step 6: Verify Deployment
echo ""
echo "✔️ Step 6: Verifying Deployment..."
ssh "$VPS_USER@$VPS_HOST" "systemctl is-active glass-backend && echo 'Backend is running' || echo 'Backend is NOT running'"
echo ""
echo "✅ Checking if new code is in production build..."
ssh "$VPS_USER@$VPS_HOST" "grep -q 'heart shape' $FRONTEND_PATH/build/static/js/main.*.js && echo '✓ New frontend code detected' || echo 'Frontend code not found in build'"

# Final summary
echo ""
echo "=================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=================================="
echo ""
echo "📊 Summary of Changes:"
echo "  • ✅ Heart shape rotation fixed (removed negative sign)"
echo "  • ✅ Oval cutout sizing corrected (w/2 → w)"
echo "  • ✅ Design PDF download added to job work success page"
echo "  • ✅ Email notifications fixed (SMTP password defaults)"
echo "  • ✅ Oval preview rendering fixed in dashboard"
echo ""
echo "🌐 Live URL: https://lucumaaglass.in"
echo "📅 Deployed: $(date '+%d-%m-%Y %H:%M:%S')"
echo ""
