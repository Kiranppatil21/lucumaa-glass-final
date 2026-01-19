#!/usr/bin/env bash
set -euo pipefail

# Deploys backend to lucumaa VPS
# Assumes backend is deployed to /root/glass-deploy-*/backend

VPS_HOST="${VPS_HOST:-root@147.79.104.84}"
REMOTE_BACKEND_DIR="${REMOTE_BACKEND_DIR:-/root/glass-deploy-20260107-190639/backend}"

echo "📦 Packaging backend files..."
# Create tarball excluding venv, __pycache__, etc
tar -czf /tmp/backend-deploy.tar.gz \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='venv' \
  --exclude='.pytest_cache' \
  --exclude='uploads/*' \
  -C backend \
  .

echo "📤 Uploading backend to $VPS_HOST:$REMOTE_BACKEND_DIR ..."
scp /tmp/backend-deploy.tar.gz "$VPS_HOST:/tmp/"

echo "🚀 Deploying backend on VPS..."
ssh "$VPS_HOST" "bash -lc 'set -e
  cd \"$REMOTE_BACKEND_DIR\"
  
  # Extract new files
  tar -xzf /tmp/backend-deploy.tar.gz
  rm /tmp/backend-deploy.tar.gz
  
  # Ensure virtual environment exists
  if [ ! -d venv ]; then
    python3.11 -m venv venv || python3 -m venv venv
  fi
  
  # Update dependencies
  source venv/bin/activate
  pip install --upgrade pip -q
  pip install -r requirements.txt -q
  
  # Restart backend service (try PM2 and systemd)
  pm2 restart glass-backend 2>/dev/null || true
  systemctl restart glass-backend 2>/dev/null || true
  
  # If neither exists, restart uvicorn directly
  if ! pm2 list 2>/dev/null | grep -q glass-backend && ! systemctl is-active glass-backend 2>/dev/null; then
    pkill -f \"uvicorn server:app\" || true
    nohup venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
  fi
  
  sleep 3
  
  # Check if backend is responding
  if curl -s -f http://localhost:8000/health > /dev/null; then
    echo \"✅ Backend deployed and running\"
  else
    echo \"⚠️  Backend deployed but health check failed - check logs\"
    exit 1
  fi
'"

rm /tmp/backend-deploy.tar.gz
echo "✅ Backend deployment complete!"
