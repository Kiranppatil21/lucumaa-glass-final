#!/bin/bash

# ============================================
# Glass ERP - Production VPS Deployment Script
# ============================================
# This script creates a clean production build WITHOUT affecting local dev environment

set -e  # Exit on error

echo "🚀 Glass ERP - Production Deployment Package Creator"
echo "=================================================="
echo ""

# Configuration
VPS_IP="YOUR_VPS_IP"  # Change this to your VPS IP
VPS_USER="root"       # Change to your VPS username
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
DEPLOY_DIR="/tmp/glass-deploy-${TIMESTAMP}"
PROJECT_DIR="/Users/admin/Desktop/Glass"

echo "📦 Step 1: Creating clean deployment package..."
echo "   (Your local code remains untouched)"
echo ""

# Create temporary deployment directory
mkdir -p "$DEPLOY_DIR"

# Copy only necessary files (excluding node_modules, venv, etc.)
echo "   Copying backend files..."
rsync -av --exclude='__pycache__' \
          --exclude='*.pyc' \
          --exclude='.pytest_cache' \
          --exclude='venv' \
          "$PROJECT_DIR/backend/" "$DEPLOY_DIR/backend/"

echo "   Copying frontend source..."
rsync -av --exclude='node_modules' \
          --exclude='build' \
          --exclude='.cache' \
          "$PROJECT_DIR/frontend/" "$DEPLOY_DIR/frontend/"

# Copy root files
echo "   Copying configuration files..."
cp "$PROJECT_DIR/README.md" "$DEPLOY_DIR/" 2>/dev/null || true

# Create production environment files
echo ""
echo "📝 Step 2: Creating production environment files..."

# Backend .env for production
cat > "$DEPLOY_DIR/backend/.env" << 'EOF'
# Production Environment Variables
ENVIRONMENT=production
DEBUG=false

# MongoDB - Use MongoDB Atlas for production
MONGODB_URI=mongodb://localhost:27017/glass_erp_prod

# JWT Secret - Generate strong secret
JWT_SECRET=CHANGE_THIS_TO_STRONG_SECRET_KEY
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS - Update with your domain
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com

# Email Configuration (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Razorpay (optional)
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_SECRET=your_razorpay_secret
EOF

# Frontend .env for production
cat > "$DEPLOY_DIR/frontend/.env.production" << 'EOF'
REACT_APP_API_URL=https://api.yourdomain.com
REACT_APP_ENVIRONMENT=production
GENERATE_SOURCEMAP=false
EOF

# Create deployment instructions
cat > "$DEPLOY_DIR/DEPLOY_INSTRUCTIONS.md" << 'EOF'
# Glass ERP - VPS Deployment Instructions

## 🎯 Quick Deploy Commands

### 1. Upload to VPS
```bash
# From your Mac, run:
scp -r glass-deploy-* root@YOUR_VPS_IP:/root/
```

### 2. On VPS - Install System Dependencies
```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Update system
apt update && apt upgrade -y

# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt install -y nodejs

# Install Python 3.11
add-apt-repository ppa:deadsnakes/ppa -y
apt update
apt install -y python3.11 python3.11-venv python3-pip build-essential

# Install MongoDB 7.0
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod

# Install Nginx
apt install -y nginx
systemctl start nginx
systemctl enable nginx

# Install PM2
npm install -g pm2
```

### 3. Deploy Application
```bash
cd /root/glass-deploy-*

# Setup Backend
cd backend
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Edit .env file with your settings
nano .env
# Update: MONGODB_URI, JWT_SECRET, ALLOWED_ORIGINS

# Test backend
python -m uvicorn server:app --host 0.0.0.0 --port 8000 &
curl http://localhost:8000/health
# Should return: {"status":"healthy"}

# Setup Frontend
cd ../frontend

# Edit environment
nano .env.production
# Update: REACT_APP_API_URL with your domain

# Install dependencies
npm install --legacy-peer-deps

# Build production
npm run build
# This creates optimized build/ folder

# Move build to Nginx
mkdir -p /var/www/glass-erp
cp -r build/* /var/www/glass-erp/
```

### 4. Configure Nginx
```bash
# Create Nginx config
cat > /etc/nginx/sites-available/glass-erp << 'NGINX_EOF'
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Frontend
    location / {
        root /var/www/glass-erp;
        index index.html;
        try_files $uri $uri/ /index.html;
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
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8000;
    }
}
NGINX_EOF

# Enable site
ln -s /etc/nginx/sites-available/glass-erp /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# Test Nginx config
nginx -t

# Restart Nginx
systemctl restart nginx
```

### 5. Setup PM2 (Process Manager)
```bash
cd /root/glass-deploy-*/backend

# Create PM2 ecosystem file
cat > ecosystem.config.js << 'PM2_EOF'
module.exports = {
  apps: [{
    name: 'glass-erp-backend',
    script: 'venv/bin/python',
    args: '-m uvicorn server:app --host 0.0.0.0 --port 8000',
    cwd: '/root/glass-deploy-TIMESTAMP/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
PM2_EOF

# Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Check status
pm2 status
pm2 logs glass-erp-backend --lines 50
```

### 6. Setup SSL (Optional but Recommended)
```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Certbot will automatically configure Nginx for HTTPS
# Certificates auto-renew
```

### 7. Security & Firewall
```bash
# Configure firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Secure MongoDB (if using local MongoDB)
mongosh
use admin
db.createUser({
  user: "glassadmin",
  pwd: "STRONG_PASSWORD_HERE",
  roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
})
exit

# Update backend/.env with:
# MONGODB_URI=mongodb://glassadmin:PASSWORD@localhost:27017/glass_erp_prod?authSource=admin
```

### 8. Monitoring & Logs
```bash
# View backend logs
pm2 logs glass-erp-backend

# View Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System resources
htop
df -h
free -h
```

## 🔄 Update/Redeploy Process
```bash
# 1. Upload new package
scp -r new-glass-deploy-* root@YOUR_VPS_IP:/root/

# 2. On VPS
pm2 stop glass-erp-backend

# 3. Deploy new version
cd /root/new-glass-deploy-*/backend
source venv/bin/activate
pip install -r requirements.txt

cd ../frontend
npm install --legacy-peer-deps
npm run build
cp -r build/* /var/www/glass-erp/

# 4. Update PM2 config with new path
pm2 delete glass-erp-backend
pm2 start ecosystem.config.js
pm2 save
```

## 🚨 Troubleshooting

### Backend not starting
```bash
cd /root/glass-deploy-*/backend
source venv/bin/activate
python -m uvicorn server:app --reload
# Check error messages
```

### Frontend blank page
```bash
# Check browser console for API errors
# Verify REACT_APP_API_URL in .env.production
# Check Nginx logs: tail -f /var/log/nginx/error.log
```

### MongoDB connection errors
```bash
systemctl status mongod
mongosh --eval "db.version()"
# Check MONGODB_URI in backend/.env
```

## ✅ Verification Checklist

- [ ] Backend health check: `curl http://YOUR_VPS_IP/health`
- [ ] Frontend loads: Visit `http://YOUR_VPS_IP`
- [ ] API requests work (check browser network tab)
- [ ] MongoDB connected (check PM2 logs)
- [ ] PM2 running: `pm2 status`
- [ ] Nginx running: `systemctl status nginx`
- [ ] SSL working (if configured): `https://yourdomain.com`
- [ ] Firewall enabled: `ufw status`

## 📞 Support

If issues persist:
1. Check PM2 logs: `pm2 logs glass-erp-backend --lines 100`
2. Check Nginx logs: `tail -100 /var/log/nginx/error.log`
3. Check MongoDB: `mongosh --eval "db.serverStatus()"`
EOF

# Create package archive
echo ""
echo "📦 Step 3: Creating compressed package..."
cd /tmp
PACKAGE_NAME="glass-deploy-${TIMESTAMP}.tar.gz"
PACKAGE_PATH="/tmp/${PACKAGE_NAME}"
tar -czf "${PACKAGE_NAME}" "glass-deploy-${TIMESTAMP}"

echo ""
echo "✅ SUCCESS! Production package created!"
echo "=================================================="
echo ""
echo "📦 Package: $PACKAGE_PATH"
echo "📏 Size: $(du -h "$PACKAGE_PATH" | cut -f1)"
echo ""
echo "🚀 Next Steps:"
echo ""
echo "1. Upload to VPS:"
echo "   scp $PACKAGE_PATH $VPS_USER@$VPS_IP:/root/"
echo ""
echo "2. SSH to VPS:"
echo "   ssh $VPS_USER@$VPS_IP"
echo ""
echo "3. Extract and deploy:"
echo "   cd /root"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd glass-deploy-*"
echo "   cat DEPLOY_INSTRUCTIONS.md"
echo ""
echo "📖 Full instructions in: $DEPLOY_DIR/DEPLOY_INSTRUCTIONS.md"
echo ""
echo "⚠️  Your local development environment is unchanged and still running!"
echo "📂 Deployment folder: $DEPLOY_DIR"
echo ""
echo ""
