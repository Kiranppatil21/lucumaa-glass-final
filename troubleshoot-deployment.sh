#!/bin/bash

##############################################################################
# MANUAL DEPLOYMENT - When SSH keys don't work
# Use this when facing SSH key issues
##############################################################################

echo "🔧 DEPLOYMENT TROUBLESHOOTING SCRIPT"
echo "===================================="
echo ""

# Try different SSH approaches
echo "Attempt 1: Standard SSH with original IP..."
ssh -o ConnectTimeout=3 lucumaa@103.145.45.65 "echo 'Success'" 2>&1 | grep -q "Success" && {
    echo "✅ Connected to original IP"
    echo "Run: ./deploy-to-vps-now.sh"
    exit 0
}

echo "❌ Original IP not responding"
echo ""

echo "Attempt 2: SSH to domain lucumaaglass.in..."
ssh -o ConnectTimeout=3 lucumaa@lucumaaglass.in "echo 'Success'" 2>&1 | grep -q "Success" && {
    echo "✅ Connected to domain"
    echo "Run: ssh lucumaa@lucumaaglass.in 'cd /app/glass && bash' and manually deploy"
    exit 0
}

echo "❌ Domain connection failed (needs password or key issue)"
echo ""

echo "⚠️  SSH Connection Issues:"
echo "  1. VPS may be temporarily down"
echo "  2. SSH keys may have changed"
echo "  3. Network connectivity issue"
echo ""

echo "📝 Manual Deployment Steps:"
echo "  1. Contact hosting provider (Hostinger)"
echo "  2. SSH into VPS using their terminal"
echo "  3. Run these commands:"
echo ""
echo "    cd /app/glass"
echo "    git pull origin main  # OR manually upload files"
echo "    cd frontend && npm run build && cd .."
echo "    pkill -f 'python.*server.py'"
echo "    sleep 2"
echo "    nohup python backend/server.py > backend.log 2>&1 &"
echo "    sleep 3"
echo "    sudo systemctl reload nginx"
echo ""

echo "📋 Files to Upload (if manual):"
echo "  - backend/routers/glass_configurator.py"
echo "  - frontend/src/utils/ShapeGenerator.js"
echo "  - frontend/src/pages/JobWork3DConfigurator.js"
echo "  - frontend/build/* (entire build directory)"
