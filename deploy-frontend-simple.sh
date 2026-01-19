#!/bin/bash
# Simple frontend deployment script
# This will prompt for your VPS password

echo "🚀 Deploying updated frontend to lucumaaglass.in..."
echo ""
echo "This will:"
echo "  1. Upload the updated build to your VPS"
echo "  2. Extract it to /var/www/lucumaa/frontend/build"
echo "  3. Reload nginx to show the changes"
echo ""
echo "You'll be prompted for your VPS root password a few times."
echo ""
read -p "Press ENTER to continue or Ctrl+C to cancel..."

VPS_IP="147.79.104.84"
VPS_USER="root"
LOCAL_PACKAGE="$HOME/Desktop/lucumaa-frontend-update.tar.gz"

# Upload the package
echo ""
echo "📤 Step 1/3: Uploading package..."
scp "$LOCAL_PACKAGE" "$VPS_USER@$VPS_IP:/tmp/frontend-update.tar.gz"

if [ $? -ne 0 ]; then
    echo "❌ Upload failed. Check your VPS password and internet connection."
    exit 1
fi

# Extract and deploy
echo ""
echo "📦 Step 2/3: Extracting on server..."
ssh -t "$VPS_USER@$VPS_IP" "cd /var/www/lucumaa/frontend && ([ -d build ] && mv build build.backup.\$(date +%Y%m%d_%H%M%S) || true) && tar -xzf /tmp/frontend-update.tar.gz
# Set permissions
# Extract and deploy
echo ""
echo "📦 Step 2/3: Extracting on server..."
ssh -t "$VPS_USER@$VPS_IP" 'cd /var/www/lucumaa/frontend && if [ -d build ]; then mv build build.backup.$(date +%Y%m%d_%H%M%S); fi && tar -xzf /tmp/frontend-update.tar.gz && chown -R www-data:www-data build 2>/dev/null || chown -R nginx:nginx build && chmod -R 755 build && rm -f /tmp/frontend-update.tar.gz && echo "Files deployed successfully"'

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed on server."
    exit 1
fi

# Reload nginx
echo ""
echo "🔄 Step 3/3: Reloading nginx..."
ssh -t "$VPS_USER@$VPS_IP" "systemctl reload nginx || service nginx reload"

if [ $? -ne 0 ]; then
    echo "⚠️  Nginx reload failed, but files are deployed. Try: ssh root@$VPS_IP 'systemctl reload nginx'"
    exit 1
fi

echo ""
echo "✅ ✅ ✅ SUCCESS! ✅ ✅ ✅"
echo ""
echo "Your website has been updated!"
echo "Changes are now live at: https://lucumaaglass.in"
echo ""
echo "What changed:"
echo "  ✓ Job Work page now has modern design matching Customize page"
echo "  ✓ Track Order page improved with better error handling"
echo "  ✓ Portal now shows Design PDF download button for all orders"
echo ""
echo "🌐 Visit https://lucumaaglass.in/job-work to see the new design!"
echo ""
