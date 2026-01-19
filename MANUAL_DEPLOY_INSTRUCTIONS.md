# Manual Deployment Instructions

## Changes Made
Updated `backend/routers/glass_configurator.py` to make PDF fit on 1 page:
- Reduced drawing dimensions
- Limited cutout display to 8 items
- Optimized spacing

## Deploy Backend Changes

### Option 1: Using the deployment script (requires password)
```bash
cd /Users/admin/Desktop/Glass
./deploy-backend-lucumaa-vps.sh
# Enter VPS password when prompted
```

### Option 2: Manual deployment steps
```bash
# 1. Package backend files
cd /Users/admin/Desktop/Glass
tar -czf /tmp/backend-deploy.tar.gz \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='venv' \
  -C backend .

# 2. Copy to VPS (enter password when prompted)
scp /tmp/backend-deploy.tar.gz root@147.79.104.84:/tmp/

# 3. SSH into VPS and deploy
ssh root@147.79.104.84

# On VPS, run:
cd /root/glass-deploy-20260107-190639/backend
tar -xzf /tmp/backend-deploy.tar.gz
rm /tmp/backend-deploy.tar.gz
source venv/bin/activate
pip install -r requirements.txt -q
pm2 restart glass-backend || systemctl restart glass-backend
exit
```

### Option 3: Deploy only the changed file
```bash
# Copy just the updated file
scp backend/routers/glass_configurator.py root@147.79.104.84:/root/glass-deploy-20260107-190639/backend/routers/

# SSH and restart
ssh root@147.79.104.84 "pm2 restart glass-backend || systemctl restart glass-backend"
```

## Verify Deployment
After deployment, test PDF export:
1. Go to https://lucumaaglass.in
2. Login to Glass Configurator 3D
3. Add some cutouts
4. Click "Export PDF"
5. Verify PDF fits on 1 page

## Files Changed
- `backend/routers/glass_configurator.py` - PDF generation optimization
