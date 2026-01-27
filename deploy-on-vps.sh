#!/bin/bash
# VPS Deployment Script - Run on VPS directly
set -e

echo "=========================================="
echo "Glass ERP - Deploying Fixes"
echo "=========================================="
echo ""

cd /root/glass

echo "📥 [1/5] Pulling latest code..."
git pull origin main

echo "🏗️  [2/5] Building frontend..."
cd frontend
npm install
npm run build
cd ..

echo "🔌 [3/5] Installing backend dependencies..."
cd backend
pip install -r requirements.txt
cd ..

echo "🔄 [4/5] Restarting services..."
systemctl restart glass-backend
sleep 2
systemctl restart glass-frontend || pm2 restart glass-frontend || echo "⚠️  Frontend not running via systemd"
sleep 2

echo "✅ [5/5] Verifying services..."
if systemctl is-active --quiet glass-backend; then
  echo "✅ Backend service running"
else
  echo "❌ Backend service failed"
  journalctl -u glass-backend -n 20
fi

if systemctl is-active --quiet glass-frontend; then
  echo "✅ Frontend service running"
else
  echo "⚠️  Frontend via systemd not found, checking pm2..."
  pm2 status || echo "⚠️  PM2 not configured"
fi

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Deployed Changes:"
echo "  ✅ Design PDF endpoint for job-work orders"
echo "  ✅ Design PDF download button in dashboard"
echo "  ✅ Fixed cutout reselect drag/resize bug"
echo "  ✅ Cutout data now persists with orders"
echo ""
echo "🌐 https://lucumaaglass.in"
echo ""
