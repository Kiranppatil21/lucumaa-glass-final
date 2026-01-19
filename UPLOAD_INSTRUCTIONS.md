# Quick Upload Commands for Hostinger

## Prerequisites
- Have your Hostinger VPS IP address
- Have your SSH credentials
- Frontend built (npm run build)

---

## Option 1: Using SCP (Terminal)

### Upload Backend
```bash
cd /Users/admin/Desktop/Glass
scp -r backend root@YOUR_VPS_IP:/var/www/glass-erp/
```

### Upload Frontend Build
```bash
cd /Users/admin/Desktop/Glass/frontend
npm run build
scp -r build root@YOUR_VPS_IP:/var/www/glass-erp/frontend/
```

### Upload Deployment Script
```bash
cd /Users/admin/Desktop/Glass
scp deploy-to-hostinger.sh root@YOUR_VPS_IP:/root/
```

---

## Option 2: Using FileZilla (GUI)

### Download FileZilla
https://filezilla-project.org/download.php

### Connect to Server
- Host: `sftp://YOUR_VPS_IP`
- Username: `root` (or your SSH username)
- Password: Your SSH password
- Port: `22`

### Upload Files
1. Navigate to local: `/Users/admin/Desktop/Glass/`
2. Navigate to remote: `/var/www/glass-erp/`
3. Drag and drop:
   - `backend/` folder
   - `frontend/build/` folder

---

## Option 3: Using rsync (Recommended for Updates)

### Initial Upload
```bash
# Backend
rsync -avz --progress /Users/admin/Desktop/Glass/backend/ root@YOUR_VPS_IP:/var/www/glass-erp/backend/

# Frontend
cd /Users/admin/Desktop/Glass/frontend && npm run build
rsync -avz --progress build/ root@YOUR_VPS_IP:/var/www/glass-erp/frontend/build/
```

### Update Only Changed Files
```bash
# Backend updates
rsync -avz --delete --progress /Users/admin/Desktop/Glass/backend/ root@YOUR_VPS_IP:/var/www/glass-erp/backend/

# Frontend updates
cd /Users/admin/Desktop/Glass/frontend && npm run build
rsync -avz --delete --progress build/ root@YOUR_VPS_IP:/var/www/glass-erp/frontend/build/
```

---

## After Upload: Run on Server

### SSH into server
```bash
ssh root@YOUR_VPS_IP
```

### Run deployment script
```bash
cd /root
chmod +x deploy-to-hostinger.sh
./deploy-to-hostinger.sh
```

### Configure .env
```bash
cd /var/www/glass-erp/backend
nano .env
```

Paste your production configuration (see .env.production)

### Seed Admin User
```bash
cd /var/www/glass-erp/backend
source venv/bin/activate
python seed_admin.py
```

### Start Backend
```bash
sudo supervisorctl start glass-erp-backend
sudo supervisorctl status
```

### Verify
```bash
# Check backend
curl http://localhost:8000/health

# Check frontend
curl http://localhost/

# Check logs
sudo tail -f /var/log/glass-erp-backend.log
```

---

## One-Line Deploy (Advanced)

### Create this script locally: `quick-deploy.sh`
```bash
#!/bin/bash
SERVER="root@YOUR_VPS_IP"

echo "Building frontend..."
cd /Users/admin/Desktop/Glass/frontend
npm run build

echo "Uploading files..."
rsync -avz --progress /Users/admin/Desktop/Glass/backend/ $SERVER:/var/www/glass-erp/backend/
rsync -avz --progress build/ $SERVER:/var/www/glass-erp/frontend/build/

echo "Restarting backend..."
ssh $SERVER "sudo supervisorctl restart glass-erp-backend"

echo "Deployment complete!"
```

Make executable and run:
```bash
chmod +x quick-deploy.sh
./quick-deploy.sh
```

---

## Troubleshooting Upload Issues

### Permission Denied
```bash
# On server, set correct permissions
sudo chown -R root:root /var/www/glass-erp
sudo chmod -R 755 /var/www/glass-erp
```

### Large File Upload Timeout
```bash
# Use rsync with compression
rsync -avz --compress-level=9 --progress ...
```

### Interrupted Upload
```bash
# rsync can resume - just run the same command again
rsync -avz --partial --progress ...
```
