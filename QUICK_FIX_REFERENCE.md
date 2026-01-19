# ⚡ Quick Fix Reference Card

## 🚨 URGENT: Backend is Down (502 errors)

### Quick Restart (Copy & Paste on VPS):
```bash
cd /root/glass-deploy-20260107-190639/backend
pkill -f "uvicorn server:app" || true
pm2 delete glass-backend 2>/dev/null || true
source venv/bin/activate
pm2 start venv/bin/uvicorn --name glass-backend -- server:app --host 0.0.0.0 --port 8000
pm2 save
sleep 3
curl http://localhost:8000/health
```

---

## 📧 Email Not Working? Set SMTP Variables:

```bash
cd /root/glass-deploy-20260107-190639/backend
cat > .env << 'EOF'
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=465
SMTP_USER=info@lucumaaglass.in
SMTP_PASSWORD=Info123@@123
EOF
pm2 restart glass-backend
```

---

## 🧪 Test Everything:
```bash
# On VPS - check backend
curl http://localhost:8000/health

# From local machine - test all endpoints
./test-endpoints.sh
```

---

## 📋 Issues Fixed:

| Issue | Status | Action Required |
|-------|--------|-----------------|
| SMTP email typo | ✅ Fixed in code | Deploy backend |
| Empty SMTP password | ✅ Fixed in code | Deploy backend |
| Order date column | ✅ Deployed | None |
| Order tracking URL | ✅ Deployed | None |
| Job work endpoint | ✅ Exists | Test after restart |
| Backend service | 🔴 Down | **RESTART NOW** |

---

## 🎯 Priority Actions:

1. **First:** SSH to VPS and restart backend (see command above)
2. **Second:** Deploy backend: `./deploy-backend-lucumaa-vps.sh`
3. **Third:** Set SMTP env vars (see command above)
4. **Fourth:** Test: `./test-endpoints.sh`

---

## 📚 Full Documentation:

- Complete report: [COMPLETE_STATUS_REPORT.md](COMPLETE_STATUS_REPORT.md)
- Backend troubleshooting: [CRITICAL_BACKEND_DOWN.md](CRITICAL_BACKEND_DOWN.md)
- Manual deployment: [MANUAL_EMAIL_FIX_GUIDE.md](MANUAL_EMAIL_FIX_GUIDE.md)
- All fixes explained: [FIX_SUMMARY_EMAIL_AND_ENDPOINTS.md](FIX_SUMMARY_EMAIL_AND_ENDPOINTS.md)

---

## 🔑 Key Info:

**VPS:** root@147.79.104.84  
**Backend:** /root/glass-deploy-20260107-190639/backend  
**Domain:** https://lucumaaglass.in  
**SMTP:** info@lucumaaglass.in / Info123@@123  

---

## ✅ Success Criteria:

- [ ] `curl https://lucumaaglass.in/api/health` returns 200
- [ ] `pm2 status` shows glass-backend online
- [ ] Forgot password emails arrive
- [ ] Order confirmation emails arrive
- [ ] Order tracking works at /track
- [ ] Job work creation works at /job-work
- [ ] ERP orders show date column
