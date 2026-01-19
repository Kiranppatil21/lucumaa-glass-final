#!/bin/bash

# Quick Fix Script for Domain + Login Issues
# Run this on your VPS

echo "🔧 Glass ERP - Quick Domain & Login Fix"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on VPS
if [ ! -d "/root/glass-deploy-20260107-190639" ]; then
    echo -e "${RED}Error: Deploy directory not found!${NC}"
    echo "Please upload and extract the deployment package first."
    exit 1
fi

echo -e "${YELLOW}Step 1: Updating Backend CORS Settings...${NC}"
cd /root/glass-deploy-20260107-190639/backend

# Backup existing .env
cp .env .env.backup-$(date +%Y%m%d-%H%M%S)

# Update CORS origins
sed -i 's|ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=https://lucumaaglass.in,https://www.lucumaaglass.in,http://lucumaaglass.in,http://www.lucumaaglass.in,http://147.79.104.84|' .env

# Ensure JWT secret exists
if ! grep -q "JWT_SECRET=" .env; then
    echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env
    echo "JWT_ALGORITHM=HS256" >> .env
    echo "ACCESS_TOKEN_EXPIRE_MINUTES=30" >> .env
fi

echo -e "${GREEN}✓ Backend .env updated${NC}"

echo -e "${YELLOW}Step 2: Updating Frontend Configuration...${NC}"
cd /root/glass-deploy-20260107-190639/frontend

# Update frontend .env.production (variable name must match code)
cat > .env.production << 'EOF'
REACT_APP_BACKEND_URL=https://lucumaaglass.in
REACT_APP_ENVIRONMENT=production
GENERATE_SOURCEMAP=false
EOF

echo -e "${GREEN}✓ Frontend .env.production updated${NC}"

echo -e "${YELLOW}Step 3: Rebuilding Frontend...${NC}"
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend built successfully${NC}"
else
    echo -e "${RED}✗ Frontend build failed${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 4: Deploying Frontend...${NC}"
sudo cp -r build/* /var/www/glass-erp/
sudo chown -R www-data:www-data /var/www/glass-erp
sudo chmod -R 755 /var/www/glass-erp

echo -e "${GREEN}✓ Frontend deployed${NC}"

echo -e "${YELLOW}Step 5: Updating Nginx Configuration...${NC}"

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

sudo ln -sf /etc/nginx/sites-available/glass-erp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
if sudo nginx -t; then
    echo -e "${GREEN}✓ Nginx configuration valid${NC}"
    sudo systemctl restart nginx
    echo -e "${GREEN}✓ Nginx restarted${NC}"
else
    echo -e "${RED}✗ Nginx configuration error${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 6: Restarting Backend...${NC}"
pm2 restart glass-erp-backend
sleep 3

if pm2 list | grep -q "glass-erp-backend.*online"; then
    echo -e "${GREEN}✓ Backend restarted successfully${NC}"
else
    echo -e "${RED}✗ Backend failed to start${NC}"
    echo "Check logs: pm2 logs glass-erp-backend"
    exit 1
fi

echo -e "${YELLOW}Step 7: Verifying Services...${NC}"

# Check health endpoint
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    echo -e "${GREEN}✓ Backend health check passed${NC}"
else
    echo -e "${RED}✗ Backend health check failed${NC}"
fi

# Check Nginx
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx is running${NC}"
else
    echo -e "${RED}✗ Nginx is not running${NC}"
fi

# Check MongoDB
if sudo systemctl is-active --quiet mongod; then
    echo -e "${GREEN}✓ MongoDB is running${NC}"
else
    echo -e "${RED}✗ MongoDB is not running${NC}"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ Configuration Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Next Steps:"
echo ""
echo "1. Point your domain DNS to this server:"
echo "   - Go to your domain registrar"
echo "   - Add A record: lucumaaglass.in → 147.79.104.84"
echo "   - Add A record: www.lucumaaglass.in → 147.79.104.84"
echo ""
echo "2. Wait 5-30 minutes for DNS propagation"
echo ""
echo "3. Install SSL certificate:"
echo "   sudo certbot --nginx -d lucumaaglass.in -d www.lucumaaglass.in"
echo ""
echo "4. Test your application:"
echo "   http://lucumaaglass.in (after DNS propagates)"
echo "   http://147.79.104.84 (works now)"
echo ""
echo "Current status:"
pm2 status
echo ""
echo "View logs:"
echo "  pm2 logs glass-erp-backend"
echo ""
