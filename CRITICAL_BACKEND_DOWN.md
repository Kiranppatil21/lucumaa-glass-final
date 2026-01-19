# 🚨 CRITICAL: Backend Service Not Running (502 Bad Gateway)

## Issue Discovered
All endpoints are returning **502 Bad Gateway** which means:
- ❌ Backend service is not running
- ❌ OR backend crashed on startup
- ❌ OR nginx can't connect to backend on port 8000

## Immediate Actions Needed

### Step 1: SSH into VPS and Check Backend Status

```bash
ssh root@147.79.104.84

# Check if backend process is running
pm2 status
# OR
ps aux | grep uvicorn

# Check systemd service
systemctl status glass-backend
```

### Step 2: Check Backend Logs for Errors

```bash
# PM2 logs
pm2 logs glass-backend --lines 50

# OR check log file
tail -50 /tmp/backend.log

# OR systemd logs
journalctl -u glass-backend -n 50
```

### Step 3: Common Issues and Fixes

#### Issue A: Backend Not Started
```bash
cd /root/glass-deploy-20260107-190639/backend
source venv/bin/activate

# Start with PM2
pm2 start venv/bin/uvicorn --name glass-backend -- server:app --host 0.0.0.0 --port 8000
pm2 save

# OR start with nohup
nohup venv/bin/uvicorn server:app --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
```

#### Issue B: Import Error or Syntax Error
```bash
cd /root/glass-deploy-20260107-190639/backend
source venv/bin/activate

# Test if server can start
python3 -c "import server; print('Server module loaded OK')"

# If errors, check what's missing
pip install -r requirements.txt
```

#### Issue C: MongoDB Connection Error
```bash
# Check MongoDB is running
systemctl status mongod

# If not running, start it
systemctl start mongod

# Check MongoDB can connect
mongo --eval "db.runCommand({ping: 1})"
```

#### Issue D: Port 8000 Already in Use
```bash
# Kill any process on port 8000
lsof -ti:8000 | xargs kill -9

# Then restart backend
pm2 restart glass-backend
```

### Step 4: Manual Backend Start (For Testing)

```bash
cd /root/glass-deploy-20260107-190639/backend
source venv/bin/activate

# Set SMTP environment variables
export SMTP_HOST=smtp.hostinger.com
export SMTP_PORT=465
export SMTP_USER=info@lucumaaglass.in
export SMTP_PASSWORD="Info123@@123"

# Start uvicorn directly to see errors
uvicorn server:app --host 0.0.0.0 --port 8000
# Press Ctrl+C to stop, then read error messages
```

### Step 5: Verify nginx Configuration

```bash
# Check nginx config for backend proxy
cat /etc/nginx/sites-available/glass-erp
# OR
cat /etc/nginx/sites-available/lucumaaglass.in

# Look for:
# location /api {
#     proxy_pass http://localhost:8000;
# }

# Test nginx config
nginx -t

# Restart nginx if needed
systemctl restart nginx
```

### Step 6: Full Backend Restart Procedure

```bash
cd /root/glass-deploy-20260107-190639/backend

# 1. Stop everything
pkill -f "uvicorn server:app" || true
pm2 delete glass-backend 2>/dev/null || true
sleep 2

# 2. Check MongoDB
systemctl status mongod || systemctl start mongod

# 3. Activate venv
source venv/bin/activate

# 4. Update dependencies (in case something is missing)
pip install -r requirements.txt -q

# 5. Set SMTP environment variables
export SMTP_HOST=smtp.hostinger.com
export SMTP_PORT=465
export SMTP_USER=info@lucumaaglass.in
export SMTP_PASSWORD="Info123@@123"

# 6. Start backend
pm2 start venv/bin/uvicorn --name glass-backend -- server:app --host 0.0.0.0 --port 8000
pm2 save

# 7. Wait and check
sleep 3
curl http://localhost:8000/health

# 8. Check from outside
curl https://lucumaaglass.in/api/health
```

## Diagnostic Commands

### Check All Services
```bash
# Backend
pm2 status
systemctl status glass-backend

# MongoDB
systemctl status mongod

# Nginx
systemctl status nginx

# Port 8000
netstat -tlnp | grep 8000
# OR
lsof -i :8000
```

### View Logs
```bash
# Backend logs (last 100 lines)
pm2 logs glass-backend --lines 100

# Nginx error log
tail -50 /var/log/nginx/error.log

# MongoDB log
tail -50 /var/log/mongodb/mongod.log
```

### Test Backend Directly
```bash
# From VPS
curl http://localhost:8000/health
curl http://localhost:8000/api/health

# From outside
curl https://lucumaaglass.in/api/health
```

## Likely Causes of 502 Error

1. **Backend not running** - Most common
   - Solution: Start backend with PM2 or uvicorn
   
2. **Backend crashed on startup** - Import or syntax error
   - Solution: Check logs, fix imports, reinstall dependencies
   
3. **MongoDB not running** - Backend can't connect to database
   - Solution: `systemctl start mongod`
   
4. **Port 8000 blocked or in use**
   - Solution: Kill process on port 8000, restart backend
   
5. **nginx can't proxy to backend**
   - Solution: Check nginx config, restart nginx
   
6. **Environment variable issues** - Missing JWT_SECRET, MONGO_URI, etc.
   - Solution: Set environment variables before starting

## Quick Fix Script (Run on VPS)

```bash
#!/usr/bin/env bash
set -e

echo "🔧 Fixing Backend Service..."

# Go to backend directory
cd /root/glass-deploy-20260107-190639/backend

# Kill existing processes
pkill -f "uvicorn server:app" || true
pm2 delete glass-backend 2>/dev/null || true

# Start MongoDB
systemctl start mongod

# Activate venv
source venv/bin/activate

# Set environment variables
export SMTP_HOST=smtp.hostinger.com
export SMTP_PORT=465
export SMTP_USER=info@lucumaaglass.in
export SMTP_PASSWORD="Info123@@123"

# Start backend
pm2 start venv/bin/uvicorn --name glass-backend -- server:app --host 0.0.0.0 --port 8000
pm2 save

# Wait
sleep 5

# Test
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ Backend is running!"
    pm2 status
else
    echo "❌ Backend failed to start. Check logs:"
    pm2 logs glass-backend --lines 30
fi
```

Save this as `fix-backend.sh` on the VPS and run: `bash fix-backend.sh`

## After Backend is Running

Once backend is up and running (health check returns 200), test endpoints again:
```bash
./test-endpoints.sh
```

All tests should pass:
- ✅ Health checks (200)
- ✅ Auth endpoints (422 for empty body = endpoint exists)
- ✅ Order tracking (404 for non-existent order = endpoint exists)
- ✅ Job work labour rates (200)
- ✅ Glass configurator pricing (200)

## Contact for Help

If backend still won't start after all troubleshooting:
1. Share the output of `pm2 logs glass-backend --lines 100`
2. Share the output of `systemctl status mongod`
3. Share any error messages from the logs
4. Check if there are permission issues: `ls -la /root/glass-deploy-20260107-190639/backend`

---

**Status: CRITICAL - Backend service must be started before testing any features!**
