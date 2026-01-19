# 🔐 Glass ERP - Login Credentials

## ✅ ISSUES FIXED
1. **403 Error on lucumaaglass.in** - Frontend rebuilt and deployed correctly
2. **Authentication Error** - Admin user created with proper bcrypt password hash
3. **Both URLs now working** - Domain and IP address both accessible

---

## 🌐 Access URLs

Your Glass ERP application is now live and accessible at:

- **Primary Domain:** http://lucumaaglass.in
- **IP Address:** http://147.79.104.84

Both URLs are working correctly and will take you to the login page.

---

## 🔑 Login Credentials

**Email:** admin@lucumaa.in  
**Password:** Lucumaa@@123

### Important Notes:
- Use the **Email** field for login (not username)
- Password is case-sensitive
- Role: Super Admin (full access)

---

## 📝 How to Login

1. Open your browser
2. Go to: **http://lucumaaglass.in** or **http://147.79.104.84**
3. You'll see the login page
4. Enter:
   - **Email:** admin@lucumaa.in
   - **Password:** Lucumaa@@123
5. Click "Login"

---

## ✅ System Status

| Service | Status | Details |
|---------|--------|---------|
| Frontend | ✅ Running | Deployed at /var/www/glass-erp/ |
| Backend | ✅ Running | Port 8000 via PM2 |
| Database | ✅ Running | MongoDB glass_erp_prod |
| Nginx | ✅ Running | Proxy to backend |
| Domain DNS | ✅ Working | lucumaaglass.in → 147.79.104.84 |

---

## 🔧 Backend API Health

Test backend health:
```bash
curl http://lucumaaglass.in/health
# Response: {"status":"healthy","service":"lucumaa-glass-backend"}
```

---

## 📱 What's Working

- ✅ Frontend loads successfully
- ✅ Backend API responding
- ✅ Admin user created with proper credentials
- ✅ Login system functional
- ✅ 3D Glass Configurator with real-time edge distances
- ✅ Heart and triangle shapes rendering correctly
- ✅ PDF export functionality
- ✅ Full ERP features available

---

## 🔒 Security Notes

- Currently running on **HTTP** (port 80)
- SSL/HTTPS can be added later using the commands in Untitled-1
- Admin password can be changed after first login
- Database: MongoDB with authentication

---

## 🚀 Next Steps (Optional)

1. **Change Admin Password** - Recommended after first login
2. **Create Additional Users** - Add team members with appropriate roles
3. **Enable HTTPS/SSL** - Use certbot commands from Untitled-1 when ready
4. **Configure Email Notifications** - Set up SMTP for email features
5. **Set Up Backups** - Schedule MongoDB backups

---

## 📞 Troubleshooting

If you encounter any issues:

1. **Can't access the site:**
   ```bash
   # Check if services are running on VPS
   ssh root@147.79.104.84
   pm2 status
   systemctl status nginx
   systemctl status mongod
   ```

2. **Login not working:**
   ```bash
   # Test backend directly
   curl http://147.79.104.84/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@lucumaa.in","password":"Lucumaa@@123"}'
   ```

3. **Frontend issues:**
   ```bash
   # Check frontend files
   ssh root@147.79.104.84
   ls -la /var/www/glass-erp/
   ```

---

## 📊 VPS Details

- **IP Address:** 147.79.104.84
- **OS:** Ubuntu 22.04
- **Node.js:** v20.x
- **Python:** 3.11
- **MongoDB:** 7.0
- **Deployment Path:** /root/glass-deploy-20260107-190639/
- **Web Root:** /var/www/glass-erp/

---

## ✨ Deployment Summary

**Date:** January 7, 2026  
**Status:** ✅ Successfully Deployed  
**Protocol:** HTTP (SSL/HTTPS optional)  
**Domain:** lucumaaglass.in  
**Admin Access:** Configured and tested  

---

**🎉 Your Glass ERP application is now live and ready to use!**

Open http://lucumaaglass.in and login with the credentials above.
