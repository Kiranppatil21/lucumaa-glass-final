# Quick Test Guide - Heart, Triangle & PDF Export

## 🚀 Ready to Test (Both servers running!)
- ✅ Frontend: http://localhost:3000
- ✅ Backend: http://localhost:8000

## Test 1: Heart Shape Display ❤️

1. **Open**: http://localhost:3000/customize
2. **Steps**:
   - Set glass: 900mm × 600mm
   - Click "Add Cutout" → Select **Heart** (❤️ icon)
   - ✅ **Expected**: Should see proper heart shape (not a circle!)
   - Try dragging it around
   - Try resizing it
   - ✅ **Expected**: Maintains heart shape while resizing

## Test 2: Triangle Shape Display 🔺

1. **Open**: http://localhost:3000/customize
2. **Steps**:
   - Click "Add Cutout" → Select **Triangle** (🔺 icon)
   - ✅ **Expected**: Should see triangular shape pointing up
   - Try dragging and resizing
   - ✅ **Expected**: Keeps triangle form

## Test 3: PDF Export 📄

### Scenario A: Normal Export (Should Work!)
1. **Setup**:
   - Glass: 900mm × 600mm, 8mm thick
   - Add 2-3 cutouts (any shapes including heart & triangle)
2. **Export**:
   - Click "Export PDF" button
   - ✅ **Expected**: Downloads PDF file `glass_specification_[timestamp].pdf`
   - ✅ **Expected**: Toast shows "PDF exported successfully!"

### Scenario B: Missing Dimensions (Should Show Error)
1. **Setup**:
   - Clear/don't set glass dimensions
   - Add some cutouts
2. **Export**:
   - Click "Export PDF"
   - ✅ **Expected**: Toast shows "Please set valid glass dimensions"
   - ✅ **Expected**: No PDF download

### Scenario C: Backend Error (Testing Error Handling)
1. Stop backend: `lsof -ti :8000 | xargs kill -9`
2. Try PDF export
3. ✅ **Expected**: Toast shows "Error exporting PDF: Network error" or "Failed to fetch"
4. Restart backend:
   ```bash
   cd /Users/admin/Desktop/Glass/backend
   /Users/admin/Desktop/Glass/.venv/bin/python -m uvicorn server:app --reload --host 0.0.0.0 --port 8000 &
   ```

## Test 4: Job Work Tool (Same Fixes)

Repeat all tests at: http://localhost:3000/job-work
- ✅ Heart shape should work
- ✅ Triangle shape should work
- ✅ PDF export should work with proper errors

## Visual Comparison

### Before Fix:
- Heart = Circle (wrong!) ⭕
- Triangle = Box or invisible (broken!) ❌
- PDF error = "Failed to export PDF" (no details) 😕

### After Fix:
- Heart = Proper heart shape ❤️
- Triangle = Proper triangle 🔺
- PDF error = "Failed to export PDF: [specific reason]" (helpful!) ✅

## Browser Console (F12)

If issues occur, check console for detailed logs:
```
PDF export error: { error: "..." }
PDF export failed: [Error details]
Triangle extrude failed, using simple mesh: [error]
```

## Success Indicators ✅

You should see:
1. ❤️ Heart shape looks like a real heart (curved top, pointy bottom)
2. 🔺 Triangle is a proper triangle (3 sides, pointy top)
3. 📄 PDF downloads with proper filename
4. 📍 Edge distance labels show real-time updates (from previous fix)
5. 💬 Clear error messages if something goes wrong

## If You See Issues

### Heart still looks like circle:
- Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+F5 (Windows)
- Check browser console for errors
- Verify hot reload picked up changes

### PDF export fails:
1. Check backend is running: `curl http://localhost:8000/health`
2. Check browser console (F12) for error details
3. Verify glass dimensions are set (>0)
4. Check network tab for API response

### Shapes not visible:
- Try adding shape again (delete and re-add)
- Check if shape is off-screen (zoom out)
- Verify cutout is added to list (check sidebar)

---
**All fixes applied and ready to test!** 🎉
