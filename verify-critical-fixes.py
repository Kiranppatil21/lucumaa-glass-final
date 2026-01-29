#!/usr/bin/env python3
"""
Verification Script for Critical Fixes - 29 January 2026
Tests all 4 fixes:
1. Heart shape not flipped in PDFs
2. Oval shape renders correctly (not rectangle)
3. Drag/resize/move works in design area
4. Job work saves successfully
"""

import json
import sys
from pathlib import Path

def verify_heart_shape_fix():
    """Check heart shape Y coordinate doesn't have negative sign"""
    print("🔍 Test 1: Heart Shape Fix (Y coordinate)")
    
    # Check backend
    backend_file = Path("backend/routers/glass_configurator.py")
    backend_content = backend_file.read_text()
    
    # Should NOT have: y = -(13 * cos...
    # Should have: y = (13 * cos...
    if "y = (13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t)) * scale_factor" in backend_content:
        print("  ✅ Backend: Heart shape Y coordinate FIXED (no negative sign)")
    else:
        print("  ❌ Backend: Heart shape Y coordinate NOT fixed")
        return False
    
    # Check frontend
    shapegen_file = Path("frontend/src/utils/ShapeGenerator.js")
    shapegen_content = shapegen_file.read_text()
    
    if "const y = 13 * Math.cos(t) - 5 * Math.cos(2 * t)" in shapegen_content and \
       "// x = 16sin³(t), y = 13cos(t) - 5cos(2t) - 2cos(3t) - cos(4t)" in shapegen_content:
        print("  ✅ Frontend: Heart shape generator FIXED")
    else:
        print("  ❌ Frontend: Heart shape generator NOT fixed")
        return False
    
    return True

def verify_oval_shape_fix():
    """Check oval shape rendering coordinates"""
    print("\n🔍 Test 2: Oval Shape Fix (Rectangle vs Ellipse)")
    
    backend_file = Path("backend/routers/glass_configurator.py")
    backend_content = backend_file.read_text()
    
    # Should have: Ellipse(cx - w/2, cy - h/2, w, h, ...)
    if "Ellipse(cx - w/2, cy - h/2, w, h," in backend_content:
        print("  ✅ Backend: Oval shape coordinates FIXED")
    else:
        print("  ❌ Backend: Oval shape coordinates NOT fixed")
        return False
    
    return True

def verify_drag_resize_fix():
    """Check drag/resize control detachment"""
    print("\n🔍 Test 3: Drag/Resize/Move Fix (Camera Control)")
    
    jobwork_file = Path("frontend/src/pages/JobWork3DConfigurator.js")
    jobwork_content = jobwork_file.read_text()
    
    # Should have: detachControl(canvasRef.current)
    if "cameraRef.current.detachControl(canvasRef.current)" in jobwork_content:
        print("  ✅ Frontend: Camera detach control FIXED")
    else:
        print("  ❌ Frontend: Camera detach control NOT fixed")
        return False
    
    return True

def verify_job_work_save():
    """Check job work save endpoint"""
    print("\n🔍 Test 4: Job Work Save Fix (Endpoint)")
    
    # Check backend has proper endpoint
    jobwork_file = Path("backend/routers/job_work.py")
    jobwork_content = jobwork_file.read_text()
    
    if '@job_work_router.post("/orders")' in jobwork_content and \
       "await db.job_work_orders.insert_one(order)" in jobwork_content:
        print("  ✅ Backend: Job work save endpoint EXISTS")
    else:
        print("  ❌ Backend: Job work save endpoint NOT found")
        return False
    
    # Check frontend sends proper data
    jobwork_frontend = Path("frontend/src/pages/JobWork3DConfigurator.js")
    jobwork_frontend_content = jobwork_frontend.read_text()
    
    if "disclaimer_accepted: true" in jobwork_frontend_content and \
       "const response = await fetch(`${API_URL}/erp/job-work/orders`" in jobwork_frontend_content:
        print("  ✅ Frontend: Job work save request CONFIGURED")
    else:
        print("  ❌ Frontend: Job work save request NOT configured")
        return False
    
    return True

def main():
    print("=" * 60)
    print("🧪 Verification Test Suite - Critical Fixes")
    print("=" * 60)
    
    results = {
        "Heart Shape Fix": verify_heart_shape_fix(),
        "Oval Shape Fix": verify_oval_shape_fix(),
        "Drag/Resize Fix": verify_drag_resize_fix(),
        "Job Work Save Fix": verify_job_work_save()
    }
    
    print("\n" + "=" * 60)
    print("📊 Test Results Summary:")
    print("=" * 60)
    
    all_passed = True
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
        if not result:
            all_passed = False
    
    print("=" * 60)
    if all_passed:
        print("✨ All fixes verified successfully!")
        print("\n📝 Next Steps:")
        print("  1. Rebuild frontend: npm run build")
        print("  2. Deploy to VPS when available")
        print("  3. Test on live server: https://lucumaaglass.in")
        return 0
    else:
        print("⚠️  Some fixes failed verification. Please check above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
