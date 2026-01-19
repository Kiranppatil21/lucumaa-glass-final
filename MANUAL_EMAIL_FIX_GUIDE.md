# 🔧 Email System and Endpoints - Manual Fix Guide

## Issues Found:
1. ❌ SMTP_USER had wrong domain: `info@lucumaaGlass.in` (capital G)
2. ❌ SMTP_PASSWORD was empty string on VPS
3. ❌ Environment variables not set on VPS
4. ⚠️ Order date column missing in ERP

## ✅ Fixes Applied Locally:
- Fixed SMTP_USER to `info@lucumaaglass.in` 
- Added default SMTP_PASSWORD to server.py
- Added order date column to OrderManagement.js (already deployed)

## 📋 Manual Deployment Steps:

### Step 1: SSH into VPS
```bash
ssh root@147.79.104.84
```
Password: [Ask user for VPS password]

### Step 2: Navigate to Backend Directory
```bash
cd /root/glass-deploy-20260107-190639/backend
```

### Step 3: Create .env File with SMTP Credentials
```bash
cat > .env << 'EOF'
# SMTP Configuration for Email System
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=info@lucumaaglass.in
SMTP_PASSWORD=Info123@@123
EOF
```

### Step 4: Update Systemd Service (if exists)
```bash
# Check if systemd service exists
if [ -f /etc/systemd/system/glass-backend.service ]; then
  # Add EnvironmentFile to service
  sudo sed -i '/\[Service\]/a EnvironmentFile=/root/glass-deploy-20260107-190639/backend/.env' /etc/systemd/system/glass-backend.service
  sudo systemctl daemon-reload
fi
```

### Step 5: Set Environment Variables and Restart Backend
```bash
# Export SMTP variables for current session
export SMTP_HOST=smtp.hostinger.com
export SMTP_PORT=465
export SMTP_USER=info@lucumaaglass.in
export SMTP_PASSWORD="Info123@@123"

# Kill existing backend processes
pkill -f "uvicorn server:app" || true
pm2 delete glass-backend 2>/dev/null || true

sleep 2

# Restart backend
if command -v pm2 &> /dev/null; then
  # Using PM2 with environment variables
  pm2 start venv/bin/uvicorn --name glass-backend -- server:app --host 0.0.0.0 --port 8000
  pm2 save
else
  # Using nohup
  nohup venv/bin/uvicorn server:app --host 0.0.0.0 --port 8000 > /tmp/backend.log 2>&1 &
fi

sleep 3

# Check if backend is running
curl -s http://localhost:8000/health
```

### Step 6: Deploy Updated Backend Code
From your local machine, run:
```bash
./deploy-backend-lucumaa-vps.sh
```

### Step 7: Verify Email System
Test forgot password:
1. Go to https://lucumaaglass.in/forgot-password
2. Enter a registered email
3. Check if password reset email arrives (check spam folder too)

Test order confirmation:
1. Create a test order
2. Check if confirmation email is sent

---

## 🧪 Testing Checklist:

### 1. Email System
- [ ] Password reset emails arrive
- [ ] Order confirmation emails arrive
- [ ] Job work order emails arrive
- [ ] Check spam folder if not in inbox

### 2. Order Tracking
- [ ] Visit https://lucumaaglass.in/track
- [ ] Enter an order number
- [ ] Should see order details (not 404)

### 3. Job Work Creation
- [ ] Visit https://lucumaaglass.in/job-work
- [ ] Fill in job work details
- [ ] Submit order
- [ ] Should create successfully

### 4. ERP Order Date Column
- [ ] Visit https://lucumaaglass.in/erp/orders
- [ ] Check if "Date" column appears
- [ ] Should show order creation date and time

---

## 📝 What Was Fixed:

### Backend (server.py):
```python
# BEFORE:
SMTP_USER = os.environ.get('SMTP_USER', 'info@lucumaaGlass.in')  # Wrong domain!
SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', '')  # Empty!

# AFTER:
SMTP_USER = os.environ.get('SMTP_USER', 'info@lucumaaglass.in')  # ✅ Correct
SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', 'Info123@@123')  # ✅ Set
```

### Frontend (OrderManagement.js):
Added date column to orders table showing:
- Date: dd MMM yyyy format
- Time: HH:mm format

---

## 🔍 Troubleshooting:

### If emails still not arriving:
1. Check backend logs:
   ```bash
   pm2 logs glass-backend
   # OR
   tail -f /tmp/backend.log
   ```

2. Test SMTP connection from VPS:
   ```bash
   cd /root/glass-deploy-20260107-190639/backend
   source venv/bin/activate
   python3 << 'PYEOF'
   import asyncio
   import aiosmtplib
   from email.message import EmailMessage
   
   async def test_smtp():
       msg = EmailMessage()
       msg["From"] = "info@lucumaaglass.in"
       msg["To"] = "test@example.com"
       msg["Subject"] = "Test Email"
       msg.set_content("This is a test email")
       
       try:
           await aiosmtplib.send(
               msg,
               hostname="smtp.hostinger.com",
               port=465,
               username="info@lucumaaglass.in",
               password="Info123@@123",
               use_tls=True
           )
           print("✅ Email sent successfully!")
       except Exception as e:
           print(f"❌ Error: {e}")
   
   asyncio.run(test_smtp())
   PYEOF
   ```

### If order tracking returns 404:
1. Check nginx is proxying /api/erp/customer correctly
2. Verify customer router is loaded in server.py
3. Check backend logs for routing errors

### If job work creation fails:
1. Check job_work_router is included in server.py
2. Verify /api/erp/job-work/orders endpoint exists
3. Check browser console for API errors

---

## 📧 SMTP Credentials:
- **Host**: smtp.hostinger.com
- **Port**: 465 (SSL/TLS)
- **Email**: info@lucumaaglass.in
- **Password**: Info123@@123

---

## ✅ Next Steps After Manual Deployment:
1. Test all email functionality
2. Verify order tracking works
3. Test job work creation
4. Check ERP order date column displays
5. Monitor backend logs for any errors

---

**Need Help?**
- Check backend logs: `pm2 logs glass-backend`
- Check nginx logs: `tail -f /var/log/nginx/error.log`
- Check application logs: `tail -f /tmp/backend.log`
