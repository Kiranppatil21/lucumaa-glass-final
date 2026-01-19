#!/bin/bash
# Glass ERP - One-Command VPS Deploy
# Upload this file to your VPS and run: bash vps-auto-deploy.sh

set -e

echo "================================================"
echo "Glass ERP - Automated VPS Deployment"
echo "================================================"
echo ""
read -p "Enter your VPS IP address: " VPS_IP
read -p "Enter your domain (or press Enter to skip): " DOMAIN
read -p "Install SSL certificate? (y/n): " INSTALL_SSL

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[1/10] Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "${GREEN}[2/10] Installing Node.js 20.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2 serve

echo -e "${GREEN}[3/10] Installing Python 3.11...${NC}"
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip build-essential libssl-dev libffi-dev

echo -e "${GREEN}[4/10] Installing MongoDB 7.0...${NC}"
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update && sudo apt install -y mongodb-org
sudo systemctl start mongod && sudo systemctl enable mongod

echo -e "${GREEN}[5/10] Installing Nginx...${NC}"
sudo apt install -y nginx
sudo systemctl start nginx && sudo systemctl enable nginx

echo -e "${GREEN}[6/10] Setting up backend...${NC}"
cd ~/Glass
python3.11 -m venv venv
source venv/bin/activate
cd backend
pip install --upgrade pip
pip install -r requirements.txt

# Create backend .env
cat > .env <<EOL
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=lucumaa_glass_erp
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
HOST=0.0.0.0
PORT=8000
DEBUG=False
CORS_ORIGINS=["http://${VPS_IP}","http://localhost:3000"]
LOG_LEVEL=INFO
LOG_FILE=~/Glass/logs/app.log
MAX_FILE_SIZE_MB=10
UPLOAD_DIR=~/Glass/uploads
EOL

# Update CORS if domain provided
if [ ! -z "$DOMAIN" ]; then
  sed -i "s/CORS_ORIGINS=.*/CORS_ORIGINS=[\"http:\/\/${VPS_IP}\",\"http:\/\/${DOMAIN}\",\"https:\/\/${DOMAIN}\",\"http:\/\/localhost:3000\"]/" .env
fi

mkdir -p ~/Glass/uploads ~/Glass/logs

# Create backend service
sudo tee /etc/systemd/system/glass-backend.service > /dev/null <<EOL
[Unit]
Description=Glass ERP Backend
After=network.target mongodb.service

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$HOME/Glass/backend
Environment="PATH=$HOME/Glass/venv/bin"
ExecStart=$HOME/Glass/venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl start glass-backend
sudo systemctl enable glass-backend

echo -e "${GREEN}[7/10] Setting up frontend...${NC}"
cd ~/Glass/frontend
npm install --legacy-peer-deps

# Create frontend .env
if [ ! -z "$DOMAIN" ]; then
  echo "REACT_APP_BACKEND_URL=https://${DOMAIN}" > .env
else
  echo "REACT_APP_BACKEND_URL=http://${VPS_IP}:8000" > .env
fi

npm run build

# Create PM2 config
cat > ecosystem.config.js <<EOL
module.exports = {
  apps: [{
    name: 'glass-frontend',
    script: 'serve',
    args: '-s build -l 3000',
    cwd: '$HOME/Glass/frontend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: { NODE_ENV: 'production', PORT: 3000 }
  }]
};
EOL

pm2 start ecosystem.config.js
pm2 save
pm2 startup | tail -1 | bash

echo -e "${GREEN}[8/10] Configuring Nginx...${NC}"
if [ ! -z "$DOMAIN" ]; then
  SERVER_NAME="$DOMAIN www.$DOMAIN"
else
  SERVER_NAME="_"
fi

sudo tee /etc/nginx/sites-available/glass-erp > /dev/null <<EOL
server {
    listen 80;
    server_name ${SERVER_NAME};
    client_max_body_size 100M;

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/glass-erp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo -e "${GREEN}[9/10] Setting up MongoDB...${NC}"
mongosh <<EOF
use lucumaa_glass_erp
db.users.insertOne({
  email: "admin@lucumaa.in",
  password: "\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ygk9rOHzY.K2",
  full_name: "Admin User",
  role: "admin",
  is_active: true,
  created_at: new Date(),
  updated_at: new Date()
})
db.users.createIndex({ email: 1 }, { unique: true })
exit
EOF

echo -e "${GREEN}[10/10] Final steps...${NC}"
# Configure firewall
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Install SSL if requested
if [ "$INSTALL_SSL" = "y" ] && [ ! -z "$DOMAIN" ]; then
  echo -e "${GREEN}Installing SSL certificate...${NC}"
  sudo apt install -y certbot python3-certbot-nginx
  sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Deployment Complete! 🎉${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
if [ ! -z "$DOMAIN" ]; then
  echo -e "Access your application: ${YELLOW}https://${DOMAIN}${NC}"
else
  echo -e "Access your application: ${YELLOW}http://${VPS_IP}${NC}"
fi
echo -e "Login: ${YELLOW}admin@lucumaa.in${NC} / ${YELLOW}adminpass${NC}"
echo ""
echo "Service Status:"
echo "  sudo systemctl status glass-backend"
echo "  pm2 status"
echo ""
echo "View Logs:"
echo "  sudo journalctl -u glass-backend -f"
echo "  pm2 logs glass-frontend"
echo ""
