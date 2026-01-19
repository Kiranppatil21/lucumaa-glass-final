# 🚀 Hostinger VPS - Quick Reference Card

## 📞 Emergency Commands

```bash
# Check all services
sudo systemctl status glass-backend nginx mongod && pm2 status

# Restart everything
sudo systemctl restart glass-backend nginx mongod && pm2 restart all

# View live logs
sudo journalctl -u glass-backend -f  # Backend logs
pm2 logs glass-frontend              # Frontend logs
```

## 🔑 Access Information

| Service | URL/Port | Credentials |
|---------|----------|-------------|
| Frontend | `http://YOUR_IP` | admin@lucumaa.in / adminpass |
| Backend API | `http://YOUR_IP:8000` | Same as above |
| MongoDB | `localhost:27017` | No auth (local only) |
| SSH | `YOUR_IP:22` | Your VPS user/password |

## 📋 Common Tasks

### Deploy Updates
```bash
cd ~/Glass
git pull                              # Get latest code
source venv/bin/activate              # Activate Python env
cd backend && pip install -r requirements.txt
sudo systemctl restart glass-backend  # Restart backend
cd ../frontend
npm install --legacy-peer-deps        # Install deps
npm run build                         # Build
pm2 restart glass-frontend            # Restart frontend
```

### Backup Database
```bash
# Full backup
mongodump --db lucumaa_glass_erp --out ~/backups/$(date +%Y%m%d)

# Restore backup
mongorestore --db lucumaa_glass_erp ~/backups/20260107/lucumaa_glass_erp
```

### View Logs
```bash
# Backend (last 50 lines)
sudo journalctl -u glass-backend -n 50

# Frontend
pm2 logs glass-frontend --lines 50

# Nginx errors
sudo tail -f /var/log/nginx/error.log

# MongoDB
sudo tail -f /var/log/mongodb/mongod.log
```

### Check Resources
```bash
df -h           # Disk space
free -h         # Memory
htop            # CPU & Memory (interactive)
pm2 monit       # PM2 monitoring
```

## 🔧 Service Management

```bash
# Backend
sudo systemctl start glass-backend
sudo systemctl stop glass-backend
sudo systemctl restart glass-backend
sudo systemctl status glass-backend

# Frontend
pm2 start glass-frontend
pm2 stop glass-frontend
pm2 restart glass-frontend
pm2 status

# Nginx
sudo systemctl restart nginx
sudo systemctl reload nginx  # Reload config without downtime
sudo nginx -t               # Test config

# MongoDB
sudo systemctl restart mongod
sudo systemctl status mongod
```

## 🔍 Troubleshooting

### Website not accessible
```bash
# 1. Check firewall
sudo ufw status
sudo ufw allow 80/tcp && sudo ufw allow 443/tcp

# 2. Check Nginx
sudo systemctl status nginx
sudo nginx -t
sudo systemctl restart nginx

# 3. Check frontend
pm2 status
pm2 restart glass-frontend
```

### API not responding
```bash
# 1. Check backend
sudo systemctl status glass-backend
sudo journalctl -u glass-backend -n 50

# 2. Restart backend
sudo systemctl restart glass-backend

# 3. Check if port is listening
sudo netstat -tulpn | grep 8000
```

### Database errors
```bash
# 1. Check MongoDB
sudo systemctl status mongod

# 2. Restart MongoDB
sudo systemctl restart mongod

# 3. Check connection
mongosh --eval "db.version()"

# 4. Check disk space
df -h
```

### Out of memory
```bash
# Check memory
free -h

# Restart services (frees memory)
pm2 restart all
sudo systemctl restart glass-backend

# Increase swap (if needed)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 📦 File Locations

```bash
# Application
~/Glass/                              # Main directory
~/Glass/backend/                      # Backend code
~/Glass/frontend/                     # Frontend code
~/Glass/venv/                         # Python virtual env
~/Glass/uploads/                      # Uploaded files
~/Glass/logs/                         # Application logs

# Configuration
~/Glass/backend/.env                  # Backend config
~/Glass/frontend/.env                 # Frontend config
~/Glass/frontend/ecosystem.config.js  # PM2 config
/etc/nginx/sites-available/glass-erp # Nginx config
/etc/systemd/system/glass-backend.service # Backend service

# Logs
/var/log/nginx/access.log            # Nginx access
/var/log/nginx/error.log             # Nginx errors
/var/log/mongodb/mongod.log          # MongoDB logs
~/Glass/logs/app.log                 # Application logs
```

## 🔒 Security

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Check failed login attempts
sudo journalctl -u ssh -n 50

# View firewall rules
sudo ufw status verbose

# Change SSH port (optional)
sudo nano /etc/ssh/sshd_config
# Change: Port 22 → Port 2222
sudo systemctl restart sshd
sudo ufw allow 2222/tcp
```

## 🌐 Domain & SSL

### Point domain to VPS
```
DNS A Record:
Type: A
Name: @
Value: YOUR_VPS_IP
TTL: 3600
```

### Install SSL
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
# Auto-renews every 90 days

# Test renewal
sudo certbot renew --dry-run
```

## 📊 Monitoring URLs

```bash
# Health check
curl http://YOUR_IP/api/health

# Backend API
curl http://YOUR_IP/api/erp/glass-config/colors

# Get your IP
curl ifconfig.me
```

## ⚡ Performance Tips

```bash
# Enable Nginx gzip compression
sudo nano /etc/nginx/nginx.conf
# Uncomment: gzip on; gzip_types ...
sudo systemctl reload nginx

# PM2 monitoring
pm2 install pm2-logrotate    # Auto log rotation
pm2 set pm2-logrotate:max_size 10M

# MongoDB optimization
mongosh
use admin
db.runCommand({ setParameter: 1, internalQueryExecMaxBlockingSortBytes: 335544320 })
```

## 📱 Quick SSH Connect

```bash
# Save to ~/.ssh/config on your Mac
Host glasserp
    HostName YOUR_VPS_IP
    User glassadmin
    Port 22

# Then connect with:
ssh glasserp
```

## 🆘 Support Checklist

Before asking for help, gather this info:

```bash
# System info
uname -a
cat /etc/os-release

# Service status
sudo systemctl status glass-backend
pm2 status

# Recent logs
sudo journalctl -u glass-backend -n 20
pm2 logs glass-frontend --lines 20

# Resource usage
df -h
free -h

# Network
sudo netstat -tulpn | grep LISTEN
```

---

## 📌 Important Notes

1. **Change default password** immediately after first login
2. **Backup database** regularly (daily recommended)
3. **Monitor disk space** - Clean logs if needed: `pm2 flush`
4. **Update system** monthly: `sudo apt update && sudo apt upgrade`
5. **Check logs** if something breaks - errors are logged there

---

## 🎯 One-Line Health Check

```bash
echo "Backend: $(curl -s http://localhost:8000/health | jq -r .status 2>/dev/null || echo 'DOWN') | Frontend: $(curl -sI http://localhost:3000 | head -1 | awk '{print $2}') | MongoDB: $(mongosh --quiet --eval 'db.version()' 2>/dev/null || echo 'DOWN')"
```

---

**Need help? Check logs first!** 90% of issues can be diagnosed from logs.

**Deployment Guide**: See `HOSTINGER_VPS_DEPLOYMENT.md` for full setup
**Quick Deploy**: Run `bash quick-deploy.sh` for automated setup
