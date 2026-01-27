# ⚡ Quick Reference - Glass ERP Latest Features

## 🎯 What Changed

### 1. Job Work Design Preview (NEW)
- **Location**: Job Work Dashboard → Click on order → See "Design Preview" section
- **What it shows**: Visual preview of glass with all cutout shapes rendered
- **Shapes**: Heart (pink), Star (amber), Diamond (orange), Circle (blue)
- **Visual**: SVG canvas showing exact cutout positions and sizes

### 2. Design PDF Download (REPLACED JSON)
- **Location**: Job Work Dashboard → Click on order → "Download Design PDF" button
- **Old way**: Downloaded JSON file
- **New way**: Downloads PDF file with proper shape rendering
- **Format**: `design_JW-XXXXXXXX-XXXX.pdf`
- **File has**: Exact dimensions, all cutout shapes properly drawn

### 3. Shape Rendering Fixed
- **Issue**: Shapes were showing as circles
- **Solution**: Now renders Heart, Star, Diamond with proper SVG paths
- **Where**: Design preview SVG + PDF generation + 3D configurator

### 4. Cutout Drag/Resize Fixed
- **Issue**: Once you select a cutout, you couldn't drag it immediately
- **Solution**: 5px movement threshold before drag activates
- **Result**: Select cutout → immediately drag/resize works smoothly

---

## 🔗 Direct Links

| Feature | URL |
|---------|-----|
| Job Work Orders | https://lucumaaglass.in/erp/job-work |
| Glass Configurator | https://lucumaaglass.in/customize |
| Admin Dashboard | https://lucumaaglass.in/erp/dashboard |
| API Health | https://lucumaaglass.in/api/health |

---

## 🧪 Quick Test

1. **View Order with Cutouts**
   ```
   1. Go to https://lucumaaglass.in/erp/job-work
   2. Click on any order with cutouts
   3. Look for "Design Preview" section with colored shapes
   4. Should see: heart (pink), star (amber), diamond (orange), circle (blue)
   ```

2. **Download Design PDF**
   ```
   1. In same modal, click "Download Design PDF" button
   2. File downloads as design_JW-XXXXXXXX-XXXX.pdf
   3. Open PDF - should show glass outline with shapes rendered
   ```

3. **Create Order with Cutouts**
   ```
   1. Go to https://lucumaaglass.in/customize
   2. Select glass and add cutouts (heart, star, diamond)
   3. Save order
   4. Go back to job work orders
   5. Find new order, open, verify design preview displays
   6. Download PDF and verify shapes render correctly
   ```

4. **Test Drag/Resize**
   ```
   1. Go to https://lucumaaglass.in/customize
   2. Add a cutout shape
   3. Click to select the cutout (highlight appears)
   4. Immediately try to drag it
   5. Should move smoothly without getting stuck
   ```

---

## 📊 API Endpoints

### New Endpoint
```
GET /api/erp/job-work/orders/{order_id}/design-pdf
Authorization: Bearer {token}
Response: PDF file (application/pdf)
```

### Example
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://lucumaaglass.in/api/erp/job-work/orders/12345/design-pdf \
  -o design.pdf
```

---

## 🛠️ System Status

| Component | Status | Details |
|-----------|--------|---------|
| Backend API | ✅ Running | Uvicorn on port 8000 |
| Frontend | ✅ Running | Nginx serving build |
| Database | ✅ Connected | MongoDB 27017 |
| SSL/HTTPS | ✅ Active | Certificate valid |

---

## 📚 Code Locations

### Frontend
- **Design Preview**: `frontend/src/pages/erp/JobWorkDashboard.js` (lines 601-656)
- **PDF Download**: `frontend/src/pages/erp/JobWorkDashboard.js` (lines 115-148)
- **Drag Fix**: `frontend/src/pages/JobWork3DConfigurator.js` & `GlassConfigurator3D.js`

### Backend
- **Design PDF Endpoint**: `backend/routers/job_work.py` (lines 755-842)
- **Shape Rendering**: Uses `glass_configurator.export_pdf()`

### Database
- **Job Work Collection**: `job_work_orders`
- **Cutout Data**: `items[0].cutouts` array
- **Design Data**: `items[0].design_data` object

---

## 🎨 Shape Type Codes

| Type | Code | Display |
|------|------|---------|
| Heart | `HR` | Pink bezier curve |
| Star | `ST` | Amber 10-point polygon |
| Diamond | `DM` | Orange 4-point rotated |
| Circle/Hole | `SH` | Blue circle |
| Hexagon | `HX` | Purple 6-point |
| Rectangle | `R` | Not in preview (glass only) |
| Triangle | `T` | Gray 3-point |

---

## ⚙️ Configuration

### Design Preview SVG
- **Canvas**: 900x600px (scaled to fit)
- **Glass**: Light blue rectangle with dashed border
- **Scaling**: 0.85x to fit in preview area
- **Colors**: Fixed per shape type (see above)

### PDF Generation
- **Format**: A4 or custom size based on glass dimensions
- **Scale**: Automatic scaling for readability
- **Shapes**: Rendered using reportlab polygons and paths
- **Quality**: Vector-based (infinitely scalable)

---

## 🔒 Authentication

- **Required**: Yes, for PDF download
- **Token**: Bearer token in Authorization header
- **Source**: Login or admin panel
- **Expiry**: Based on system settings

---

## 📞 Support

### Check Logs
```bash
# Backend logs
ssh root@147.79.104.84 'journalctl -u glass-backend -n 50'

# Frontend logs
Check browser console (F12) → Console tab

# System logs
ssh root@147.79.104.84 'tail -f /var/log/nginx/access.log'
```

### Common Issues
- **Design preview not showing**: Order must have `cutouts` array
- **PDF download fails**: Check token validity and backend status
- **Shapes not rendering**: Verify shape type code is correct

---

## 🚀 Deployment Commands

```bash
# On VPS, to redeploy:
cd /root/glass-deploy-20260107-190639
git fetch origin main
git reset --hard origin/main
cd frontend && npm run build && cd ..
systemctl restart glass-backend
```

---

## ✅ Verification Checklist

- [ ] Design preview shows colored shapes (pink heart, amber star, orange diamond, blue circle)
- [ ] PDF download button works and generates file
- [ ] Downloaded PDF contains glass outline and shapes
- [ ] Can select and immediately drag cutouts in configurator
- [ ] New orders save cutout data correctly
- [ ] No console errors when loading job work dashboard
- [ ] Services show as "running" in systemd

---

**Last Updated**: January 27, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Live
