# 🚀 Manual VPS Deployment Guide
## Pagination & PDF Fixes - 26 January 2026

### Quick Summary of Changes

Three main improvements deployed:

1. ✅ **Server-side pagination** on `/erp/orders` page
   - Now shows 20 orders per page instead of 1000+
   - Dramatically improves page load performance

2. ✅ **Better PDF shape rendering** with proper 2-decimal coordinates
   - Supports 10+ shape types (circle, triangle, star, heart, etc.)
   - Coordinates always shown as X.XX format

3. ✅ **Server-side search** for orders
   - Search by order number, customer name, company, email
   - Filters apply before pagination for accurate counts

---

## 📋 Deployment Steps

### Step 1: SSH into VPS
```bash
ssh root@147.79.104.84
# or if using key:
ssh -i your_private_key root@147.79.104.84
```

### Step 2: Navigate to Application Directory
```bash
# Find the Glass app directory
cd /var/www/glass
# OR
cd /home/glass
# OR if not exists, create it:
mkdir -p /var/www/glass && cd /var/www/glass
```

### Step 3: Pull Latest Code from GitHub
```bash
# If git repo already exists:
git pull origin main

# OR if first time:
git clone https://github.com/Kiranppatil21/lucumaa-glass-final.git .
```

Expected output:
```
From https://github.com/Kiranppatil21/lucumaa-glass-final
 * branch            main       -> FETCH_HEAD
Already up to date.
# OR shows files changed if updates available
```

### Step 4: Restart Backend Service

**Option A: Using PM2 (Recommended)**
```bash
cd /var/www/glass/backend
pm2 restart backend

# OR if not running:
pm2 start "python -m uvicorn server:app --host 0.0.0.0 --port 8000" --name backend

# Verify it's running:
pm2 status backend
```

**Option B: Manual Restart**
```bash
cd /var/www/glass/backend
# Stop current process (Ctrl+C if running in foreground)
# OR kill the process:
pkill -f "uvicorn server:app"
sleep 2

# Start backend
python -m uvicorn server:app --host 0.0.0.0 --port 8000 &
```

### Step 5: Build and Deploy Frontend

```bash
cd /var/www/glass/frontend

# Install dependencies
npm install --legacy-peer-deps

# Build production bundle
npm run build

# Copy to web server directory
sudo cp -r build/* /var/www/html/
# OR
sudo cp -r build/* /var/www/lucumaa-glass-frontend/
```

---

## ✅ Verification

### Backend Health Check
```bash
# Test health endpoint
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","service":"lucumaa-glass-backend"}
```

### Frontend Check
```bash
# Navigate to your domain:
# https://lucumaaglass.in/erp/orders

# Verify:
# 1. Page loads without errors
# 2. Shows "Showing 1 to 20 of XXX orders" at bottom
# 3. Pagination controls present
```

### Pagination API Test
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://lucumaaglass.in/api/admin/orders?page=1&limit=20&status=pending&search=ORD"
```

Expected response structure:
```json
{
  "orders": [
    {
      "id": "...",
      "order_number": "ORD-20260126-...",
      "customer_name": "...",
      "status": "pending",
      ...
    }
  ],
  "total": 1234,
  "page": 1,
  "limit": 20,
  "total_pages": 62
}
```

### PDF Generation Test
1. Go to: `https://lucumaaglass.in/erp/orders`
2. Find an order with glass designs
3. Click "Design" → "Download Design (PDF)"
4. Verify PDF shows:
   - All cutout shapes render correctly
   - Coordinates in format: `(X.XX, Y.XX)` (2 decimals)
   - Size in format: `Ø 20.00` or `100.00 × 50.00`
   - Edges in format: `123.45 / 234.56 / 345.67 / 456.78`

---

## 🔄 Rollback (If Issues Occur)

```bash
cd /var/www/glass

# Reset to previous version
git reset --hard HEAD~1

# Restart backend
cd backend
pm2 restart backend
```

---

## 📊 Key Changes Made

### Backend Changes (`backend/server.py`)

**New imports added:**
```python
import re  # For search regex
from math import sin, cos, pi  # For shape calculations
```

**Updated endpoint:** `GET /api/admin/orders`
```python
# New parameters:
- page: int = 1 (page number, default 1)
- limit: int = 20 (items per page, max 200)
- status: Optional[str] = None (filter by status)
- search: Optional[str] = None (search orders)

# Returns:
{
  "orders": [...20 items...],
  "total": total_count_matching_filters,
  "page": 1,
  "limit": 20,
  "total_pages": calculated_total_pages
}
```

**Enhanced PDF generation:** `/api/glass-configs/{config_id}/pdf`
- Supports shapes: circle, rectangle, square, triangle, diamond, oval, pentagon, hexagon, octagon, star, heart
- Coordinates rounded to 2 decimals (`.2f` format)
- Edge distances calculated and displayed
- Color-coded shapes for better visualization

### Frontend Changes (`frontend/src/pages/erp/OrderManagement.js`)

**New state variables:**
```javascript
const [totalPages, setTotalPages] = useState(1);
const [totalOrders, setTotalOrders] = useState(0);
const [debouncedSearch, setDebouncedSearch] = useState('');
```

**Debounced search:**
- 300ms delay before making API request
- Reduces server load from rapid typing

**Server-side pagination:**
- No longer loads all 1000+ orders at once
- Respects page/limit parameters from API
- Shows accurate "Showing X to Y of Z orders"

---

## 🐛 Troubleshooting

### Issue: Backend won't start
```bash
# Check if port 8000 is in use:
lsof -i :8000

# Kill existing process:
kill -9 PID

# Try starting again:
cd /var/www/glass/backend
python -m uvicorn server:app --host 0.0.0.0 --port 8000
```

### Issue: Frontend builds fail
```bash
# Clear npm cache:
npm cache clean --force

# Delete node_modules:
rm -rf node_modules

# Reinstall:
npm install --legacy-peer-deps

# Try build again:
npm run build
```

### Issue: Orders page won't load
```bash
# Check browser console (F12) for errors
# Most likely: Authorization header issue or CORS

# Test API directly:
curl -H "Authorization: Bearer TOKEN" \
  https://lucumaaglass.in/api/admin/orders?page=1&limit=20
```

---

## 📝 Files Changed

```
✅ backend/server.py
   - Lines 1-21: Added imports (re, math)
   - Lines 2636-2680: Updated /api/admin/orders endpoint
   - Lines 2400-2600: Enhanced PDF generation

✅ frontend/src/pages/erp/OrderManagement.js
   - Lines 35-80: Added state for pagination
   - Lines 95-150: Refactored fetchOrders function
   - Lines 470-490: Removed client-side filtering
   - Lines 715-745: Updated pagination display
```

---

## 🎯 Testing Checklist

- [ ] Backend starts without errors
- [ ] Frontend builds successfully
- [ ] Orders page loads with pagination
- [ ] Search box filters results server-side
- [ ] Status dropdown filters correctly
- [ ] "Showing X to Y of Z" displays accurately
- [ ] PDF exports with proper 2-decimal coordinates
- [ ] All shape types render in PDF
- [ ] No console errors in browser

---

## 📞 Support

If deployment fails:
1. Check application logs: `pm2 logs backend`
2. Verify git has latest code: `git log --oneline | head -5`
3. Test API health: `curl http://localhost:8000/health`
4. Contact development team with error details

---

**Status**: ✅ Ready for Production
**Commit**: 753b71a - "Fix: Add pagination to admin orders, improve PDF cutout rendering..."
**Deployed**: 26 January 2026

