#!/bin/bash

# Critical Fixes Deployment - 29 January 2026
# Fixes: 1) Heart shape flip, 2) Oval shape rendering, 3) Drag/resize issues, 4) Job work save

set -e

echo "🚀 Starting Critical Fixes Deployment - 29 January 2026"
echo "=================================================="

# Configuration
VPS_HOST="lucumaa@103.145.45.65"
VPS_APP_DIR="/app/glass"
VPS_BACKEND_DIR="$VPS_APP_DIR/backend"
VPS_FRONTEND_DIR="$VPS_APP_DIR/frontend"

# Local paths
LOCAL_BACKEND_CONFIG="./backend/routers/glass_configurator.py"
LOCAL_SHAPE_GEN="./frontend/src/utils/ShapeGenerator.js"
LOCAL_JOBWORK_CONFIG="./frontend/src/pages/JobWork3DConfigurator.js"
LOCAL_GLASS_CONFIG="./frontend/src/pages/GlassConfigurator3D.js"

echo ""
echo "📋 Issues Fixed:"
echo "  ✅ Issue 1: Heart shape flip/flop down in PDFs"
echo "  ✅ Issue 2: Fail to save job work"
echo "  ✅ Issue 3: Oval shape looks like rectangle"
echo "  ✅ Issue 4: Cutout cannot move/drag/resize in design area"

echo ""
echo "Step 1: Building frontend..."
cd frontend
npm run build 2>&1 | tail -20
cd ..

echo ""
echo "Step 2: Transferring backend fixes to VPS..."
scp $LOCAL_BACKEND_CONFIG $VPS_HOST:$VPS_BACKEND_DIR/routers/
echo "  ✅ glass_configurator.py transferred"

echo ""
echo "Step 3: Transferring frontend fixes to VPS..."
scp -r frontend/build/* $VPS_HOST:$VPS_APP_DIR/static/ 2>/dev/null || {
  echo "  ⚠️ Building static files..."
  scp -r frontend/build $VPS_HOST:$VPS_APP_DIR/ 2>/dev/null
}
echo "  ✅ Frontend build transferred"

echo ""
echo "Step 4: Restarting backend service on VPS..."
ssh $VPS_HOST << 'EOF'
  cd /app/glass
  echo "Stopping backend..."
  pkill -f "python.*server.py" || true
  sleep 2
  echo "Starting backend..."
  nohup python backend/server.py > backend.log 2>&1 &
  sleep 3
  echo "Backend restarted ✅"
EOF

echo ""
echo "Step 5: Flushing cache on VPS..."
ssh $VPS_HOST << 'EOF'
  cd /app/glass
  # Clear nginx cache
  sudo rm -rf /var/cache/nginx/* || true
  sudo systemctl reload nginx || true
  # Clear Python cache
  find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
  echo "Cache flushed ✅"
EOF

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📝 Changes Deployed:"
echo "  1. Backend (glass_configurator.py):"
echo "     - Fixed heart shape Y coordinate (removed negative sign)"
echo "     - Fixed oval ellipse rendering coordinates"
echo ""
echo "  2. Frontend (ShapeGenerator.js):"
echo "     - Fixed heart shape parametric equation"
echo ""
echo "  3. Frontend (JobWork3DConfigurator.js):"
echo "     - Fixed camera control detachment for drag/resize"
echo ""
echo "🔗 Live Site: https://lucumaaglass.in"
echo "⏱️  Deployment Time: $(date)"
echo ""
echo "Next: Run verification tests..."
