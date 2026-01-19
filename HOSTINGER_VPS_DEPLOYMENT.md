# Complete Hostinger VPS Deployment Guide - Glass ERP

## 📋 Prerequisites
- Hostinger VPS account (KVM 1 or higher recommended)
- Domain name (optional but recommended)
- SSH client on your computer
- Your application files ready

---

## Phase 1: VPS Initial Setup

### Step 1: Order & Access VPS

1. **Login to Hostinger**
   - Go to https://hostinger.com
   - Login to your account
   - Navigate to VPS → Order new VPS

2. **Choose VPS Plan**
   - **Recommended**: KVM 1 (2 vCPU, 4 GB RAM, 50 GB SSD)
   - **OS**: Ubuntu 22.04 LTS (recommended)
   - Complete purchase

3. **Get VPS Credentials**
   - After setup, go to hPanel → VPS
   - Note down:
     - **IP Address**: e.g., `123.45.67.89`
     - **SSH Port**: Usually `22`
     - **Root Password**: (shown once, save it!)

### Step 2: First SSH Connection

```bash
# Connect to your VPS
ssh root@YOUR_VPS_IP

# If asked about fingerprint, type: yes
# Enter the root password when prompted
```

### Step 3: Initial Server Security

```bash
# Update system packages
apt update && apt upgrade -y

# Create new sudo user (replace 'glassadmin' with your username)
adduser glassadmin
# Enter password and info when prompted

# Add user to sudo group
usermod -aG sudo glassadmin

# Enable firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
# Type 'y' when prompted

# Exit and login as new user
exit

# Reconnect as new user
ssh glassadmin@YOUR_VPS_IP
```

---

## Phase 2: Install Required Software

### Step 4: Install Node.js 20.x

```bash
# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version  # Should show v20.x.x
npm --version   # Should show 10.x.x

# Install PM2 globally (process manager)
sudo npm install -g pm2
```

### Step 5: Install Python 3.11

```bash
# Install Python and pip
sudo apt install -y python3.11 python3.11-venv python3-pip

# Verify installation
python3.11 --version  # Should show Python 3.11.x

# Install build essentials
sudo apt install -y build-essential libssl-dev libffi-dev python3.11-dev
```

### Step 6: Install MongoDB 7.0

```bash
# Import MongoDB GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Add MongoDB repository
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Install MongoDB
sudo apt update
sudo apt install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Verify MongoDB is running
sudo systemctl status mongod
# Press 'q' to exit

# Test MongoDB connection
mongosh --eval "db.version()"
```

### Step 7: Install Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check if Nginx is running
sudo systemctl status nginx
# Press 'q' to exit

# Test: Visit http://YOUR_VPS_IP in browser
# Should see "Welcome to Nginx" page
```

### Step 8: Install Additional Tools

```bash
# Install Git
sudo apt install -y git

# Install curl and wget (if not already installed)
sudo apt install -y curl wget

# Install unzip
sudo apt install -y unzip
```

---

## Phase 3: Upload Your Application

### Step 9: Transfer Files to VPS

**Option A: Using Git (Recommended if you have GitHub)**

```bash
# On VPS
cd /home/glassadmin
git clone https://github.com/yourusername/Glass.git
cd Glass
```

**Option B: Using SCP (From your Mac)**

```bash
# On your Mac terminal (from Desktop)
cd /Users/admin/Desktop
scp -r Glass glassadmin@YOUR_VPS_IP:/home/glassadmin/

# Then on VPS
cd /home/glassadmin/Glass
```

**Option C: Using SFTP Client (GUI)**
- Download FileZilla or Cyberduck
- Connect to `YOUR_VPS_IP` with username `glassadmin`
- Upload entire `Glass` folder to `/home/glassadmin/`

### Step 10: Verify Files

```bash
# Check files are there
cd /home/glassadmin/Glass
ls -la

# You should see:
# - backend/
# - frontend/
# - package.json (if any)
# - README.md
# etc.
```

---

## Phase 4: Setup Backend (FastAPI)

### Step 11: Create Python Virtual Environment

```bash
# Navigate to project
cd /home/glassadmin/Glass

# Create virtual environment
python3.11 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Your prompt should now show (venv)
```

### Step 12: Install Backend Dependencies

```bash
# Navigate to backend
cd backend

# Install requirements
pip install --upgrade pip
pip install -r requirements.txt

# This will take 5-10 minutes
```

### Step 13: Configure Backend Environment

```bash
# Create .env file
nano .env
```

**Paste this content (adjust values):**

```env
# MongoDB Configuration
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=lucumaa_glass_erp

# JWT Secret (generate a random strong secret)
SECRET_KEY=your-super-secret-key-change-this-to-random-string
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Server Configuration
HOST=0.0.0.0
PORT=8000
DEBUG=False

# CORS Origins (replace with your domain)
CORS_ORIGINS=["http://YOUR_VPS_IP", "http://your-domain.com", "https://your-domain.com"]

# Email Configuration (optional - for notifications)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=your-email@gmail.com

# Razorpay Configuration (for payments)
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret

# File Upload
MAX_FILE_SIZE_MB=10
UPLOAD_DIR=/home/glassadmin/Glass/uploads

# Logging
LOG_LEVEL=INFO
LOG_FILE=/home/glassadmin/Glass/logs/app.log
```

**Save and exit:**
- Press `Ctrl + X`
- Press `Y`
- Press `Enter`

### Step 14: Create Necessary Directories

```bash
# Create uploads and logs directories
mkdir -p /home/glassadmin/Glass/uploads
mkdir -p /home/glassadmin/Glass/logs

# Set permissions
chmod 755 /home/glassadmin/Glass/uploads
chmod 755 /home/glassadmin/Glass/logs
```

### Step 15: Test Backend

```bash
# Make sure you're in backend directory with venv activated
cd /home/glassadmin/Glass/backend
source /home/glassadmin/Glass/venv/bin/activate

# Test run
python -m uvicorn server:app --host 0.0.0.0 --port 8000

# You should see:
# INFO: Uvicorn running on http://0.0.0.0:8000
# Press Ctrl+C to stop
```

### Step 16: Create Backend Systemd Service

```bash
# Create service file
sudo nano /etc/systemd/system/glass-backend.service
```

**Paste this content:**

```ini
[Unit]
Description=Glass ERP Backend (FastAPI)
After=network.target mongodb.service

[Service]
Type=simple
User=glassadmin
Group=glassadmin
WorkingDirectory=/home/glassadmin/Glass/backend
Environment="PATH=/home/glassadmin/Glass/venv/bin"
ExecStart=/home/glassadmin/Glass/venv/bin/python -m uvicorn server:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Save and exit** (`Ctrl+X`, `Y`, `Enter`)

```bash
# Reload systemd
sudo systemctl daemon-reload

# Start backend service
sudo systemctl start glass-backend

# Enable on boot
sudo systemctl enable glass-backend

# Check status
sudo systemctl status glass-backend

# Test backend API
curl http://localhost:8000/health
# Should return: {"status":"healthy","service":"lucumaa-glass-backend"}
```

---

## Phase 5: Setup Frontend (React)

### Step 17: Install Frontend Dependencies

```bash
# Navigate to frontend
cd /home/glassadmin/Glass/frontend

# Install dependencies
npm install --legacy-peer-deps

# This will take 5-10 minutes
```

### Step 18: Configure Frontend Environment

```bash
# Create .env file
nano .env
```

**Paste this content:**

```env
# Backend API URL
REACT_APP_BACKEND_URL=http://YOUR_VPS_IP:8000

# Or if using domain:
# REACT_APP_BACKEND_URL=https://api.your-domain.com

# Other configurations
REACT_APP_NAME=Lucumaa Glass ERP
REACT_APP_VERSION=1.0.0
```

**Save and exit** (`Ctrl+X`, `Y`, `Enter`)

### Step 19: Build Frontend

```bash
# Build production version
npm run build

# This creates a 'build' folder with optimized files
# Takes 2-5 minutes

# Verify build
ls -lh build/
```

### Step 20: Setup Frontend with PM2

```bash
# Install serve package globally
sudo npm install -g serve

# Create PM2 ecosystem file
nano ecosystem.config.js
```

**Paste this content:**

```javascript
module.exports = {
  apps: [{
    name: 'glass-frontend',
    script: 'serve',
    args: '-s build -l 3000',
    cwd: '/home/glassadmin/Glass/frontend',
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
```

**Save and exit**

```bash
# Start frontend with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
# Copy and run the command it shows

# Check status
pm2 status
pm2 logs glass-frontend
# Press Ctrl+C to exit logs
```

---

## Phase 6: Configure Nginx Reverse Proxy

### Step 21: Create Nginx Configuration

```bash
# Create site configuration
sudo nano /etc/nginx/sites-available/glass-erp
```

**Paste this content (replace YOUR_VPS_IP or domain):**

```nginx
# Backend API Server
server {
    listen 80;
    server_name YOUR_VPS_IP;  # or api.your-domain.com

    client_max_body_size 100M;

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

    # Frontend React App
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Static files (if served directly)
    location /static {
        alias /home/glassadmin/Glass/frontend/build/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**Save and exit**

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/glass-erp /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx
```

---

## Phase 7: Setup MongoDB Database

### Step 22: Create Database and Initial User

```bash
# Connect to MongoDB
mongosh

# In MongoDB shell, run:
```

```javascript
// Switch to database
use lucumaa_glass_erp

// Create admin user
db.users.insertOne({
  email: "admin@lucumaa.in",
  password: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ygk9rOHzY.K2",  // "adminpass"
  full_name: "Admin User",
  role: "admin",
  is_active: true,
  created_at: new Date(),
  updated_at: new Date()
})

// Create indexes
db.users.createIndex({ email: 1 }, { unique: true })
db.glass_orders.createIndex({ order_number: 1 }, { unique: true })
db.customers.createIndex({ company_name: 1 })

// Verify
db.users.find()

// Exit MongoDB shell
exit
```

---

## Phase 8: Domain Configuration (Optional)

### Step 23: Point Domain to VPS

**If you have a domain (e.g., glasserp.com):**

1. **Login to your domain registrar** (GoDaddy, Namecheap, etc.)

2. **Add DNS A Records:**
   ```
   Type    Name    Value           TTL
   A       @       YOUR_VPS_IP     3600
   A       www     YOUR_VPS_IP     3600
   ```

3. **Wait for DNS propagation** (5 minutes - 24 hours)

4. **Update Nginx configuration:**

```bash
sudo nano /etc/nginx/sites-available/glass-erp
```

Change `server_name YOUR_VPS_IP;` to:
```nginx
server_name glasserp.com www.glasserp.com;
```

Save and restart:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

### Step 24: Install SSL Certificate (Free with Let's Encrypt)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d glasserp.com -d www.glasserp.com

# Enter your email when prompted
# Agree to terms
# Choose whether to redirect HTTP to HTTPS (recommended: Yes)

# Certbot will automatically configure Nginx
# Certificates auto-renew every 90 days

# Test renewal
sudo certbot renew --dry-run
```

---

## Phase 9: Final Testing & Verification

### Step 25: Test Everything

```bash
# Check all services
sudo systemctl status mongod
sudo systemctl status glass-backend
sudo systemctl status nginx
pm2 status

# Test backend API
curl http://YOUR_VPS_IP/api/health
# or
curl http://localhost:8000/health

# Test frontend
curl http://YOUR_VPS_IP

# Check logs
sudo journalctl -u glass-backend -f  # Ctrl+C to exit
pm2 logs glass-frontend  # Ctrl+C to exit
```

### Step 26: Open in Browser

1. **Visit**: `http://YOUR_VPS_IP` (or `https://your-domain.com`)
2. **Login with:**
   - Email: `admin@lucumaa.in`
   - Password: `adminpass`
3. **Test features:**
   - Navigate to `/customize` - Test 3D configurator
   - Navigate to `/job-work` - Test job work tool
   - Try adding shapes, exporting PDF
   - Test real-time distance calculations

---

## Phase 10: Maintenance & Monitoring

### Step 27: Useful Commands

```bash
# View Backend Logs
sudo journalctl -u glass-backend -f

# View Frontend Logs
pm2 logs glass-frontend

# Restart Services
sudo systemctl restart glass-backend
pm2 restart glass-frontend
sudo systemctl restart nginx
sudo systemctl restart mongod

# Stop Services
sudo systemctl stop glass-backend
pm2 stop glass-frontend

# Start Services
sudo systemctl start glass-backend
pm2 start glass-frontend

# Check Disk Space
df -h

# Check Memory Usage
free -h

# Check CPU Usage
htop  # Press F10 to exit

# MongoDB Backup
mongodump --db lucumaa_glass_erp --out /home/glassadmin/backups/$(date +%Y%m%d)

# View Open Ports
sudo netstat -tulpn | grep LISTEN
```

### Step 28: Update Application

```bash
# Update backend
cd /home/glassadmin/Glass
git pull  # if using git
source venv/bin/activate
cd backend
pip install -r requirements.txt
sudo systemctl restart glass-backend

# Update frontend
cd /home/glassadmin/Glass/frontend
npm install --legacy-peer-deps
npm run build
pm2 restart glass-frontend
```

### Step 29: Security Hardening (Recommended)

```bash
# Setup fail2ban
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Setup automatic updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Change SSH port (optional)
sudo nano /etc/ssh/sshd_config
# Change: Port 22 to Port 2222
# Uncomment: PermitRootLogin no
sudo systemctl restart sshd
sudo ufw allow 2222/tcp
```

---

## 🎯 Quick Reference

### URLs
- **Frontend**: `http://YOUR_VPS_IP:3000` or `https://your-domain.com`
- **Backend API**: `http://YOUR_VPS_IP:8000` or `https://api.your-domain.com`
- **MongoDB**: `localhost:27017`

### Ports
- **80**: HTTP (Nginx)
- **443**: HTTPS (Nginx with SSL)
- **3000**: React Frontend
- **8000**: FastAPI Backend
- **27017**: MongoDB

### Service Status Commands
```bash
sudo systemctl status glass-backend  # Backend
pm2 status                           # Frontend
sudo systemctl status nginx          # Nginx
sudo systemctl status mongod         # MongoDB
```

### Log Locations
- Backend: `sudo journalctl -u glass-backend`
- Frontend: `pm2 logs glass-frontend`
- Nginx: `/var/log/nginx/access.log` and `/var/log/nginx/error.log`
- MongoDB: `/var/log/mongodb/mongod.log`

---

## 🐛 Troubleshooting

### Issue: Can't access website
```bash
# Check firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check Nginx
sudo systemctl status nginx
sudo nginx -t
```

### Issue: Backend not responding
```bash
# Check backend logs
sudo journalctl -u glass-backend -n 50

# Restart backend
sudo systemctl restart glass-backend
```

### Issue: Frontend not loading
```bash
# Check PM2
pm2 status
pm2 logs glass-frontend

# Restart frontend
pm2 restart glass-frontend
```

### Issue: MongoDB connection failed
```bash
# Check MongoDB
sudo systemctl status mongod
sudo systemctl restart mongod

# Check connection
mongosh --eval "db.version()"
```

### Issue: Out of memory
```bash
# Check memory
free -h

# Restart services to free memory
pm2 restart all
sudo systemctl restart glass-backend
```

---

## ✅ Deployment Checklist

- [ ] VPS ordered and accessible via SSH
- [ ] Security user created and sudo configured
- [ ] Firewall enabled (ports 22, 80, 443)
- [ ] Node.js 20.x installed
- [ ] Python 3.11 installed
- [ ] MongoDB 7.0 installed and running
- [ ] Nginx installed and running
- [ ] Application files uploaded to `/home/glassadmin/Glass`
- [ ] Backend virtual environment created
- [ ] Backend dependencies installed
- [ ] Backend `.env` configured
- [ ] Backend service created and running
- [ ] Frontend dependencies installed
- [ ] Frontend `.env` configured
- [ ] Frontend built successfully
- [ ] Frontend PM2 service running
- [ ] Nginx reverse proxy configured
- [ ] MongoDB database created with admin user
- [ ] Domain pointed to VPS (if applicable)
- [ ] SSL certificate installed (if using domain)
- [ ] Website accessible in browser
- [ ] Login working with admin credentials
- [ ] 3D configurator working
- [ ] PDF export working

---

## 🎉 Congratulations!

Your Glass ERP is now live on Hostinger VPS!

**Access your application:**
- **URL**: `http://YOUR_VPS_IP` or `https://your-domain.com`
- **Admin Login**: admin@lucumaa.in / adminpass

**Remember to:**
1. Change default admin password
2. Setup regular backups
3. Monitor server resources
4. Keep system updated

For support or issues, check logs and error messages!
