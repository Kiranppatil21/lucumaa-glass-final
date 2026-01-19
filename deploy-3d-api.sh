#!/bin/bash

# Deploy 3D Glass Modeling API to VPS

VPS_IP="147.79.104.84"
VPS_USER="root"
VPS_DIR="/root/glass-deploy-20260107-190639/backend"

echo "🚀 Deploying 3D Glass API to VPS..."

# Step 1: Upload glass_3d.py router
echo "📤 Uploading glass_3d.py..."
scp backend/routers/glass_3d.py ${VPS_USER}@${VPS_IP}:${VPS_DIR}/routers/

# Step 2: Update server.py to include glass_3d router (if not already added)
echo "🔧 Checking server.py..."
ssh -T ${VPS_USER}@${VPS_IP} bash <<'ENDSSH'
cd /root/glass-deploy-20260107-190639/backend

# Check if glass_3d import exists
if ! grep -q "from routers.glass_3d import router as glass_3d_router" server.py; then
    echo "Adding glass_3d router to server.py..."
    
    # Find the line with SEO router and add after it
    LINE_NUM=$(grep -n "from routers.seo import router as sitemap_router" server.py | cut -d: -f1)
    if [ ! -z "$LINE_NUM" ]; then
        sed -i "${LINE_NUM}a from routers.glass_3d import router as glass_3d_router" server.py
        
        # Add router mounting
        MOUNT_LINE=$(grep -n "app.include_router(sitemap_router" server.py | cut -d: -f1)
        if [ ! -z "$MOUNT_LINE" ]; then
            sed -i "${MOUNT_LINE}a app.include_router(glass_3d_router, prefix=\"/api\")" server.py
        fi
    fi
    echo "✅ server.py updated"
else
    echo "✅ glass_3d router already in server.py"
fi
ENDSSH

# Step 3: Update requirements.txt
echo "📦 Updating requirements.txt..."
ssh -T ${VPS_USER}@${VPS_IP} bash <<'ENDSSH'
cd /root/glass-deploy-20260107-190639/backend

# Add PyVista dependencies if not present
if ! grep -q "pyvista" requirements.txt; then
    echo "pyvista==0.44.2" >> requirements.txt
    echo "trimesh==4.5.3" >> requirements.txt
    echo "scipy==1.14.1" >> requirements.txt
    echo "✅ Added 3D modeling dependencies"
else
    echo "✅ Dependencies already present"
fi
ENDSSH

# Step 4: Install dependencies in virtualenv
echo "⏳ Installing Python packages (this may take 5-10 minutes)..."
ssh -T ${VPS_USER}@${VPS_IP} bash <<'ENDSSH'
cd /root/glass-deploy-20260107-190639/backend

# Find and use existing venv or create new one
if [ -d "venv" ]; then
    source venv/bin/activate
elif [ -d ".venv" ]; then
    source .venv/bin/activate
else
    python3 -m venv venv
    source venv/bin/activate
fi

pip install pyvista==0.44.2 trimesh==4.5.3 scipy==1.14.1 2>&1 | tail -30
echo "✅ Packages installed"
ENDSSH

# Step 5: Restart backend
echo "♻️  Restarting backend..."
ssh -T ${VPS_USER}@${VPS_IP} bash <<'ENDSSH'
pm2 restart glass-erp-backend
sleep 3
pm2 logs glass-erp-backend --lines 20 --nostream
ENDSSH

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "Test the API:"
echo "  curl https://lucumaaglass.in/api/glass-3d/formats"
echo ""
echo "Generate 3D model:"
echo '  curl -X POST https://lucumaaglass.in/api/glass-3d/generate \\'
echo '    -H "Content-Type: application/json" \\'
echo "    -d '{\"width\":1000,\"height\":800,\"thickness\":10,\"cutouts\":[{\"shape\":\"circle\",\"x\":500,\"y\":400,\"diameter\":100}],\"export_format\":\"stl\"}'"
