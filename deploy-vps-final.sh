#!/bin/bash

# Glass ERP VPS Deployment Script - 28 January 2026
# Simple direct deployment from local to VPS

set -e

VPS_HOST="147.79.104.84"
VPS_USER="root"
LOCAL_PATH="/Users/admin/Desktop/Glass"
BACKEND_PATH="/root/glass-backend"
FRONTEND_PATH="/root/glass-frontend"

echo "=================================="
echo "🚀 Glass ERP VPS Deployment"
echo "Date: $(date '+%d-%m-%Y %H:%M:%S')"
echo "=================================="

# Step 1: Deploy Backend
echo ""
echo "🔧 Step 1: Deploying Backend Changes..."
scp "$LOCAL_PATH/backend/routers/glass_configurator.py" "$VPS_USER@$VPS_HOST:$BACKEND_PATH/routers/" && echo "  ✅ glass_configurator.py" || exit 1
scp "$LOCAL_PATH/backend/routers/job_work.py" "$VPS_USER@$VPS_HOST:$BACKEND_PATH/routers/" && echo "  ✅ job_work.py" || exit 1
scp "$LOCAL_PATH/backend/routers/orders_router.py" "$VPS_USER@$VPS_HOST:$BACKEND_PATH/routers/" && echo "  ✅ orders_router.py" || exit 1
echo "✅ Backend files deployed"

# Step 2: Deploy Frontend
echo ""
echo "🎨 Step 2: Deploying Frontend Changes..."
scp "$LOCAL_PATH/frontend/src/pages/JobWorkPage.js" "$VPS_USER@$VPS_HOST:$FRONTEND_PATH/src/pages/" && echo "  ✅ JobWorkPage.js" || exit 1
scp "$LOCAL_PATH/frontend/src/pages/erp/JobWorkDashboard.js" "$VPS_USER@$VPS_HOST:$FRONTEND_PATH/src/pages/erp/" && echo "  ✅ JobWorkDashboard.js" || exit 1
echo "✅ Frontend files deployed"

# Step 3: Rebuild Frontend and Restart
echo ""
echo "⚙️ Step 3: Rebuilding Frontend and Restarting Services..."
ssh "$VPS_USER@$VPS_HOST" << 'REBUILD'
cd /root/glass-frontend

echo "  Clearing npm cache..."
npm cache clean --force 2>&1 | tail -1

echo "  Removing old build..."
rm -rf node_modules build

echo "  Installing dependencies..."
npm install --legacy-peer-deps 2>&1 | tail -2

echo "  Building frontend..."
npm run build 2>&1 | tail -5

echo "  Restarting backend..."
systemctl restart glass-backend
sleep 3

echo "✅ Services restarted"
REBUILD

# Step 4: Verify Deployment
echo ""
echo "✔️ Step 4: Verifying Deployment..."
BACKEND_STATUS=$(ssh "$VPS_USER@$VPS_HOST" "systemctl is-active glass-backend")
if [ "$BACKEND_STATUS" = "active" ]; then
    echo "  ✅ Backend is running"
else
    echo "  ❌ Backend is NOT running"
    exit 1
fi

# Final summary
echo ""
echo "=================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=================================="
echo ""
echo "📊 Summary of Changes Deployed:"
echo "  ✅ Heart shape rotation fixed (y calculation sign removed)"
echo "  ✅ Oval cutout sizing corrected (ellipse dimensions)"  
echo "  ✅ Design PDF download added to job work success page"
echo "  ✅ Email notifications fixed (SMTP password defaults)"
echo "  ✅ Oval preview rendering fixed in dashboard"
echo ""
echo "🌐 Live URL: https://lucumaaglass.in"
echo "📅 Deployed: $(date '+%d-%m-%Y %H:%M:%S')"
echo ""
echo "Next: Test all features on live VPS..."
echo ""
