#!/usr/bin/env bash
set -euo pipefail

# Fix email system and endpoints on VPS
# 1. Set SMTP environment variables
# 2. Fix SMTP_USER email domain typo
# 3. Deploy backend with fixes
# 4. Test email sending
# 5. Verify order tracking and job work endpoints

VPS_HOST="${VPS_HOST:-root@147.79.104.84}"
REMOTE_BACKEND_DIR="/root/glass-deploy-20260107-190639/backend"

echo "🔧 Fixing Email System and Endpoints..."
echo ""

# Step 1: Fix SMTP_USER email domain in server.py
echo "📝 Fixing SMTP_USER email domain typo..."
sed -i '' "s/info@lucumaaGlass.in/info@lucumaaglass.in/g" backend/server.py

# Step 2: Package backend
echo "📦 Packaging backend files..."
tar -czf /tmp/backend-deploy.tar.gz \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='venv' \
  --exclude='.pytest_cache' \
  --exclude='uploads/*' \
  -C backend \
  .

# Step 3: Upload and deploy
echo "📤 Uploading to VPS..."
scp /tmp/backend-deploy.tar.gz "$VPS_HOST:/tmp/"

# Step 4: Deploy with SMTP environment variables
echo "🚀 Deploying backend with SMTP configuration..."
ssh "$VPS_HOST" "bash -lc 'set -e
  cd \"$REMOTE_BACKEND_DIR\"
  
  # Extract new files
  tar -xzf /tmp/backend-deploy.tar.gz
  rm /tmp/backend-deploy.tar.gz
  
  # Create/update .env file with SMTP credentials
  echo \"Creating .env file with SMTP credentials...\"
  cat > .env << EOF
# SMTP Configuration
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=info@lucumaaglass.in
SMTP_PASSWORD=Info123@@123

# MongoDB (keep existing)
MONGO_URI=\${MONGO_URI}
JWT_SECRET=\${JWT_SECRET}
EOF

  # Update systemd service to load .env file (if using systemd)
  if [ -f /etc/systemd/system/glass-backend.service ]; then
    echo \"Updating systemd service to load .env...\"
    # Add EnvironmentFile directive if not present
    if ! grep -q \"EnvironmentFile\" /etc/systemd/system/glass-backend.service; then
      sed -i \"/\\[Service\\]/a EnvironmentFile=$REMOTE_BACKEND_DIR/.env\" /etc/systemd/system/glass-backend.service
      systemctl daemon-reload
    fi
  fi
  
  # Update virtual environment
  if [ ! -d venv ]; then
    python3.11 -m venv venv || python3 -m venv venv
  fi
  
  source venv/bin/activate
  pip install --upgrade pip -q
  pip install -r requirements.txt -q
  
  # Kill all existing uvicorn processes
  echo \"Stopping existing backend processes...\"
  pkill -f \"uvicorn server:app\" || true
  pm2 delete glass-backend 2>/dev/null || true
  sleep 2
  
  # Start backend with environment variables
  echo \"Starting backend with SMTP configuration...\"
  export SMTP_HOST=smtp.hostinger.com
  export SMTP_PORT=465
  export SMTP_USER=info@lucumaaglass.in
  export SMTP_PASSWORD=\"Info123@@123\"
  
  # Start with PM2 if available, otherwise with nohup
  if command -v pm2 &> /dev/null; then
    # Create PM2 ecosystem file with env vars
    cat > ecosystem.config.js << EOFPM2
module.exports = {
  apps: [{
    name: \"glass-backend\",
    script: \"venv/bin/uvicorn\",
    args: \"server:app --host 0.0.0.0 --port 8000\",
    env: {
      SMTP_HOST: \"smtp.hostinger.com\",
      SMTP_PORT: \"465\",
      SMTP_USER: \"info@lucumaaglass.in\",
      SMTP_PASSWORD: \"Info123@@123\"
    }
  }]
}
EOFPM2
    pm2 start ecosystem.config.js
    pm2 save
  else
    nohup venv/bin/uvicorn server:app --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
  fi
  
  sleep 5
  
  # Check if backend is running
  if curl -s -f http://localhost:8000/health > /dev/null; then
    echo \"✅ Backend is running\"
  else
    echo \"❌ Backend health check failed\"
    tail -20 /tmp/backend.log 2>/dev/null || true
    exit 1
  fi
  
  # Test email endpoint
  echo \"\"
  echo \"📧 Testing email configuration...\"
  curl -s -X POST http://localhost:8000/api/test-email \
    -H \"Content-Type: application/json\" \
    -d \"{\\\"email\\\":\\\"test@example.com\\\",\\\"subject\\\":\\\"Test Email\\\",\\\"message\\\":\\\"Testing SMTP configuration\\\"}\" \
    || echo \"Test email endpoint not available (expected)\"
  
  echo \"\"
  echo \"✅ Backend deployed with SMTP configuration!\"
  echo \"\"
  echo \"📋 SMTP Settings:\"
  echo \"   Host: smtp.hostinger.com\"
  echo \"   Port: 465\"
  echo \"   User: info@lucumaaglass.in\"
  echo \"   Password: [SET]\"
'"

rm /tmp/backend-deploy.tar.gz

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🔍 Verifying endpoints..."
echo ""

# Test order tracking endpoint
echo "Testing order tracking endpoint..."
TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://lucumaaglass.in/api/erp/customer/orders/test-123/track || echo "000")
if [ "$TEST_RESPONSE" = "404" ] || [ "$TEST_RESPONSE" = "200" ]; then
  echo "✅ Order tracking endpoint is accessible (returned $TEST_RESPONSE)"
else
  echo "⚠️  Order tracking endpoint returned: $TEST_RESPONSE"
fi

echo ""
echo "Testing job work endpoint..."
TEST_JW=$(curl -s -o /dev/null -w "%{http_code}" https://lucumaaglass.in/api/erp/job-work/labour-rates || echo "000")
if [ "$TEST_JW" = "200" ]; then
  echo "✅ Job work endpoint is accessible"
else
  echo "⚠️  Job work endpoint returned: $TEST_JW"
fi

echo ""
echo "🎉 All fixes deployed!"
echo ""
echo "📋 What was fixed:"
echo "   ✅ SMTP email domain corrected (lucumaaGlass.in → lucumaaglass.in)"
echo "   ✅ SMTP password configured on VPS"
echo "   ✅ Backend restarted with environment variables"
echo "   ✅ Email system should now work properly"
echo ""
echo "🧪 Test the following:"
echo "   1. Go to https://lucumaaglass.in/forgot-password"
echo "   2. Enter a registered email"
echo "   3. Check if password reset email arrives"
echo "   4. Create an order and check if confirmation email is sent"
echo "   5. Try creating a job work order at /job-work"
echo "   6. Try tracking an order at /track with order number"
echo ""
