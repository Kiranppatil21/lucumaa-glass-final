#!/bin/bash
# Glass ERP - Quick VPS Setup Script
# Run this after initial VPS setup and file upload
# Usage: bash quick-deploy.sh

set -e

echo "========================================="
echo "Glass ERP - VPS Deployment Script"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
  echo -e "${RED}Do not run this script as root. Run as your regular user with sudo access.${NC}"
  exit 1
fi

echo -e "${GREEN}Step 1: Installing Node.js 20.x...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g pm2 serve

echo -e "${GREEN}Step 2: Installing Python 3.11...${NC}"
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip build-essential

echo -e "${GREEN}Step 3: Installing MongoDB 7.0...${NC}"
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

echo -e "${GREEN}Step 4: Installing Nginx...${NC}"
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

echo -e "${GREEN}Step 5: Setting up Backend...${NC}"
cd ~/Glass
python3.11 -m venv venv
source venv/bin/activate
cd backend
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${YELLOW}Creating backend .env file...${NC}"
cat > .env <<EOL
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=lucumaa_glass_erp
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
HOST=0.0.0.0
PORT=8000
DEBUG=False
CORS_ORIGINS=["http://localhost:3000"]
LOG_LEVEL=INFO
LOG_FILE=~/Glass/logs/app.log
EOL

echo -e "${YELLOW}Creating backend systemd service...${NC}"
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

echo -e "${GREEN}Step 6: Setting up Frontend...${NC}"
cd ~/Glass/frontend
npm install --legacy-peer-deps

echo -e "${YELLOW}Creating frontend .env file...${NC}"
echo "REACT_APP_BACKEND_URL=http://localhost:8000" > .env

echo -e "${YELLOW}Building frontend...${NC}"
npm run build

echo -e "${YELLOW}Creating PM2 ecosystem file...${NC}"
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
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
EOL

pm2 start ecosystem.config.js
pm2 save
pm2 startup | tail -1 | bash

echo -e "${GREEN}Step 7: Configuring Nginx...${NC}"
sudo tee /etc/nginx/sites-available/glass-erp > /dev/null <<EOL
server {
    listen 80;
    server_name _;
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
sudo nginx -t
sudo systemctl restart nginx

echo -e "${GREEN}Step 8: Setting up MongoDB...${NC}"
mkdir -p ~/Glass/uploads ~/Glass/logs
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

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "Your Glass ERP is now running!"
echo ""
echo -e "Access: ${YELLOW}http://$(curl -s ifconfig.me)${NC}"
echo -e "Login:  ${YELLOW}admin@lucumaa.in${NC} / ${YELLOW}adminpass${NC}"
echo ""
echo "Service Status:"
echo "  Backend:  sudo systemctl status glass-backend"
echo "  Frontend: pm2 status"
echo "  Nginx:    sudo systemctl status nginx"
echo "  MongoDB:  sudo systemctl status mongod"
echo ""
echo "Logs:"
echo "  Backend:  sudo journalctl -u glass-backend -f"
echo "  Frontend: pm2 logs glass-frontend"
echo ""
echo -e "${YELLOW}Remember to update CORS_ORIGINS in backend .env with your domain!${NC}"
echo ""
