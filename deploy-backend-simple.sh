#!/bin/bash
# Simple backend deployment script
# This will prompt for your VPS password

echo "🚀 Deploying updated backend to lucumaaglass.in..."
echo ""
echo "This will:"
echo "  1. Upload the updated backend files"
echo "  2. Restart the backend service"
echo ""
echo "You'll be prompted for your VPS root password a few times."
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."

VPS_IP="147.79.104.84"
VPS_USER="root"
BACKEND_PATH="/root/glass-deploy-20260107-190639/backend"

# Upload server.py
echo ""
echo "📤 Step 1/3: Uploading server.py..."
scp backend/server.py "$VPS_USER@$VPS_IP:$BACKEND_PATH/server.py"

if [ $? -ne 0 ]; then
    echo "❌ Upload failed. Check your VPS password."
    exit 1
fi

# Upload orders_router.py
echo ""
echo "📤 Step 2/3: Uploading orders_router.py..."
scp backend/routers/orders_router.py "$VPS_USER@$VPS_IP:$BACKEND_PATH/routers/orders_router.py"

if [ $? -ne 0 ]; then
    echo "❌ Upload failed."
    exit 1
fi

# Restart backend service
echo ""
echo "🔄 Step 3/3: Restarting backend service..."
ssh "$VPS_USER@$VPS_IP" << 'ENDSSH'
# Kill existing processes
pkill -f "uvicorn.*server:app"
sleep 3
# Start backend
cd /root/glass-deploy-20260107-190639/backend
nohup ./venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8000 > /var/log/lucumaa-backend.log 2>&1 &
sleep 2
# Check if running
if pgrep -f "uvicorn.*server:app" > /dev/null; then
    echo "✅ Backend restarted successfully!"
else
    echo "⚠️  Backend may not have started. Check logs."
fi
ENDSSH

if [ $? -ne 0 ]; then
    echo "⚠️  Service restart may have failed. Check manually: ssh root@$VPS_IP"
    exit 1
fi

echo ""
echo "✅ ✅ ✅ SUCCESS! ✅ ✅ ✅"
echo ""
echo "Backend has been updated!"
echo ""
echo "What was fixed:"
echo "  ✓ Design PDF generation now works properly"
echo "  ✓ Order tracking improved with case-insensitive search"
echo "  ✓ Better error handling for all endpoints"
echo ""
echo "🌐 Test the fixes:"
echo "  - Design PDF: https://lucumaaglass.in/portal"
echo "  - Order Tracking: https://lucumaaglass.in/track"
echo "  - ERP Orders: https://lucumaaglass.in/erp/orders"
echo ""
