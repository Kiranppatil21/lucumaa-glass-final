#!/bin/bash
# Deploy fixes to live VPS
set -e

echo "================================"
echo "Deploying Fixes to VPS"
echo "================================"
echo ""

# Configuration
VPS_IP="147.79.104.84"
VPS_USER="root"
VPS_PATH="/root/glass"
SSH_KEY="$HOME/.ssh/id_rsa"

echo "🚀 Step 1: Building frontend..."
npm run build --prefix frontend

echo "📤 Step 2: Uploading files to VPS..."

# Upload built frontend
scp -i "$SSH_KEY" -r frontend/build/* "$VPS_USER@$VPS_IP:$VPS_PATH/frontend/build/"

# Upload backend files (job_work.py)
scp -i "$SSH_KEY" backend/routers/job_work.py "$VPS_USER@$VPS_IP:$VPS_PATH/backend/routers/"

# Upload frontend source files
scp -i "$SSH_KEY" frontend/src/pages/JobWork3DConfigurator.js "$VPS_USER@$VPS_IP:$VPS_PATH/frontend/src/pages/"
scp -i "$SSH_KEY" frontend/src/pages/GlassConfigurator3D.js "$VPS_USER@$VPS_IP:$VPS_PATH/frontend/src/pages/"
scp -i "$SSH_KEY" frontend/src/pages/erp/JobWorkDashboard.js "$VPS_USER@$VPS_IP:$VPS_PATH/frontend/src/pages/erp/"

echo "🔄 Step 3: Restarting services on VPS..."
ssh -i "$SSH_KEY" "$VPS_USER@$VPS_IP" << 'EOF'
cd /root/glass

# Restart backend
systemctl restart glass-backend

# Restart frontend (if using pm2)
cd frontend && pm2 restart "glass-frontend" || echo "Frontend not running via pm2"

echo "✅ Services restarted"
EOF

echo ""
echo "✅ Deployment complete!"
echo "🌐 Visit https://lucumaaglass.in to verify"
echo ""
echo "Changes deployed:"
echo "  ✓ Design PDF endpoint for job-work orders"
echo "  ✓ Design PDF download button in JobWorkDashboard"
echo "  ✓ Fixed cutout reselect drag/resize bug"
echo "  ✓ Cutout data now saved with job work orders"
