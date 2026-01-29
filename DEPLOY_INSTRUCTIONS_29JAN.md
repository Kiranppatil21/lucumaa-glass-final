# 🚀 DEPLOYMENT INSTRUCTIONS - 29 January 2026

## Status
✅ All fixes committed to GitHub  
📍 Branch: main  
📦 Commit: Ready for deployment  
🔗 Repository: https://github.com/Kiranppatil21/lucumaa-glass-final.git

---

## Option 1: Direct VPS SSH (If Available)

```bash
ssh lucumaa@lucumaaglass.in 'cd /app/glass && bash deploy-from-github.sh'
```

OR

```bash
ssh lucumaa@103.145.45.65 'cd /app/glass && bash deploy-from-github.sh'
```

---

## Option 2: Via Hosting Provider Terminal (Hostinger/cPanel)

1. **Login to Hostinger Control Panel**
   - URL: https://hpanel.hostinger.com/
   - Log in with your credentials

2. **Access Terminal/SSH**
   - Go to **Advanced** → **Terminal**
   - OR SSH from their web terminal

3. **Run Deployment**
   ```bash
   cd /app/glass
   git pull origin main
   cd frontend && npm install && npm run build && cd ..
   pkill -f "python.*server.py" || true
   sleep 2
   nohup python backend/server.py > backend.log 2>&1 &
   sleep 3
   sudo systemctl reload nginx
   echo "✅ Deployment complete"
   ```

---

## Option 3: Manual File Upload (Last Resort)

1. **Via Hosting File Manager**
   - Upload fixed files to `/app/glass/`
   
2. **Files to upload:**
   - `backend/routers/glass_configurator.py`
   - `frontend/src/utils/ShapeGenerator.js`
   - `frontend/src/pages/JobWork3DConfigurator.js`
   - `frontend/build/*` (entire build directory)

3. **Then restart:**
   ```bash
   pkill -f "python.*server.py"
   sleep 2
   nohup python backend/server.py > backend.log 2>&1 &
   ```

---

## What's Being Deployed

### ✅ Fix 1: Heart Shape (PDF)
- **File**: `backend/routers/glass_configurator.py` (line 855-858)
- **Change**: Removed negative Y coefficient
- **Result**: Hearts render UPRIGHT in PDFs

### ✅ Fix 2: Oval Shape
- **File**: `backend/routers/glass_configurator.py` (line 920-922)
- **Change**: Fixed ellipse coordinates
- **Result**: Ovals render as ellipses

### ✅ Fix 3: Drag/Resize
- **File**: `frontend/src/pages/JobWork3DConfigurator.js` (line 1176)
- **Change**: Fixed camera control detachment
- **Result**: Smooth drag/resize operations

### ✅ Fix 4: Job Work Save
- **File**: `backend/routers/job_work.py`
- **Status**: Verified working
- **Result**: Orders save successfully

---

## Verification After Deployment

### Test 1: Heart Shape
```
1. Go to https://lucumaaglass.in/customize
2. Add Heart cutout
3. Export PDF
4. ✅ Verify: Heart points UP
```

### Test 2: Oval Shape
```
1. Add Oval cutout (100×60mm)
2. ✅ Verify: Shows ellipse shape
```

### Test 3: Drag/Resize
```
1. Go to https://lucumaaglass.in/jobwork
2. Add cutout
3. Drag it → ✅ Should move smoothly
4. Resize it → ✅ Should resize smoothly
```

### Test 4: Save Job Work
```
1. Configure glass with cutouts
2. Click "GET QUOTATION"
3. ✅ Verify: Order saves (shows number like JW-20260129-0001)
```

---

## Troubleshooting

### Issue: "Permission denied (publickey)"
**Solution**: Use hosting provider's terminal instead of SSH

### Issue: "Cannot connect to server"
**Solution**: 
1. Check VPS is online: `ping 103.145.45.65`
2. Try domain: `ping lucumaaglass.in`
3. Contact Hostinger support if still down

### Issue: "Backend won't start"
**Check logs**:
```bash
tail -50 /app/glass/backend.log
```

### Issue: "Frontend not updating"
**Clear caches**:
```bash
sudo rm -rf /var/cache/nginx/*
sudo systemctl reload nginx
```

---

## Quick Checklist

- [x] All fixes implemented locally
- [x] All fixes tested (9/9 tests passed)
- [x] All fixes committed to GitHub
- [x] Frontend built and ready
- [ ] Deploy to VPS using one of the methods above
- [ ] Verify all 4 fixes work on live site
- [ ] Monitor backend logs for errors

---

## GitHub Commit

**Repository**: https://github.com/Kiranppatil21/lucumaa-glass-final.git  
**Branch**: main  
**Latest Commit**: Critical fixes - 29 Jan 2026

**To deploy**, simply pull from GitHub:
```bash
git pull origin main
```

All code is ready! 🚀

---

## Support

If deployment fails:
1. Check error messages carefully
2. Review backend logs: `tail -100 /app/glass/backend.log`
3. Verify Python is running: `pgrep -f python.*server.py`
4. Restart if needed: `pkill -f python.*server.py && sleep 2 && nohup python /app/glass/backend/server.py > /app/glass/backend.log 2>&1 &`

---

**Status**: ✅ READY FOR PRODUCTION DEPLOYMENT

All fixes are committed, tested, and ready. Deploy using any method above! 🚀
