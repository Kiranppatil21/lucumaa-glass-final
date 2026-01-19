#!/bin/bash
# Glass ERP - Quick Deployment Script for Hostinger VPS
# Run this on your Hostinger VPS after uploading files

set -e

echo "======================================"
echo "Glass ERP Production Deployment"
echo "======================================"

# Configuration
APP_DIR="/var/www/glass-erp"
DOMAIN="yourdomain.com"  # CHANGE THIS

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Installing system dependencies...${NC}"
sudo apt update
sudo apt install -y python3.10 python3.10-venv python3-pip nodejs npm nginx supervisor

echo -e "${GREEN}✓ System dependencies installed${NC}"

echo -e "${YELLOW}Step 2: Setting up application directory...${NC}"
sudo mkdir -p $APP_DIR/frontend $APP_DIR/backend
sudo chown -R $USER:$USER $APP_DIR

echo -e "${GREEN}✓ Application directory created${NC}"

echo -e "${YELLOW}Step 3: Setting up Python backend...${NC}"
cd $APP_DIR/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo -e "${GREEN}✓ Python dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠ requirements.txt not found. Please upload backend files first.${NC}"
fi

echo -e "${YELLOW}Step 4: Configuring Nginx...${NC}"
sudo tee /etc/nginx/sites-available/glass-erp > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    root $APP_DIR/frontend/build;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /uploads {
        alias $APP_DIR/backend/uploads;
        autoindex off;
    }

    client_max_body_size 10M;
}
EOL

sudo ln -sf /etc/nginx/sites-available/glass-erp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

echo -e "${GREEN}✓ Nginx configured${NC}"

echo -e "${YELLOW}Step 5: Setting up Supervisor...${NC}"
sudo tee /etc/supervisor/conf.d/glass-erp-backend.conf > /dev/null <<EOL
[program:glass-erp-backend]
directory=$APP_DIR/backend
command=$APP_DIR/backend/venv/bin/uvicorn server:app --host 127.0.0.1 --port 8000 --workers 2
user=www-data
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/glass-erp-backend.log
stderr_logfile=/var/log/glass-erp-backend-error.log
environment=PATH="$APP_DIR/backend/venv/bin"
EOL

sudo supervisorctl reread
sudo supervisorctl update

echo -e "${GREEN}✓ Supervisor configured${NC}"

echo -e "${YELLOW}Step 6: Setting up SSL (optional but recommended)...${NC}"
read -p "Do you want to set up SSL with Let's Encrypt? (y/n): " setup_ssl
if [ "$setup_ssl" = "y" ]; then
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN
    echo -e "${GREEN}✓ SSL configured${NC}"
fi

echo ""
echo "======================================"
echo -e "${GREEN}Deployment Complete!${NC}"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Upload your backend files to: $APP_DIR/backend/"
echo "2. Upload your frontend build to: $APP_DIR/frontend/build/"
echo "3. Configure .env file in backend directory"
echo "4. Run: cd $APP_DIR/backend && source venv/bin/activate && python seed_admin.py"
echo "5. Start backend: sudo supervisorctl start glass-erp-backend"
echo ""
echo "Your app will be available at: http://$DOMAIN"
echo ""
echo "View logs:"
echo "  Backend: sudo tail -f /var/log/glass-erp-backend.log"
echo "  Nginx: sudo tail -f /var/log/nginx/error.log"
echo ""
