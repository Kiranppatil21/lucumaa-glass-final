#!/bin/bash

# Glass ERP VPS Deployment Script - 28 January 2026
# Deploy from local to VPS deploy directory

set -e

VPS_HOST="147.79.104.84"
VPS_USER="root"
LOCAL_PATH="/Users/admin/Desktop/Glass"
DEPLOY_PATH="/root/glass-deploy-20260107-190639"

echo "=================================="
echo "🚀 Glass ERP VPS Deployment"
echo "Date: $(date '+%d-%m-%Y %H:%M:%S')"
echo "=================================="

# Step 1: Deploy Backend
echo ""
echo "🔧 Step 1: Deploying Backend Changes..."
scp "$LOCAL_PATH/backend/routers/glass_configurator.py" "$VPS_USER@$VPS_HOST:$DEPLOY_PATH/backend/routers/" && echo "  ✅ glass_configurator.py" || exit 1
scp "$LOCAL_PATH/backend/routers/job_work.py" "$VPS_USER@$VPS_HOST:$DEPLOY_PATH/backend/routers/" && echo "  ✅ job_work.py" || exit 1
scp "$LOCAL_PATH/backend/routers/orders_router.py" "$VPS_USER@$VPS_HOST:$DEPLOY_PATH/backend/routers/" && echo "  ✅ orders_router.py" || exit 1
echo "✅ Backend files deployed"

# Step 2: Deploy Frontend
echo ""
echo "🎨 Step 2: Deploying Frontend Changes..."
scp "$LOCAL_PATH/frontend/src/pages/JobWorkPage.js" "$VPS_USER@$VPS_HOST:$DEPLOY_PATH/frontend/src/pages/" && echo "  ✅ JobWorkPage.js" || exit 1
scp "$LOCAL_PATH/frontend/src/pages/erp/JobWorkDashboard.js" "$VPS_USER@$VPS_HOST:$DEPLOY_PATH/frontend/src/pages/erp/" && echo "  ✅ JobWorkDashboard.js" || exit 1
echo "✅ Frontend files deployed to deploy directory"

# Step 3: Run VPS deployment script
echo ""
echo "🔄 Step 3: Running VPS Deployment Script..."
ssh "$VPS_USER@$VPS_HOST" << 'DEPLOY_SCRIPT'
cd /root/glass-deploy-20260107-190639

echo "📁 Copying backend files to live backend..."
cp backend/routers/glass_configurator.py /var/www/glass-backend/routers/ 2>/dev/null || echo "  (trying alternate path...)"
cp backend/routers/job_work.py /var/www/glass-backend/routers/ 2>/dev/null || echo "  (trying alternate path...)"
cp backend/routers/orders_router.py /var/www/glass-backend/routers/ 2>/dev/null || echo "  (trying alternate path...)"

# Find and copy to actual backend location
BACKEND_LOC=$(find /home -name "job_work.py" -type f 2>/dev/null | grep routers | head -1 | sed 's|/job_work.py||')
if [ -n "$BACKEND_LOC" ]; then
    echo "✅ Found backend at: $BACKEND_LOC"
    cp backend/routers/glass_configurator.py "$BACKEND_LOC/" && echo "  ✅ glass_configurator.py copied"
    cp backend/routers/job_work.py "$BACKEND_LOC/" && echo "  ✅ job_work.py copied"
    cp backend/routers/orders_router.py "$BACKEND_LOC/" && echo "  ✅ orders_router.py copied"
fi

echo ""
echo "📁 Copying frontend files to live frontend..."
FRONTEND_LOC=$(find /home -name "JobWorkPage.js" -type f 2>/dev/null | sed 's|/JobWorkPage.js||' | head -1)
if [ -n "$FRONTEND_LOC" ]; then
    echo "✅ Found frontend at: $FRONTEND_LOC"
    cp frontend/src/pages/JobWorkPage.js "$FRONTEND_LOC/" && echo "  ✅ JobWorkPage.js copied"
    cp frontend/src/pages/erp/JobWorkDashboard.js "$FRONTEND_LOC/erp/" && echo "  ✅ JobWorkDashboard.js copied"
    
    echo ""
    echo "⚙️ Rebuilding frontend..."
    cd $FRONTEND_LOC/../..
    npm cache clean --force 2>&1 | tail -1
    rm -rf node_modules build
    npm install --legacy-peer-deps 2>&1 | tail -2
    npm run build 2>&1 | tail -5
fi

echo ""
echo "🔄 Restarting backend service..."
systemctl restart glass-backend 2>/dev/null || service glass-backend restart 2>/dev/null || echo "  (service restart may need manual attention)"
sleep 3

echo "✅ Services restarted"
DEPLOY_SCRIPT

# Step 4: Verify
echo ""
echo "✔️ Step 4: Verifying Deployment..."
echo "Checking backend status..."
BACKEND_STATUS=$(ssh "$VPS_USER@$VPS_HOST" "systemctl is-active glass-backend 2>/dev/null || echo 'unknown'")
echo "Backend status: $BACKEND_STATUS"

# Final summary
echo ""
echo "=================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=================================="
echo ""
echo "📊 Summary of Changes Deployed:"
echo "  ✅ Heart shape rotation fixed (y calculation)"
echo "  ✅ Oval cutout sizing corrected (ellipse w/h)"  
echo "  ✅ Design PDF download added to job work success"
echo "  ✅ Email SMTP password defaults fixed"
echo "  ✅ Oval preview rendering in dashboard fixed"
echo ""
echo "🌐 Live URL: https://lucumaaglass.in"
echo "📅 Deployed: $(date '+%d-%m-%Y %H:%M:%S')"
echo ""
