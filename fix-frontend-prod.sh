#!/bin/bash
# Fix authentication issue on lucumaaglass.in by rebuilding frontend with correct API URL

set -e

echo "🔧 Fixing Frontend Authentication Issue"
echo "========================================"
echo ""

VPS_IP="147.79.104.84"
DOMAIN="lucumaaglass.in"

echo "📝 This script will:"
echo "  1. SSH to your VPS"
echo "  2. Rebuild frontend with correct REACT_APP_BACKEND_URL"
echo "  3. Deploy the fixed build"
echo "  4. Restart Nginx"
echo ""
echo "VPS IP: $VPS_IP"
echo "Domain: $DOMAIN"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# SSH and execute commands on VPS
ssh root@$VPS_IP << 'ENDSSH'
set -e

echo ""
echo "🔍 Step 1: Checking current deployment..."
cd /root/glass-deploy-*/frontend || cd /var/www/glass*/frontend || cd /root/glass/frontend

echo ""
echo "📋 Current .env file:"
cat .env 2>/dev/null || echo "No .env file found"

echo ""
echo "🔧 Step 2: Creating correct .env file..."
cat > .env << 'EOF'
REACT_APP_BACKEND_URL=https://lucumaaglass.in
GENERATE_SOURCEMAP=false
EOF

cat > .env.production << 'EOF'
REACT_APP_BACKEND_URL=https://lucumaaglass.in
GENERATE_SOURCEMAP=false
EOF

echo "✅ Environment files created"
cat .env

echo ""
echo "📦 Step 3: Installing dependencies..."
npm install --legacy-peer-deps

echo ""
echo "🏗️  Step 4: Building production frontend..."
REACT_APP_BACKEND_URL=https://lucumaaglass.in npm run build

echo ""
echo "📂 Step 5: Deploying to web directory..."
sudo rm -rf /var/www/glass-erp/*
sudo cp -r build/* /var/www/glass-erp/

echo ""
echo "🔄 Step 6: Restarting services..."
sudo systemctl reload nginx
pm2 restart all

echo ""
echo "✅ Frontend fixed and deployed!"
echo ""
echo "🧪 Testing backend API..."
curl -s http://localhost/health | head -10

echo ""
echo "🎉 Done! Try logging in now at: https://lucumaaglass.in/login"
echo ""
echo "Use these credentials:"
echo "  Email: admin@lucumaa.in"
echo "  Password: Lucumaa@@123"
echo ""
ENDSSH

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Test your site now:"
echo "   https://lucumaaglass.in/login"
echo ""
echo "🔑 Login with:"
echo "   Email: admin@lucumaa.in"
echo "   Password: Lucumaa@@123"
echo ""
