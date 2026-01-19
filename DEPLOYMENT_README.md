# 🚀 Glass ERP - Hostinger Deployment Package

Complete production-ready deployment package for hosting Glass ERP on Hostinger VPS with MongoDB Atlas.

---

## 📦 What's Included

- ✅ Complete deployment guide
- ✅ MongoDB Atlas (free database) setup instructions
- ✅ Production environment configurations
- ✅ Automated deployment scripts
- ✅ Upload instructions (SCP, SFTP, rsync)
- ✅ Nginx configuration
- ✅ SSL certificate setup
- ✅ Process management (Supervisor)

---

## 🎯 Quick Start (30 minutes total)

### 1️⃣ Build Application (5 minutes)
```bash
cd /Users/admin/Desktop/Glass
./build-for-production.sh
```

This creates: `glass-erp-deployment/` folder with everything ready to upload.

### 2️⃣ Setup MongoDB Atlas (10 minutes)
Follow guide: **`MONGODB_ATLAS_SETUP.md`**
- Create free account at mongodb.com
- Get connection string
- No credit card required!

### 3️⃣ Upload to Hostinger (5 minutes)
Choose your method from **`UPLOAD_INSTRUCTIONS.md`**:
- SCP (command line)
- FileZilla (GUI)
- rsync (advanced)

### 4️⃣ Deploy on Server (10 minutes)
```bash
ssh root@your-vps-ip
cd /root
./deploy-to-hostinger.sh
```

### 5️⃣ Configure & Start
```bash
cd /var/www/glass-erp/backend
nano .env  # Add your MongoDB connection string
source venv/bin/activate
python seed_admin.py
sudo supervisorctl start glass-erp-backend
```

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| **HOSTINGER_DEPLOYMENT.md** | Complete step-by-step deployment guide |
| **MONGODB_ATLAS_SETUP.md** | Free MongoDB database setup |
| **UPLOAD_INSTRUCTIONS.md** | How to upload files to server |
| **build-for-production.sh** | Automated build script |
| **deploy-to-hostinger.sh** | Server setup automation |
| **frontend/.env.production** | Frontend production config |
| **backend/.env.production** | Backend production config template |

---

## 💰 Cost Breakdown

| Service | Cost | Notes |
|---------|------|-------|
| **MongoDB Atlas** | Free | 512MB storage, perfect for starting |
| **Hostinger VPS** | $4-8/month | VPS KVM 1 recommended |
| **Domain Name** | $10-15/year | Optional if you have one |
| **SSL Certificate** | Free | Let's Encrypt |
| **Total** | **~$5-10/month** | Professional grade hosting |

---

## 🔐 Login Credentials

After deployment, login at: `https://yourdomain.com`

**Default Admin:**
- Email: `admin@lucumaa.in`
- Password: `adminpass`
- Role: Super Admin

⚠️ **Change password immediately after first login!**

---

## 📋 System Requirements

### Hostinger VPS Minimum:
- **RAM**: 2GB
- **Storage**: 20GB SSD
- **CPU**: 1 core
- **OS**: Ubuntu 20.04 or 22.04
- **Access**: SSH/root access

### Recommended:
- **Plan**: VPS KVM 2 ($8/month)
- **RAM**: 4GB
- **Storage**: 50GB SSD
- **CPU**: 2 cores

---

## 🛠️ Technology Stack

- **Frontend**: React 19, TailwindCSS, ShadcnUI
- **Backend**: FastAPI (Python 3.10+)
- **Database**: MongoDB Atlas (Cloud)
- **Web Server**: Nginx
- **Process Manager**: Supervisor
- **SSL**: Let's Encrypt (Certbot)

---

## 📞 Need Help?

### Common Issues:

**MongoDB connection failed?**
→ Check `MONGODB_ATLAS_SETUP.md` → IP whitelist section

**Backend not starting?**
→ Check logs: `sudo tail -f /var/log/glass-erp-backend.log`

**Frontend shows blank page?**
→ Check Nginx: `sudo nginx -t && sudo systemctl status nginx`

**Can't login?**
→ Verify admin user: Run `python seed_admin.py` again

---

## 🚀 Deployment Checklist

Before going live:

- [ ] MongoDB Atlas cluster created
- [ ] Connection string tested
- [ ] Admin user seeded in database
- [ ] Frontend built successfully
- [ ] Files uploaded to `/var/www/glass-erp/`
- [ ] .env configured with production settings
- [ ] Backend running via Supervisor
- [ ] Nginx configured and running
- [ ] SSL certificate installed
- [ ] Domain DNS pointed to VPS IP
- [ ] Test login at https://yourdomain.com
- [ ] Change default admin password
- [ ] Test all major features

---

## 📊 Post-Deployment

### Monitor Your Application:
```bash
# Check backend status
sudo supervisorctl status

# View backend logs
sudo tail -f /var/log/glass-erp-backend.log

# View Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Check disk usage
df -h

# Check memory usage
free -h
```

### Update Application:
```bash
# On your local machine
cd /Users/admin/Desktop/Glass/frontend
npm run build
rsync -avz build/ root@your-vps-ip:/var/www/glass-erp/frontend/build/

# On server
ssh root@your-vps-ip
sudo supervisorctl restart glass-erp-backend
```

---

## 🎓 Learning Resources

- **MongoDB Atlas**: https://www.mongodb.com/docs/atlas/
- **FastAPI**: https://fastapi.tiangolo.com/
- **React**: https://react.dev/
- **Nginx**: https://nginx.org/en/docs/
- **Let's Encrypt**: https://letsencrypt.org/getting-started/

---

## ⚡ One-Command Deployment

After initial setup, update your app with:

```bash
# Local: Build and upload
cd /Users/admin/Desktop/Glass
./build-for-production.sh
rsync -avz glass-erp-deployment/backend/ root@your-vps-ip:/var/www/glass-erp/backend/
rsync -avz glass-erp-deployment/frontend/ root@your-vps-ip:/var/www/glass-erp/frontend/

# Server: Restart
ssh root@your-vps-ip "sudo supervisorctl restart glass-erp-backend"
```

---

## 🎉 Success!

Once deployed, you'll have:
- ✅ Professional grade ERP system
- ✅ HTTPS secured website
- ✅ Automatic process management
- ✅ Cloud database with backups
- ✅ Production monitoring
- ✅ Easy updates and maintenance

Your Glass ERP is now production-ready! 🚀

---

## 📝 Notes

- Keep your MongoDB connection string secure
- Backup your .env file safely
- Monitor your database usage (512MB limit on free tier)
- Set up regular database backups
- Consider upgrading hosting as your business grows

For detailed instructions on each step, refer to the specific documentation files listed above.
