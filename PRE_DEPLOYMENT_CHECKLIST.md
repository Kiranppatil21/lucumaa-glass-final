# Pre-Deployment Checklist for Hostinger VPS

## Before You Start

### 1. Requirements Check
- [ ] Hostinger VPS account created
- [ ] VPS plan selected (KVM 1 or higher)
- [ ] Ubuntu 22.04 LTS installed on VPS
- [ ] Root password saved securely
- [ ] VPS IP address noted down
- [ ] Domain name (optional, but recommended)
- [ ] SSH client installed (Terminal on Mac/Linux, PuTTY on Windows)

### 2. Local Preparation
- [ ] Application tested locally and working
- [ ] All environment variables documented
- [ ] Database schema/migrations ready
- [ ] Frontend builds successfully (`npm run build`)
- [ ] Backend requirements.txt up to date
- [ ] No hardcoded localhost URLs in code

### 3. Account Information
```
VPS IP Address: _________________
VPS Username:   _________________
VPS Password:   _________________
SSH Port:       _______ (default: 22)
Domain Name:    _________________ (if any)
```

### 4. Third-Party Services
- [ ] Razorpay keys obtained (if using payments)
- [ ] Email SMTP credentials (if using email)
- [ ] Any API keys needed
- [ ] SSL certificate plan (Let's Encrypt recommended)

---

## Deployment Day Checklist

### Phase 1: Initial Access (15 min)
- [ ] Connected to VPS via SSH
- [ ] Root login successful
- [ ] Created sudo user (non-root)
- [ ] Sudo user tested
- [ ] Firewall configured (ports 22, 80, 443)
- [ ] System packages updated (`apt update && upgrade`)

### Phase 2: Software Installation (30 min)
- [ ] Node.js 20.x installed
- [ ] Python 3.11 installed
- [ ] MongoDB 7.0 installed and running
- [ ] Nginx installed and running
- [ ] PM2 installed globally
- [ ] Git installed
- [ ] All tools verified with `--version` commands

### Phase 3: Application Setup (45 min)
- [ ] Application files uploaded to VPS
- [ ] Files in `/home/username/Glass` directory
- [ ] Backend virtual environment created
- [ ] Backend dependencies installed
- [ ] Backend `.env` file created and configured
- [ ] Frontend dependencies installed
- [ ] Frontend `.env` file created and configured
- [ ] Frontend built successfully

### Phase 4: Services Configuration (30 min)
- [ ] Backend systemd service created
- [ ] Backend service started and enabled
- [ ] Backend health check passing (`curl localhost:8000/health`)
- [ ] Frontend PM2 service created
- [ ] Frontend service started
- [ ] Frontend accessible (`curl localhost:3000`)

### Phase 5: Web Server Setup (20 min)
- [ ] Nginx reverse proxy configured
- [ ] Nginx configuration tested (`nginx -t`)
- [ ] Nginx restarted
- [ ] Can access frontend via VPS IP in browser
- [ ] API endpoints working via Nginx proxy

### Phase 6: Database Setup (15 min)
- [ ] MongoDB running
- [ ] Database created
- [ ] Admin user created
- [ ] Indexes created
- [ ] Can connect to MongoDB
- [ ] Test login with admin credentials

### Phase 7: Domain & SSL (Optional, 30 min)
- [ ] Domain A record pointed to VPS IP
- [ ] DNS propagated (check with `nslookup domain.com`)
- [ ] Nginx configuration updated with domain
- [ ] Certbot installed
- [ ] SSL certificate obtained
- [ ] HTTPS working
- [ ] HTTP redirects to HTTPS

### Phase 8: Testing & Verification (30 min)
- [ ] Website loads in browser
- [ ] Login works with admin credentials
- [ ] Can navigate to different pages
- [ ] 3D configurator loads and works
- [ ] Shapes display correctly (heart, triangle)
- [ ] Can add/move/resize shapes
- [ ] Real-time distance calculation works
- [ ] PDF export works
- [ ] Database operations working
- [ ] All API endpoints responding

### Phase 9: Security Hardening (20 min)
- [ ] Changed default passwords
- [ ] Root login disabled
- [ ] SSH key authentication configured (recommended)
- [ ] Fail2ban installed and configured
- [ ] Automatic security updates enabled
- [ ] Firewall rules verified
- [ ] MongoDB secured (not exposed to internet)

### Phase 10: Monitoring Setup (15 min)
- [ ] Can view backend logs
- [ ] Can view frontend logs
- [ ] Can monitor resource usage
- [ ] PM2 startup configured
- [ ] Backend service enabled on boot
- [ ] Test server reboot (optional)

---

## Post-Deployment Verification

### Functionality Tests
- [ ] User registration works
- [ ] User login works
- [ ] Dashboard loads
- [ ] Glass configurator (/customize) works
- [ ] Job work tool (/job-work) works
- [ ] Can create glass configurations
- [ ] Can add cutouts (all shapes: circle, rectangle, triangle, heart, hexagon)
- [ ] Can drag shapes
- [ ] Can resize shapes
- [ ] Real-time edge distances update
- [ ] Can export to PDF
- [ ] PDF download works
- [ ] Can create orders
- [ ] Can manage inventory
- [ ] Admin features work
- [ ] Customer features work

### Performance Tests
- [ ] Page load time < 3 seconds
- [ ] API response time < 500ms
- [ ] 3D configurator smooth (no lag)
- [ ] Can handle multiple shapes without slowdown
- [ ] PDF generation < 5 seconds

### Security Tests
- [ ] Cannot access backend directly (must go through Nginx)
- [ ] CORS working properly
- [ ] Authentication required for protected routes
- [ ] MongoDB not accessible from internet
- [ ] No exposed credentials in client-side code
- [ ] HTTPS certificate valid (if using SSL)

### Browser Compatibility
- [ ] Chrome/Edge - Works
- [ ] Firefox - Works
- [ ] Safari - Works
- [ ] Mobile browsers - Works

---

## Common Issues & Solutions

### ❌ Can't SSH into VPS
**Solution:**
```bash
# Try with verbose mode
ssh -v username@ip_address

# Check if firewall blocking
# On VPS: sudo ufw allow 22/tcp
```

### ❌ Services won't start
**Solution:**
```bash
# Check logs
sudo journalctl -u glass-backend -n 50
pm2 logs glass-frontend

# Check port conflicts
sudo netstat -tulpn | grep :8000
sudo netstat -tulpn | grep :3000
```

### ❌ Website not accessible
**Solution:**
```bash
# Check firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check Nginx
sudo nginx -t
sudo systemctl restart nginx
```

### ❌ MongoDB connection failed
**Solution:**
```bash
# Start MongoDB
sudo systemctl start mongod

# Check status
sudo systemctl status mongod

# Check logs
sudo tail -f /var/log/mongodb/mongod.log
```

### ❌ Out of disk space
**Solution:**
```bash
# Check space
df -h

# Clean logs
pm2 flush
sudo journalctl --vacuum-time=7d

# Clean package cache
sudo apt clean
```

### ❌ Backend crashes
**Solution:**
```bash
# Check logs for errors
sudo journalctl -u glass-backend -n 100

# Check environment variables
cat ~/Glass/backend/.env

# Restart service
sudo systemctl restart glass-backend
```

---

## Emergency Rollback Plan

If deployment fails, you can rollback:

### 1. Stop all services
```bash
sudo systemctl stop glass-backend
pm2 stop all
```

### 2. Restore previous version
```bash
cd ~/Glass
git checkout previous-working-commit
# or restore from backup
```

### 3. Rebuild and restart
```bash
# Backend
source venv/bin/activate
cd backend
pip install -r requirements.txt
sudo systemctl restart glass-backend

# Frontend
cd ../frontend
npm install --legacy-peer-deps
npm run build
pm2 restart glass-frontend
```

---

## Backup Before Deployment

Always backup before major changes:

```bash
# Backup database
mongodump --db lucumaa_glass_erp --out ~/backup-$(date +%Y%m%d)

# Backup application
tar -czf ~/Glass-backup-$(date +%Y%m%d).tar.gz ~/Glass

# Backup configs
sudo cp -r /etc/nginx ~/nginx-backup-$(date +%Y%m%d)
```

---

## Success Criteria

Your deployment is successful when:

✅ Website loads at `http://YOUR_IP` or `https://your-domain.com`
✅ Can login with admin credentials
✅ All pages navigate without errors
✅ 3D configurator works smoothly
✅ Shapes render correctly
✅ PDF export generates valid PDF
✅ Database operations work
✅ Logs show no critical errors
✅ Services restart automatically after reboot
✅ Resource usage is normal (CPU < 50%, Memory < 80%)

---

## Contact Information

Keep these handy during deployment:

- **Hostinger Support**: https://www.hostinger.com/contact
- **Your Domain Registrar**: _______________
- **Your Team Contact**: _______________

---

## Time Estimates

- **Full Manual Deployment**: 3-4 hours
- **Using Quick Deploy Script**: 30-45 minutes
- **Domain + SSL Setup**: +30 minutes
- **Testing & Verification**: 1 hour

**Total Time**: Plan for a 4-6 hour deployment window

---

## Ready to Deploy?

If you've checked all boxes above, you're ready!

**Next Steps:**
1. Read `HOSTINGER_VPS_DEPLOYMENT.md` for detailed instructions
2. OR run `bash quick-deploy.sh` for automated deployment
3. Keep `VPS_QUICK_REFERENCE.md` open for quick commands

**Good luck! 🚀**
