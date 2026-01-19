# 🚀 Glass ERP - Strong VPS Production Setup

## ✅ This deployment DOES NOT affect your local running code!

Your local development environment stays completely untouched and continues running.

---

## 🎯 Deployment Strategy Overview

### Production Architecture:
```
┌─────────────────────────────────────────────────┐
│                  VPS Server                      │
│  ┌────────────────────────────────────────────┐ │
│  │  Nginx (Port 80/443)                       │ │
│  │  ├─ Frontend (Static Build)                │ │
│  │  └─ Reverse Proxy to Backend               │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │  PM2 Process Manager                       │ │
│  │  └─ Backend (FastAPI on port 8000)        │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │  MongoDB 7.0 (Local or Atlas)              │ │
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

### 1. VPS Requirements
- **Provider**: Hostinger VPS (or any Ubuntu VPS)
- **Minimum Specs**: 
  - 2 vCPU
  - 4 GB RAM
  - 50 GB SSD
  - Ubuntu 22.04 LTS
- **Network**: Public IP address

### 2. Domain (Optional but Recommended)
- Domain name pointing to VPS IP
- A record: `yourdomain.com` → `YOUR_VPS_IP`
- A record: `www.yourdomain.com` → `YOUR_VPS_IP`

### 3. On Your Mac
- SSH access to VPS
- Terminal access
- Current project running locally (don't stop it!)

---

## 🚀 Method 1: Automated Deployment (Recommended)

This is the **fastest and safest** method - takes 20 minutes total.

### Step 1: Create Production Package (On Your Mac)

```bash
# Navigate to project
cd /Users/admin/Desktop/Glass

# Make script executable
chmod +x deploy-to-vps.sh

# Edit VPS IP in script (line 11)
nano deploy-to-vps.sh
# Change: VPS_IP="YOUR_VPS_IP" to your actual IP

# Run deployment package creator
./deploy-to-vps.sh
```

**This creates a clean production package WITHOUT touching your local code!**

Output will be: `/tmp/glass-deploy-TIMESTAMP.tar.gz` (~5MB)

### Step 2: Upload to VPS

```bash
# The script will show you the exact command, example:
scp /tmp/glass-deploy-20260107-123456.tar.gz root@YOUR_VPS_IP:/root/
```

### Step 3: Setup VPS (One-time)

```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Run initial VPS setup (copy-paste all at once)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
sudo add-apt-repository ppa:deadsnakes/ppa -y && \
sudo apt update && \
sudo apt upgrade -y && \
sudo apt install -y nodejs python3.11 python3.11-venv python3-pip build-essential nginx && \
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
sudo apt update && \
sudo apt install -y mongodb-org && \
sudo systemctl start mongod && \
sudo systemctl enable mongod && \
sudo npm install -g pm2 && \
echo "✅ VPS Setup Complete!"
```

**Wait 5-10 minutes for installation to complete.**

### Step 4: Deploy Application

```bash
# Still on VPS
cd /root
tar -xzf glass-deploy-*.tar.gz
cd glass-deploy-*

# Follow the detailed instructions
cat DEPLOY_INSTRUCTIONS.md
```

The instructions will guide you through:
1. Backend setup (5 mins)
2. Frontend build (3 mins)
3. Nginx configuration (2 mins)
4. PM2 process manager (2 mins)
5. SSL setup (optional, 3 mins)

---

## 🔧 Method 2: Manual Production Setup

### Phase 1: Prepare Clean Build (Mac)

```bash
cd /Users/admin/Desktop/Glass

# Create production directory
mkdir -p ~/glass-production

# Copy backend (exclude development files)
rsync -av --exclude='__pycache__' --exclude='*.pyc' --exclude='venv' \
  backend/ ~/glass-production/backend/

# Copy frontend source
rsync -av --exclude='node_modules' --exclude='build' \
  frontend/ ~/glass-production/frontend/

# Create production .env files
cat > ~/glass-production/backend/.env << 'EOF'
ENVIRONMENT=production
DEBUG=false
MONGODB_URI=mongodb://localhost:27017/glass_erp_prod
JWT_SECRET=GENERATE_STRONG_SECRET_HERE
ALLOWED_ORIGINS=https://yourdomain.com
EOF

cat > ~/glass-production/frontend/.env.production << 'EOF'
REACT_APP_API_URL=https://yourdomain.com
REACT_APP_ENVIRONMENT=production
GENERATE_SOURCEMAP=false
EOF

# Create archive
cd ~
tar -czf glass-production.tar.gz glass-production/

# Upload to VPS
scp glass-production.tar.gz root@YOUR_VPS_IP:/root/
```

### Phase 2: VPS Initial Setup

```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Update system
apt update && apt upgrade -y

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt install -y nodejs

# Verify
node --version  # Should be v20.x
npm --version   # Should be 10.x

# Install PM2
npm install -g pm2
```

### Phase 3: Install Python 3.11

```bash
# Add Python PPA
add-apt-repository ppa:deadsnakes/ppa -y
apt update

# Install Python
apt install -y python3.11 python3.11-venv python3-pip build-essential

# Verify
python3.11 --version  # Should be 3.11.x
```

### Phase 4: Install MongoDB 7.0

```bash
# Import MongoDB key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Install
apt update
apt install -y mongodb-org

# Start MongoDB
systemctl start mongod
systemctl enable mongod

# Verify
systemctl status mongod
mongosh --eval "db.version()"  # Should show 7.0.x
```

### Phase 5: Install Nginx

```bash
# Install
apt install -y nginx

# Start
systemctl start nginx
systemctl enable nginx

# Test
curl http://localhost  # Should show Nginx welcome page
```

### Phase 6: Deploy Backend

```bash
# Extract files
cd /root
tar -xzf glass-production.tar.gz
cd glass-production/backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Configure environment
nano .env
# Update:
# - MONGODB_URI (if using remote MongoDB)
# - JWT_SECRET (generate strong secret)
# - ALLOWED_ORIGINS (your domain)

# Test backend
python -m uvicorn server:app --host 0.0.0.0 --port 8000 &
sleep 5
curl http://localhost:8000/health
# Should return: {"status":"healthy","service":"lucumaa-glass-backend"}

# Kill test process
pkill -f uvicorn
```

### Phase 7: Build Frontend

```bash
cd /root/glass-production/frontend

# Configure environment
nano .env.production
# Update REACT_APP_API_URL with your domain/IP

# Install dependencies
npm install --legacy-peer-deps

# Build for production
npm run build

# This creates optimized build/ folder
# Move to web root
mkdir -p /var/www/glass-erp
cp -r build/* /var/www/glass-erp/

# Set permissions
chown -R www-data:www-data /var/www/glass-erp
chmod -R 755 /var/www/glass-erp
```

### Phase 8: Configure Nginx

```bash
# Create site configuration
cat > /etc/nginx/sites-available/glass-erp << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name yourdomain.com www.yourdomain.com;  # Change this
    
    # Increase buffer size for large requests
    client_max_body_size 50M;
    
    # Frontend - Serve static files
    location / {
        root /var/www/glass-erp;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Backend API - Reverse proxy
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        # Forward real IP
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8000;
        access_log off;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/glass-erp /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test configuration
nginx -t

# If OK, restart Nginx
systemctl restart nginx

# Verify
systemctl status nginx
```

### Phase 9: Setup PM2 (Production Process Manager)

```bash
cd /root/glass-production/backend

# Create PM2 configuration
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'glass-erp-backend',
    script: 'venv/bin/python',
    args: ['-m', 'uvicorn', 'server:app', '--host', '0.0.0.0', '--port', '8000', '--workers', '2'],
    cwd: '/root/glass-production/backend',
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    error_file: '/var/log/glass-backend-error.log',
    out_file: '/var/log/glass-backend-out.log',
    time: true,
    env: {
      NODE_ENV: 'production',
      PYTHONUNBUFFERED: '1'
    }
  }]
};
EOF

# Start application
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
# Copy and run the command it outputs

# Check status
pm2 status
pm2 logs glass-erp-backend --lines 50
```

### Phase 10: Security Hardening

```bash
# Setup firewall
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
ufw status

# Secure MongoDB (create admin user)
mongosh << 'MONGO_EOF'
use admin
db.createUser({
  user: "glassadmin",
  pwd: "CHANGE_THIS_STRONG_PASSWORD",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" }
  ]
})
exit
MONGO_EOF

# Enable MongoDB authentication
nano /etc/mongod.conf
# Add/uncomment:
# security:
#   authorization: enabled

# Restart MongoDB
systemctl restart mongod

# Update backend/.env with authenticated MongoDB URI:
# MONGODB_URI=mongodb://glassadmin:PASSWORD@localhost:27017/glass_erp_prod?authSource=admin
```

### Phase 11: SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Follow prompts:
# - Enter email
# - Agree to terms
# - Choose redirect HTTP to HTTPS (option 2)

# Certbot will automatically:
# - Configure SSL in Nginx
# - Setup auto-renewal

# Test auto-renewal
certbot renew --dry-run

# Verify SSL
curl https://yourdomain.com
```

---

## ✅ Verification Steps

### 1. Check All Services

```bash
# MongoDB
systemctl status mongod
mongosh --eval "db.serverStatus().ok"  # Should return 1

# Nginx
systemctl status nginx
curl -I http://localhost  # Should return 200

# Backend
pm2 status  # Should show "online"
curl http://localhost:8000/health  # Should return healthy status

# Frontend
curl http://localhost  # Should return HTML
```

### 2. Test From Browser

```bash
# Get your VPS IP
curl ifconfig.me

# Visit:
# http://YOUR_VPS_IP - Should load frontend
# http://YOUR_VPS_IP/health - Should show backend health
```

### 3. Check Logs

```bash
# PM2 logs
pm2 logs glass-erp-backend --lines 100

# Nginx access log
tail -f /var/log/nginx/access.log

# Nginx error log
tail -f /var/log/nginx/error.log

# Backend logs
tail -f /var/log/glass-backend-out.log
tail -f /var/log/glass-backend-error.log
```

---

## 🔄 Update/Redeploy Process

When you need to deploy updates:

### On Your Mac:

```bash
# Create new production package
cd /Users/admin/Desktop/Glass
./deploy-to-vps.sh

# Upload to VPS
scp /tmp/glass-deploy-NEW_TIMESTAMP.tar.gz root@YOUR_VPS_IP:/root/
```

### On VPS:

```bash
# Stop current application
pm2 stop glass-erp-backend

# Backup current version
mv /root/glass-production /root/glass-production-backup-$(date +%Y%m%d)

# Extract new version
cd /root
tar -xzf glass-deploy-NEW_TIMESTAMP.tar.gz
mv glass-deploy-* glass-production

# Update backend
cd /root/glass-production/backend
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Copy .env from backup
cp /root/glass-production-backup-*/backend/.env .

# Build frontend
cd /root/glass-production/frontend
npm install --legacy-peer-deps
npm run build
cp -r build/* /var/www/glass-erp/

# Update PM2 config if needed
cd /root/glass-production/backend
pm2 delete glass-erp-backend
pm2 start ecosystem.config.js
pm2 save

# Verify
pm2 status
curl http://localhost:8000/health
```

---

## 🚨 Troubleshooting

### Backend Not Starting

```bash
# Check logs
pm2 logs glass-erp-backend --lines 100

# Try manual start to see errors
cd /root/glass-production/backend
source venv/bin/activate
python -m uvicorn server:app --reload

# Common issues:
# 1. MongoDB not running: systemctl start mongod
# 2. Wrong MongoDB URI in .env
# 3. Missing Python packages: pip install -r requirements.txt
```

### Frontend Shows Blank Page

```bash
# Check browser console (F12)
# Usually means:
# 1. REACT_APP_API_URL is wrong in .env.production
# 2. Backend not responding

# Check Nginx error log
tail -100 /var/log/nginx/error.log

# Verify frontend files
ls -la /var/www/glass-erp/
# Should have index.html and static/ folder

# Rebuild frontend
cd /root/glass-production/frontend
rm -rf build/
npm run build
cp -r build/* /var/www/glass-erp/
```

### MongoDB Connection Errors

```bash
# Check MongoDB status
systemctl status mongod

# Check MongoDB logs
tail -100 /var/log/mongodb/mongod.log

# Test connection
mongosh

# If authentication enabled, test with credentials
mongosh "mongodb://glassadmin:PASSWORD@localhost:27017/admin"

# Verify .env has correct URI
cat /root/glass-production/backend/.env | grep MONGODB_URI
```

### Nginx Configuration Error

```bash
# Test Nginx config
nginx -t

# If errors, check syntax in config file
nano /etc/nginx/sites-available/glass-erp

# View error details
journalctl -u nginx -n 100

# Restart Nginx
systemctl restart nginx
```

### PM2 Keeps Restarting

```bash
# Check error logs
pm2 logs glass-erp-backend --err --lines 200

# Check memory usage
pm2 monit

# If memory issues, increase max_memory_restart in ecosystem.config.js
```

---

## 📊 Monitoring & Maintenance

### Daily Monitoring

```bash
# Quick health check
pm2 status && systemctl status mongod && systemctl status nginx

# Disk space
df -h

# Memory usage
free -h

# CPU usage
top
```

### Weekly Maintenance

```bash
# Update system packages
apt update && apt upgrade -y

# Check logs for errors
pm2 logs glass-erp-backend --lines 500 | grep -i error

# MongoDB backup
mongodump --out=/root/backups/mongodb-$(date +%Y%m%d)

# Clean old PM2 logs
pm2 flush
```

### Monthly Tasks

```bash
# SSL certificate renewal (automatic, but verify)
certbot renew --dry-run

# Rotate logs
logrotate -f /etc/logrotate.conf

# Check disk usage
du -sh /root/glass-production/*
du -sh /var/www/glass-erp/*
```

---

## 🎉 Success Checklist

- [ ] VPS accessible via SSH
- [ ] All services installed (Node, Python, MongoDB, Nginx, PM2)
- [ ] Backend running in PM2
- [ ] Frontend built and deployed to Nginx
- [ ] MongoDB running and secured
- [ ] Nginx serving application
- [ ] Firewall configured
- [ ] SSL certificate installed (if using domain)
- [ ] Application accessible from browser
- [ ] PM2 configured for auto-restart
- [ ] Monitoring and logs working
- [ ] Backup strategy in place

---

## 🔗 Quick Commands Reference

```bash
# Start application
pm2 start ecosystem.config.js

# Stop application
pm2 stop glass-erp-backend

# Restart application
pm2 restart glass-erp-backend

# View logs
pm2 logs glass-erp-backend

# Restart Nginx
systemctl restart nginx

# Restart MongoDB
systemctl restart mongod

# Check all services
pm2 status && systemctl status mongod nginx

# Update application (after upload)
pm2 stop glass-erp-backend
cd /root/glass-production && git pull  # if using git
pm2 restart glass-erp-backend
```

---

## 📞 Need Help?

Common issues and solutions are in the TROUBLESHOOTING section above.

For persistent issues:
1. Check all logs systematically
2. Verify each service independently
3. Test connectivity at each layer
4. Review environment variables

**Remember: Your local development environment is completely separate and unaffected!**
