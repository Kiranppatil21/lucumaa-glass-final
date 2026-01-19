# 🔧 Fix Login Authentication Issue on VPS

## Problem
Backend API works perfectly (tested with curl), but frontend login shows "authentication error"

## Root Cause
Frontend build has wrong `REACT_APP_BACKEND_URL` or is missing the environment variable

## ✅ Solution - Run these commands on your VPS

**Automated Method:**
Run the helper script from your local machine:
```bash
chmod +x solve_login_issue.sh
./solve_login_issue.sh
```

**Manual Method:**
```bash
# SSH to your VPS
ssh root@YOUR_VPS_IP

# Step 1: Check current frontend .env
cd /var/www/glass/frontend  # or wherever frontend is deployed
cat .env
cat .env.production

# Step 2: Fix .env file
nano .env
# Make sure it has:
# REACT_APP_BACKEND_URL=https://lucumaaglass.in

# OR create if missing:
echo "REACT_APP_BACKEND_URL=https://lucumaaglass.in" > .env
echo "REACT_APP_BACKEND_URL=https://lucumaaglass.in" > .env.production

# Step 3: Rebuild frontend with correct API URL
npm install
REACT_APP_BACKEND_URL=https://lucumaaglass.in npm run build

# Step 4: Copy build to nginx directory
sudo rm -rf /var/www/html/*   # If serving static files via Nginx
sudo cp -r build/* /var/www/html/

# Step 5: Reload nginx
sudo systemctl reload nginx

# Step 6: Clear browser cache and test
# Open in incognito: https://lucumaaglass.in/login
```

## Alternative: Check Nginx Proxy Configuration

If frontend is served by Nginx and API calls go to `/api/`, check nginx config:

```bash
# Check nginx config
sudo cat /etc/nginx/sites-enabled/default | grep -A 20 "location /api"

# Should have proxy_pass to backend:
# location /api/ {
#     proxy_pass http://127.0.0.1:8000/api/;
#     proxy_set_header Host $host;
#     proxy_set_header X-Real-IP $remote_addr;
# }

# If missing or wrong, edit:
sudo nano /etc/nginx/sites-available/default

# Add/fix the location block, then:
sudo nginx -t
sudo systemctl reload nginx
```

## Quick Test After Fix

```bash
# From your Mac, test the exact login flow:
curl -X POST https://lucumaaglass.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@lucumaaglass.in","password":"Admin@2026"}'

# Should return: {"message":"Login successful","token":"..."}
```

## If Still Not Working - Check Browser Console

1. Open https://lucumaaglass.in/login in Chrome/Firefox
2. Press F12 (Developer Tools)
3. Go to Console tab
4. Try to login
5. Look for:
   - Red error messages
   - Network tab → look for the `/api/auth/login` request
   - Check if request URL is correct
   - Check response status and body

Common issues:
- ❌ Request goes to `http://localhost:8000` instead of `https://lucumaaglass.in`
- ❌ Request goes to `/api/auth/login` but nginx doesn't proxy it to backend
- ❌ CORS error (backend not allowing frontend domain)
- ❌ Network error (backend not running)

## Create Admin User (if needed)

```bash
# Run on VPS or from Mac:
curl -X POST https://lucumaaglass.in/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"admin@lucumaaglass.in",
    "password":"Admin@2026",
    "name":"Admin User",
    "phone":"+919284701985",
    "role":"admin"
  }'
```

## Verify Backend is Running

```bash
ssh root@YOUR_VPS_IP

# Check backend service
sudo systemctl status glass-backend

# Check logs
sudo journalctl -u glass-backend -n 50 -f

# If not running, start it:
sudo systemctl start glass-backend
```
