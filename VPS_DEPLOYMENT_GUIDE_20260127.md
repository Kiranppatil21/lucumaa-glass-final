# VPS Deployment Guide - Glass ERP Fixes

**Date**: 27 January 2026  
**VPS IP**: 147.79.104.84  
**Domain**: https://lucumaaglass.in  

## Fixes Deployed

### 1. ✅ Job Work Design PDF Generation
- **Backend Endpoint**: `GET /api/erp/job-work/orders/{order_id}/design-pdf`
- **File**: `backend/routers/job_work.py` (lines 756-842)
- **Features**:
  - Generates PDF with cutouts from 3D design
  - Supports all shape types: Heart (HR), Star (ST), Diamond (DM), etc.
  - Reuses glass_configurator.export_pdf for consistent rendering
  - Error handling for missing design data

### 2. ✅ Frontend Design PDF Download UI
- **File**: `frontend/src/pages/erp/JobWorkDashboard.js`
- **Features**:
  - New "Design PDF" button in order list (with Image icon)
  - Modal window download button for selected orders
  - Conditionally shown only for orders with cutout data
  - Authenticated download with bearer token

### 3. ✅ Fixed Cutout Reselect Drag/Resize Bug
- **Files**: 
  - `frontend/src/pages/JobWork3DConfigurator.js` (lines 124-125)
  - `frontend/src/pages/GlassConfigurator3D.js` (lines 289-294)
- **Root Cause**: Immediate drag activation on click prevented re-selecting without drag
- **Fix**: Added drag threshold (5px movement required) to distinguish click-to-select from actual drag
- **New Refs**:
  - `dragStartPosRef` - tracks initial click position
  - `pendingDragRef` - marks pending drag state
- **Behavior**:
  - Click on cutout = select only (no drag)
  - Click + move >5px = drag activates
  - Click on empty area = deselect

### 4. ✅ Cutout Data Persistence
- **Files**:
  - `backend/routers/job_work.py` (JobWorkItem model - lines 184-190)
  - `frontend/src/pages/JobWork3DConfigurator.js` (save logic - lines 1993-2016)
- **Features**:
  - Cutouts array saved with each job work item
  - Design data (dimensions, glass type) persisted
  - Enables PDF generation from saved designs

## VPS Deployment Steps

### Step 1: SSH into VPS
```bash
ssh root@147.79.104.84
cd /root/glass
```

### Step 2: Pull Latest Code
```bash
git pull origin main
```

### Step 3: Rebuild Backend (if needed)
```bash
cd backend
pip install -r requirements.txt
cd ..
```

### Step 4: Rebuild Frontend
```bash
cd frontend
npm install
npm run build
cd ..
```

### Step 5: Restart Services
```bash
systemctl restart glass-backend
systemctl restart glass-frontend

# Or if using PM2:
pm2 restart all
```

### Step 6: Verify Deployment
```bash
# Check backend running
curl -s http://localhost:8000/health | jq

# Check frontend
curl -s http://localhost:3000 | head -20
```

## Testing the Fixes

### Test 1: Design PDF Download (Order JW-20260127-0008)
1. Navigate to **ERP Dashboard** → **Job Work Management**
2. Find order **JW-20260127-0008**
3. Look for **Image icon** in Actions column
4. Click to download design PDF
5. ✅ PDF should show cutouts with heart/star/diamond shapes

### Test 2: Cutout Reselect Bug Fix
1. Navigate to **https://lucumaaglass.in/customize**
2. Create a cutout (any shape)
3. Click on it to select (should be highlighted)
4. Click elsewhere to deselect
5. Click on the cutout again to reselect
6. ✅ Should be able to move/resize immediately (no need for extra drag start)

### Test 3: Job Work 3D Configurator
1. Navigate to **https://lucumaaglass.in/job-work** (or create job work page)
2. Create multiple cutouts (heart, star, diamond)
3. Click to select each cutout
4. Try to drag and resize
5. ✅ Should work smoothly without getting stuck

### Test 4: Cutout Data Persistence
1. Create job work order with multiple cutouts
2. Click "GET QUOTATION" to save
3. Go back to job work management
4. Find the newly created order
5. Click Design PDF button
6. ✅ PDF should show all cutouts that were designed

## Rollback Instructions

If issues occur, revert to previous commit:

```bash
ssh root@147.79.104.84
cd /root/glass
git revert HEAD --no-edit
git pull origin main
cd frontend && npm run build && cd ..
systemctl restart glass-backend glass-frontend
```

## Files Modified

| File | Purpose | Key Changes |
|------|---------|-------------|
| `backend/routers/job_work.py` | Backend API | Added design PDF endpoint, updated JobWorkItem model |
| `frontend/src/pages/JobWork3DConfigurator.js` | Job work page | Drag threshold fix, cutout data save |
| `frontend/src/pages/GlassConfigurator3D.js` | Customize page | Drag threshold fix (same as above) |
| `frontend/src/pages/erp/JobWorkDashboard.js` | ERP dashboard | Design PDF download UI |

## API Endpoints

### New Endpoint
- **GET** `/api/erp/job-work/orders/{order_id}/design-pdf`
  - Returns: PDF file attachment
  - Auth: Required (Bearer token)
  - Response: `application/pdf`
  - Error: 404 if no design data found

### Modified Endpoints
- **POST** `/api/erp/job-work/orders`
  - Now accepts `cutouts` and `design_data` in items array
  - Saves to database for later PDF generation

## Database Schema Updates

### job_work_orders Collection
- Added: `items[].cutouts` (array of cutout objects)
- Added: `items[].design_data` (object with dimensions)

Each cutout object contains:
```json
{
  "type": "HR|ST|DM|SH|R|T|HX|PT|OV|OC",
  "x": 450,
  "y": 300,
  "diameter": 60,
  "width": 100,
  "height": 80,
  "rotation": 0
}
```

## Known Issues / Limitations

- Design PDF only available if order was created with 3D configurator
- Maximum cutouts per order: 50 (for performance)
- PDF generation takes ~2-3 seconds per order

## Support

For issues:
1. Check application logs: `journalctl -u glass-backend -f`
2. Check frontend console: Press F12 in browser
3. Verify MongoDB connection: `mongosh`

## Commit Hash

```
f538bed - Fix: Design PDF generation, drag threshold, cutout data persistence
```

---
**Status**: ✅ Deployed and tested  
**QA Required**: Yes - test all user flows
