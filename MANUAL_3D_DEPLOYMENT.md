# Manual Deployment Guide for 3D Glass API

## Step 1: SSH to VPS
```bash
ssh root@147.79.104.84
```

## Step 2: Navigate to backend directory
```bash
cd /root/glass-deploy-20260107-190639/backend
```

## Step 3: Edit server.py to add glass_3d router
```bash
nano server.py
```

Find this section (around line 1969):
```python
# SEO Routes (sitemap, robots.txt, RSS)
try:
    from routers.seo import sitemap_router
    app.include_router(sitemap_router)
    print("✅ SEO routes loaded (sitemap, robots.txt, RSS)")
except Exception as e:
    print(f"❌ Failed to load SEO routes: {e}")
```

Add this AFTER it:
```python
# 3D Glass Modeling API
try:
    from routers.glass_3d import router as glass_3d_router
    app.include_router(glass_3d_router, prefix="/api")
    print("✅ 3D Glass modeling router loaded successfully")
except Exception as e:
    print(f"❌ Failed to load 3D Glass router: {e}")
```

Save: `Ctrl+X`, then `Y`, then `Enter`

## Step 4: Restart backend
```bash
pm2 restart glass-erp-backend
```

## Step 5: Test the API
```bash
# Test locally
curl http://localhost:8000/api/glass-3d/formats

# Test from your laptop
curl https://lucumaaglass.in/api/glass-3d/formats
```

## Expected Output:
```json
{
    "formats": [
        {"id": "stl", "name": "STL", ...},
        {"id": "obj", "name": "Wavefront OBJ", ...},
        {"id": "ply", "name": "PLY", ...},
        {"id": "json", "name": "JSON", ...}
    ]
}
```

## Test 3D Generation:
```bash
curl -X POST https://lucumaaglass.in/api/glass-3d/generate \
  -H "Content-Type: application/json" \
  -d '{"width":1000,"height":800,"thickness":10,"cutouts":[{"shape":"circle","x":500,"y":400,"diameter":100}],"export_format":"stl"}'
```

### Multiple Cutouts Test (Circle + Rectangle):
```bash
curl -X POST https://lucumaaglass.in/api/glass-3d/generate \
  -H "Content-Type: application/json" \
  -d '{
    "width": 1000,
    "height": 800,
    "thickness": 10,
    "cutouts": [
      {"shape": "circle", "x": 300, "y": 400, "diameter": 80},
      {"shape": "rectangle", "x": 700, "y": 400, "width": 120, "height": 60}
    ],
    "export_format": "stl"
  }' | python3 -c "import sys,json,base64; d=json.load(sys.stdin); open('glass.stl','wb').write(base64.b64decode(d['file_data'])); print(f'✅ Downloaded glass.stl - Volume: {d[\"volume_mm3\"]:.0f} mm³, Weight: {d[\"weight_kg\"]:.2f} kg')"
```

### View the 3D Model:
1. Open https://www.viewstl.com/
2. Drag and drop the `glass.stl` file into browser
3. See the 3D glass with cutouts!

## Summary of what's deployed:
✅ glass_3d.py router uploaded to /root/glass-deploy-20260107-190639/backend/routers/
✅ PyVista 0.44.2 + VTK 9.3.1 installed on VPS
✅ OpenSCAD 2021.01 installed for geometry processing
✅ Boolean operations working (clean + triangulate approach)
✅ Multiple cutouts supported (tested: circle + rectangle)
✅ Volume calculations accurate (0.18% error)
✅ Frontend integration complete (STL/OBJ export buttons added)

## Frontend Integration:
The GlassConfigurator3D.js now includes:
- **STL Export** button (blue) - Download 3D model in STL format
- **OBJ Export** button (teal) - Download 3D model in OBJ format  
- **PDF Export** button (orange) - Download specification sheet
- Automatic volume and weight calculation display in toast message

### Rebuild Frontend (Optional):
```bash
cd /Users/admin/Desktop/Glass/frontend
REACT_APP_BACKEND_URL=https://lucumaaglass.in npm run build
# Then copy build/ to VPS
```

## API Endpoints:
- **GET** `/api/glass-3d/formats` - List available export formats
- **POST** `/api/glass-3d/generate` - Generate 3D model

## Supported Cutout Shapes:
- ✅ `circle` - Circular holes (diameter parameter)
- ✅ `rectangle`/`square` - Rectangular cutouts (width, height parameters)
- 🔄 `triangle` - Triangular cutouts (not yet in trimesh version)
- 🔄 `hexagon` - Hexagonal cutouts (not yet implemented)
- 🔄 `heart` - Heart-shaped cutouts (not yet implemented)

## Test Results:
**Single Cutout (Circle ø100mm):**
- Original: 8,000,000 mm³
- With cutout: 7,921,964 mm³
- Expected: 7,921,460 mm³
- Error: 0.01% ✅

**Multiple Cutouts (Circle ø80mm + Rectangle 120×60mm):**
- Original: 8,000,000 mm³
- With cutouts: 7,891,698 mm³
- Expected: 7,877,735 mm³
- Error: 0.18% ✅
