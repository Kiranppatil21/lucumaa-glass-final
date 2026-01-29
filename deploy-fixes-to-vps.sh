#!/bin/bash

# Deploy fixes to VPS - Proper deployment
set -e

VPS_HOST="root@147.79.104.84"
DEPLOY_DIR="/root/glass-deploy-20260107-190639"

echo "🚀 Deploying fixes to VPS..."

# Step 1: Pull latest code
echo ""
echo "📥 Step 1: Pulling latest code..."
ssh $VPS_HOST "cd $DEPLOY_DIR && git pull origin main"

# Step 2: Rebuild frontend
echo ""
echo "🏗️  Step 2: Building frontend..."
ssh $VPS_HOST "cd $DEPLOY_DIR/frontend && npm run build"

# Step 3: Deploy frontend
echo ""
echo "📦 Step 3: Deploying frontend to /var/www/glass-erp..."
ssh $VPS_HOST "rm -rf /var/www/glass-erp/* && cp -r $DEPLOY_DIR/frontend/build/* /var/www/glass-erp/"

# Step 4: Restart backend
echo ""
echo "🔄 Step 4: Restarting backend..."
ssh $VPS_HOST "pkill -f uvicorn || true"
sleep 3
ssh $VPS_HOST "cd $DEPLOY_DIR && source venv/bin/activate && cd backend && nohup python -m uvicorn server:app --host 0.0.0.0 --port 8000 > ../backend.log 2>&1 &"

# Step 5: Verify deployment
echo ""
echo "✅ Step 5: Verifying deployment..."
sleep 5
ssh $VPS_HOST "ps aux | grep uvicorn | grep -v grep && echo '' && echo '✅ Backend is running'"

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "Please test on: https://lucumaaglass.in"
echo ""
echo "Test checklist:"
echo "  1. ❓ Heart shape points UP (not down)"
echo "  2. ❓ Oval is elliptical (not rectangular)"  
echo "  3. ❓ Job work save shows PDF download button"
echo "  4. ❓ PDF download works"
echo ""
