#!/bin/bash

# Configuration
VPS_IP="147.79.104.84"
DOMAIN="lucumaaglass.in"

echo "🚀 Starting Login Fix for $DOMAIN ($VPS_IP)..."
echo "This will rebuild the frontend with the correct API URL."

ssh root@$VPS_IP << 'ENDSSH'
set -e

# 1. Locate Frontend Directory
echo "🔍 Locating frontend source..."
# Try common paths based on your documentation
if [ -d "/home/glassadmin/Glass/frontend" ]; then
    PROJECT_DIR="/home/glassadmin/Glass/frontend"
elif [ -d "/var/www/glass/frontend" ]; then
    PROJECT_DIR="/var/www/glass/frontend"
elif [ -d "/var/www/glass-erp/frontend" ]; then
    PROJECT_DIR="/var/www/glass-erp/frontend"
else
    # Fallback to finding the latest deploy folder in root
    PROJECT_DIR=$(find /root -maxdepth 2 -type d -name "frontend" | head -n 1)
fi

if [ -z "$PROJECT_DIR" ]; then
    echo "❌ Could not find frontend directory. Please check path manually."
    exit 1
fi

echo "📂 Found frontend at: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 2. Set Environment Variables
echo "🔧 Configuring environment variables..."
# Ensure the backend URL is set to the domain, not localhost
echo "REACT_APP_BACKEND_URL=https://lucumaaglass.in" > .env
echo "REACT_APP_BACKEND_URL=https://lucumaaglass.in" > .env.production
echo "GENERATE_SOURCEMAP=false" >> .env.production

# 3. Install & Build
echo "📦 Installing dependencies..."
npm install --legacy-peer-deps

echo "🏗️ Building frontend (this may take a few minutes)..."
export REACT_APP_BACKEND_URL=https://lucumaaglass.in
npm run build

# 4. Deploy
echo "🚀 Deploying to web server..."

# Option A: If using Nginx to serve static files directly (Standard)
if [ -d "/var/www/html" ]; then
    echo "   -> Copying to /var/www/html/"
    rm -rf /var/www/html/*
    cp -r build/* /var/www/html/
fi

# Option B: If using PM2 to serve the build (Node serve)
echo "   -> Restarting PM2 services"
pm2 restart all || echo "PM2 not running, skipping restart"

# 5. Reload Nginx (if running)
systemctl reload nginx || echo "Nginx not running or reload failed"

echo "✅ Login fix applied! Please clear your browser cache and test."
ENDSSH