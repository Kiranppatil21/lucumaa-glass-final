# Glass ERP - Hostinger Deployment Guide

## Prerequisites

### Hostinger Requirements:
- **VPS Hosting** (recommended) or Cloud Hosting with:
  - Python 3.10+ support
  - Node.js 18+ support
  - At least 2GB RAM
  - SSH access
  - Domain/subdomain configured

### External Services Needed:
- **MongoDB Atlas** (Free tier available): https://www.mongodb.com/cloud/atlas/register

---

## Part 1: MongoDB Atlas Setup (Free Database)

### Step 1: Create MongoDB Atlas Account
1. Go to https://www.mongodb.com/cloud/atlas/register
2. Sign up for a free account
3. Create a new cluster (choose Free tier - M0)
4. Select your nearest region

### Step 2: Configure Database Access
1. In Atlas Dashboard, go to **Database Access**
2. Click **Add New Database User**
   - Username: `glassadmin`
   - Password: `[Generate Strong Password]` (save this!)
   - Database User Privileges: `Atlas admin`

### Step 3: Configure Network Access
1. Go to **Network Access**
2. Click **Add IP Address**
3. Choose **Allow Access from Anywhere** (0.0.0.0/0)
   - Or add your Hostinger VPS IP specifically

### Step 4: Get Connection String
1. Click **Connect** on your cluster
2. Choose **Connect your application**
3. Copy the connection string:
   ```
   mongodb+srv://glassadmin:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
4. Replace `<password>` with your actual password

### Step 5: Create Database and Seed Admin User
```bash
# Install MongoDB Shell locally or use Atlas UI
# Connection string format:
mongodb+srv://glassadmin:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/lucumaa
```

---

## Part 2: Prepare Application for Production

### Step 1: Build Frontend (Run Locally)
```bash
cd /Users/admin/Desktop/Glass/frontend
npm install
npm run build
# This creates a 'build' folder with static files
```

### Step 2: Prepare Backend Files
Your backend Python files are ready in `/Users/admin/Desktop/Glass/backend/`

---

## Part 3: Upload to Hostinger VPS

### Method A: Using SSH/SFTP (Recommended)

#### 1. Connect to Hostinger VPS
```bash
ssh root@your-server-ip
# Or use the credentials from Hostinger panel
```

#### 2. Install Required Software
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python 3.10+
sudo apt install python3.10 python3.10-venv python3-pip -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y

# Install Nginx
sudo apt install nginx -y

# Install Supervisor (for process management)
sudo apt install supervisor -y
```

#### 3. Create Application Directory
```bash
sudo mkdir -p /var/www/glass-erp
sudo chown -R $USER:$USER /var/www/glass-erp
cd /var/www/glass-erp
```

#### 4. Upload Files via SFTP
Using FileZilla or your SFTP client:
- Upload frontend `build` folder to: `/var/www/glass-erp/frontend/`
- Upload entire `backend` folder to: `/var/www/glass-erp/backend/`

OR use SCP:
```bash
# From your local machine
scp -r /Users/admin/Desktop/Glass/frontend/build root@your-server-ip:/var/www/glass-erp/frontend/
scp -r /Users/admin/Desktop/Glass/backend root@your-server-ip:/var/www/glass-erp/backend/
```

#### 5. Setup Backend on Server
```bash
cd /var/www/glass-erp/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create production .env file
nano .env
```

Paste this configuration (UPDATE VALUES):
```env
MONGO_URL=mongodb+srv://glassadmin:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
DB_NAME=lucumaa
JWT_SECRET=your-super-secret-jwt-key-change-this-to-random-string
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret
EMAIL_FROM=noreply@yourdomain.com
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-email-password
```

#### 6. Seed Admin User
```bash
cd /var/www/glass-erp/backend
source venv/bin/activate
python seed_admin.py
```

---

## Part 4: Configure Nginx (Web Server)

### Create Nginx Configuration
```bash
sudo nano /etc/nginx/sites-available/glass-erp
```

Paste this configuration:
```nginx
# Frontend (React App)
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    root /var/www/glass-erp/frontend/build;
    index index.html;

    # Serve static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to backend
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Serve uploaded files
    location /uploads {
        alias /var/www/glass-erp/backend/uploads;
        autoindex off;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/glass-erp /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

---

## Part 5: Setup Supervisor (Keep Backend Running)

### Create Supervisor Configuration
```bash
sudo nano /etc/supervisor/conf.d/glass-erp-backend.conf
```

Paste this:
```ini
[program:glass-erp-backend]
directory=/var/www/glass-erp/backend
command=/var/www/glass-erp/backend/venv/bin/uvicorn server:app --host 127.0.0.1 --port 8000 --workers 2
user=www-data
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/glass-erp-backend.log
stderr_logfile=/var/log/glass-erp-backend-error.log
environment=PATH="/var/www/glass-erp/backend/venv/bin"
```

Start the service:
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start glass-erp-backend
sudo supervisorctl status
```

---

## Part 6: Setup SSL Certificate (HTTPS)

### Install Certbot
```bash
sudo apt install certbot python3-certbot-nginx -y
```

### Get SSL Certificate
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Follow the prompts. Certbot will automatically configure Nginx for HTTPS.

---

## Part 7: Update Frontend Configuration

### Update Frontend .env for Production
Create/edit on server: `/var/www/glass-erp/frontend/.env.production`
```env
REACT_APP_BACKEND_URL=https://yourdomain.com
```

Then rebuild frontend:
```bash
cd /var/www/glass-erp/frontend
npm install
npm run build
```

---

## Verification Checklist

- [ ] MongoDB Atlas cluster is running
- [ ] Admin user seeded in database
- [ ] Backend running on http://127.0.0.1:8000
- [ ] Nginx serving frontend on http://yourdomain.com
- [ ] API proxying working: http://yourdomain.com/api/health
- [ ] SSL certificate installed (https://)
- [ ] Can login at: https://yourdomain.com

### Test Commands
```bash
# Check backend is running
curl http://127.0.0.1:8000/health

# Check Nginx
sudo nginx -t
sudo systemctl status nginx

# Check Supervisor
sudo supervisorctl status

# View logs
sudo tail -f /var/log/glass-erp-backend.log
sudo tail -f /var/log/nginx/error.log
```

---

## Maintenance Commands

### Restart Backend
```bash
sudo supervisorctl restart glass-erp-backend
```

### Update Application
```bash
# Stop backend
sudo supervisorctl stop glass-erp-backend

# Upload new files via SFTP
# Then:
cd /var/www/glass-erp/backend
source venv/bin/activate
pip install -r requirements.txt

# Start backend
sudo supervisorctl start glass-erp-backend
```

### View Logs
```bash
sudo tail -f /var/log/glass-erp-backend.log
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## Troubleshooting

### Backend Not Starting
```bash
cd /var/www/glass-erp/backend
source venv/bin/activate
python -m uvicorn server:app --host 127.0.0.1 --port 8000
# Check for errors
```

### Database Connection Issues
- Verify MongoDB Atlas connection string
- Check if IP is whitelisted in Atlas
- Test connection: `mongo "mongodb+srv://..."`

### Frontend Not Loading
- Check Nginx configuration: `sudo nginx -t`
- Verify files exist: `ls /var/www/glass-erp/frontend/build/`
- Check permissions: `sudo chown -R www-data:www-data /var/www/glass-erp/`

### Login Issues
- Verify admin user exists in MongoDB
- Check JWT_SECRET in .env
- Check browser console for errors

---

## Cost Breakdown

- **MongoDB Atlas**: Free (M0 tier - 512MB)
- **Hostinger VPS**: ~$4-8/month (VPS KVM 1)
- **Domain**: ~$10-15/year (if needed)
- **SSL Certificate**: Free (Let's Encrypt)

**Total**: ~$5-10/month

---

## Support

For issues:
1. Check logs first
2. Verify all services are running
3. Test individual components
4. Review Nginx/Supervisor configurations
