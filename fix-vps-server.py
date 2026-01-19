#!/usr/bin/env python3
"""Fix server.py on VPS to properly add glass_3d router"""
import subprocess
import sys

VPS = "root@147.79.104.84"
SERVER_PATH = "/root/glass-deploy-20260107-190639/backend/server.py"

# Python script to run on VPS
fix_script = '''
import re

# Read server.py
with open("/root/glass-deploy-20260107-190639/backend/server.py", "r") as f:
    content = f.read()

# Remove any incorrectly placed glass_3d lines
content = re.sub(r'\\nfrom routers\\.glass_3d import router as glass_3d_router\\n', '', content)
content = re.sub(r'\\napp\\.include_router\\(glass_3d_router, prefix="/api"\\)\\n', '', content)

# Find the SEO router try block and add glass_3d after it  
pattern = r'(try:\\s+from routers\\.seo import sitemap_router\\s+app\\.include_router\\(sitemap_router\\)\\s+print\\("✅ SEO routes loaded.*?"\\)\\s+except Exception as e:\\s+print\\(f"❌ Failed to load SEO routes: \\{e\\}"\\))'

replacement = r'''\\1

# 3D Glass Modeling API
try:
    from routers.glass_3d import router as glass_3d_router
    app.include_router(glass_3d_router, prefix="/api")
    print("✅ 3D Glass modeling router loaded successfully")
except Exception as e:
    print(f"❌ Failed to load 3D Glass router: {e}")'''

content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back
with open("/root/glass-deploy-20260107-190639/backend/server.py", "w") as f:
    f.write(content)

print("✅ server.py fixed")
'''

print("🔧 Fixing server.py on VPS...")
result = subprocess.run(
    ["ssh", VPS, f"python3 -c '{fix_script}' && pm2 restart glass-erp-backend && sleep 3 && curl -s http://localhost:8000/api/glass-3d/formats"],
    capture_output=True,
    text=True
)

print(result.stdout)
if result.stderr:
    print(result.stderr, file=sys.stderr)

sys.exit(result.returncode)
