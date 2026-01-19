#!/bin/bash

# ============================================
# Glass ERP - Domain Configuration Script
# Configure lucumaaglass.in domain
# ============================================

cat << 'EOF'

🌐 Glass ERP - Domain Configuration Guide
==========================================

STEP 1: Point Your Domain to VPS
---------------------------------

1. Login to your domain registrar (where you bought lucumaaglass.in)
2. Go to DNS Management / DNS Settings
3. Add/Update these DNS records:

   Type   | Name  | Value           | TTL
   -------|-------|-----------------|-------
   A      | @     | 147.79.104.84   | 3600
   A      | www   | 147.79.104.84   | 3600

4. Save changes (DNS propagation takes 5-30 minutes)

5. Verify DNS is working:
   ping lucumaaglass.in
   ping www.lucumaaglass.in


STEP 2: Update VPS Configuration
----------------------------------

SSH to your VPS and run these commands:

ssh root@147.79.104.84

# 1. Update Backend CORS Settings
cd /root/glass-deploy-20260107-190639/backend
nano .env

# Update this line:
ALLOWED_ORIGINS=http://lucumaaglass.in,https://lucumaaglass.in,http://www.lucumaaglass.in,https://www.lucumaaglass.in,http://147.79.104.84

# Save: Ctrl+X, Y, Enter

# 2. Update Frontend API URL
cd /root/glass-deploy-20260107-190639/frontend
nano .env.production

# Change to:
REACT_APP_BACKEND_URL=https://lucumaaglass.in
REACT_APP_ENVIRONMENT=production
GENERATE_SOURCEMAP=false

# Save: Ctrl+X, Y, Enter

# 3. Rebuild Frontend
npm run build
sudo cp -r build/* /var/www/glass-erp/

# 4. Update Nginx Configuration
sudo tee /etc/nginx/sites-available/glass-erp > /dev/null << 'NGINX'
server {
    listen 80;
    listen [::]:80;
    server_name lucumaaglass.in www.lucumaaglass.in 147.79.104.84;
    
    client_max_body_size 50M;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Frontend
    location / {
        root /var/www/glass-erp;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # CORS headers for frontend
        add_header Access-Control-Allow-Origin * always;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8000;
        access_log off;
    }
}
NGINX

# 5. Test and Restart Nginx
sudo nginx -t
sudo systemctl restart nginx

# 6. Restart Backend
pm2 restart glass-erp-backend
pm2 logs glass-erp-backend --lines 20

# 7. Verify
curl http://localhost:8000/health
curl http://lucumaaglass.in/health


STEP 3: Install SSL Certificate (HTTPS)
----------------------------------------

# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL Certificate (domain must be pointing to your VPS first!)
sudo certbot --nginx -d lucumaaglass.in -d www.lucumaaglass.in

# Follow prompts:
# - Enter your email
# - Agree to terms (Y)
# - Share email? (N)
# - Redirect HTTP to HTTPS? (2 - Yes)

# Certbot will automatically update Nginx configuration

# Verify SSL
curl https://lucumaaglass.in/health


STEP 4: Fix Login Error
------------------------

The login error is likely due to CORS or JWT configuration. 

# Check backend logs
pm2 logs glass-erp-backend --lines 50

# Common fixes:

# A. Update JWT Secret (if not set)
cd /root/glass-deploy-20260107-190639/backend
nano .env

# Add/Update:
JWT_SECRET=$(openssl rand -hex 32)
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# B. Verify CORS origins are correct
ALLOWED_ORIGINS=https://lucumaaglass.in,https://www.lucumaaglass.in,http://lucumaaglass.in,http://www.lucumaaglass.in

# C. Check MongoDB is running
sudo systemctl status mongod

# D. Restart backend
pm2 restart glass-erp-backend

# E. Test login from backend directly
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'


STEP 5: Verify Everything Works
--------------------------------

# Check all services
pm2 status
sudo systemctl status nginx
sudo systemctl status mongod

# Test endpoints
curl https://lucumaaglass.in
curl https://lucumaaglass.in/health
curl https://lucumaaglass.in/api/auth/me

# Check logs for errors
pm2 logs glass-erp-backend --lines 50
sudo tail -50 /var/log/nginx/error.log

# Open browser and test:
https://lucumaaglass.in


TROUBLESHOOTING LOGIN ERRORS
=============================

Error 1: CORS Error
-------------------
Symptom: Browser console shows "CORS policy" error

Fix:
cd /root/glass-deploy-20260107-190639/backend
nano .env

# Ensure this line includes your domain:
ALLOWED_ORIGINS=https://lucumaaglass.in,https://www.lucumaaglass.in,http://lucumaaglass.in,http://www.lucumaaglass.in,http://147.79.104.84

pm2 restart glass-erp-backend


Error 2: 401 Unauthorized
-------------------------
Symptom: Login returns 401 or "Invalid credentials"

Fix:
# Check if admin user exists in MongoDB
mongosh
use glass_erp_prod
db.users.findOne({username: "admin"})

# If no admin user, create one:
cd /root/glass-deploy-20260107-190639/backend
source venv/bin/activate
python seed_admin.py

pm2 restart glass-erp-backend


Error 3: Network Error / Cannot Connect
----------------------------------------
Symptom: "Network Error" or "Failed to fetch"

Fix:
# 1. Check if backend is running
pm2 status
curl http://localhost:8000/health

# 2. Check if Nginx is proxying correctly
sudo nginx -t
sudo systemctl status nginx

# 3. Check firewall
sudo ufw status

# 4. Check backend logs
pm2 logs glass-erp-backend --err --lines 50


Error 4: Frontend Shows Wrong API URL
--------------------------------------
Symptom: Browser console shows requests to wrong domain

Fix:
cd /root/glass-deploy-20260107-190639/frontend

# Check current .env.production
cat .env.production

# Should show:
# REACT_APP_BACKEND_URL=https://lucumaaglass.in

# If not, update it:
nano .env.production

# Rebuild frontend
npm run build
sudo cp -r build/* /var/www/glass-erp/

# Clear browser cache and reload


QUICK FIX COMMANDS (Run on VPS)
================================

# Complete fix for domain + login:
cd /root/glass-deploy-20260107-190639/backend && \
echo 'ALLOWED_ORIGINS=https://lucumaaglass.in,https://www.lucumaaglass.in,http://lucumaaglass.in' >> .env && \
pm2 restart glass-erp-backend && \
cd ../frontend && \
echo 'REACT_APP_BACKEND_URL=https://lucumaaglass.in' > .env.production && \
npm run build && \
sudo cp -r build/* /var/www/glass-erp/ && \
sudo systemctl restart nginx && \
echo "✅ Configuration updated!"


FINAL CHECKLIST
===============

□ DNS records pointing to 147.79.104.84
□ Backend .env has correct ALLOWED_ORIGINS
□ Frontend .env.production has correct REACT_APP_API_URL
□ Frontend rebuilt and copied to /var/www/glass-erp/
□ Nginx configuration updated with domain name
□ SSL certificate installed
□ Backend restarted with pm2
□ Nginx restarted
□ Browser cache cleared
□ Test login works

EOF
