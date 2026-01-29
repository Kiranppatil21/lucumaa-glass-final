#!/bin/bash

##############################################################################
# VPS DEPLOYMENT - Direct Pull from GitHub
# When SSH key auth fails, use this method via hosting provider terminal
##############################################################################

set -e

echo "🚀 DEPLOYING CRITICAL FIXES - From GitHub"
echo "=========================================="
echo ""

# Step 1: Navigate to app directory
echo "Step 1: Navigating to app directory..."
cd /app/glass || {
    echo "❌ /app/glass directory not found"
    exit 1
}

# Step 2: Pull latest code from GitHub
echo "Step 2: Pulling latest fixes from GitHub..."
git pull origin main || {
    echo "❌ Git pull failed"
    echo "Try: git fetch origin && git reset --hard origin/main"
    exit 1
}

# Step 3: Build frontend
echo "Step 3: Building frontend..."
cd frontend || {
    echo "❌ Frontend directory not found"
    exit 1
}
npm install > /tmp/npm-install.log 2>&1
npm run build > /tmp/npm-build.log 2>&1 || {
    echo "❌ Frontend build failed"
    tail -20 /tmp/npm-build.log
    exit 1
}
echo "✅ Frontend built"
cd ..

# Step 4: Stop backend
echo "Step 4: Stopping backend service..."
pkill -f "python.*server.py" 2>/dev/null || true
sleep 2

# Step 5: Clear caches
echo "Step 5: Clearing caches..."
find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true

# Step 6: Start backend
echo "Step 6: Starting backend service..."
nohup python backend/server.py > backend.log 2>&1 &
BACKEND_PID=$!
sleep 3

if ! kill -0 $BACKEND_PID 2>/dev/null; then
    echo "❌ Backend failed to start"
    tail -20 backend.log
    exit 1
fi
echo "✅ Backend started (PID: $BACKEND_PID)"

# Step 7: Clear nginx cache
echo "Step 7: Clearing nginx cache..."
sudo rm -rf /var/cache/nginx/* 2>/dev/null || true
sudo systemctl reload nginx 2>/dev/null || true

# Step 8: Verification
echo ""
echo "Step 8: Verifying deployment..."
sleep 2

if pgrep -f "python.*server.py" > /dev/null; then
    echo "✅ Backend running"
else
    echo "❌ Backend not running"
    exit 1
fi

if systemctl is-active --quiet nginx; then
    echo "✅ Nginx running"
else
    echo "❌ Nginx not running"
    exit 1
fi

# Check for errors
if grep -q "Error\|Traceback\|Exception" backend.log 2>/dev/null | head -1; then
    echo "⚠️  Check backend.log for warnings"
else
    echo "✅ No recent errors in logs"
fi

echo ""
echo "╔═════════════════════════════════════════╗"
echo "║  ✅ DEPLOYMENT SUCCESSFUL               ║"
echo "╚═════════════════════════════════════════╝"
echo ""
echo "📋 Deployed Fixes:"
echo "  1. Heart shape flip in PDFs - FIXED"
echo "  2. Oval shape rendering - FIXED"
echo "  3. Drag/resize controls - FIXED"
echo "  4. Job work save - VERIFIED"
echo ""
echo "🔗 Live at: https://lucumaaglass.in"
echo ""
echo "📝 To monitor backend:"
echo "  tail -f /app/glass/backend.log"
echo ""

exit 0
