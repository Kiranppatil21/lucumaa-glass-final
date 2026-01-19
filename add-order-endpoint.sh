#!/bin/bash
# Add new endpoints to server.py on VPS

ssh -T root@147.79.104.84 << 'EOF'
cd /root/glass-deploy-20260107-190639/backend

# Backup server.py
cp server.py server.py.backup

# Add the with-design endpoint after line 1771 (after my-orders endpoint)
cat > /tmp/new_endpoint.py << 'ENDPOINT'

# =============== ORDER WITH 3D DESIGN ===============
@api_router.post("/orders/with-design")
async def create_order_with_design(
    data: dict,
    current_user: dict = Depends(get_current_user)
):
    """Create order and save associated 3D glass design"""
    import uuid
    from datetime import datetime, timezone
    
    # Generate unique IDs
    order_id = str(uuid.uuid4())
    glass_config_id = str(uuid.uuid4())
    
    # Save glass configuration first
    glass_config = data.get("glass_config", {})
    glass_config_doc = {
        "id": glass_config_id,
        "width_mm": glass_config.get("width_mm"),
        "height_mm": glass_config.get("height_mm"),
        "thickness_mm": glass_config.get("thickness_mm"),
        "glass_type": glass_config.get("glass_type"),
        "color_name": glass_config.get("color_name"),
        "application": glass_config.get("application"),
        "cutouts": glass_config.get("cutouts", []),
        "created_by": current_user.get("id"),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    await db.glass_configs.insert_one(glass_config_doc)
    
    # Create order with reference to glass config
    order_number = f"ORD-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"
    order_data = data.get("order_data", {})
    
    order_doc = {
        "id": order_id,
        "order_number": order_number,
        "user_id": current_user.get("id"),
        "customer_name": order_data.get("customer_name", current_user.get("name")),
        "customer_email": order_data.get("customer_email", current_user.get("email")),
        "customer_phone": order_data.get("customer_phone", ""),
        "glass_config_id": glass_config_id,
        "quantity": order_data.get("quantity", 1),
        "notes": order_data.get("notes", ""),
        "status": order_data.get("status", "pending"),
        "payment_status": "pending",
        "total_price": 0,
        "advance_amount": 0,
        "remaining_amount": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat()
    }
    
    await db.orders.insert_one(order_doc)
    
    return {
        "message": "Order created successfully with 3D design",
        "order_id": order_id,
        "order_number": order_number,
        "glass_config_id": glass_config_id
    }

# Enhanced my-orders to include designs
@api_router.get("/orders/my-orders-with-designs")
async def get_my_orders_with_designs(current_user: dict = Depends(get_current_user)):
    """Get orders for current user with 3D glass designs"""
    orders = await db.orders.find({"user_id": current_user['id']}, {"_id": 0}).to_list(100)
    
    # Populate glass configs
    for order in orders:
        if order.get("glass_config_id"):
            glass_config = await db.glass_configs.find_one(
                {"id": order["glass_config_id"]},
                {"_id": 0}
            )
            if glass_config:
                order["glass_config"] = glass_config
    
    return orders

ENDPOINT

# Insert the new endpoint before the last line
python3 << 'PYTHON'
with open("server.py", "r") as f:
    content = f.read()

# Find the position after my-orders endpoint
import re
pattern = r'(@api_router\.get\("/orders/my-orders"\).*?return orders)'
match = re.search(pattern, content, re.DOTALL)

if match:
    insert_pos = match.end()
    with open("/tmp/new_endpoint.py", "r") as nf:
        new_code = nf.read()
    
    new_content = content[:insert_pos] + "\n" + new_code + content[insert_pos:]
    
    with open("server.py", "w") as f:
        f.write(new_content)
    
    print("✅ Endpoints added successfully")
else:
    print("❌ Could not find insertion point")
PYTHON

# Restart PM2
pm2 restart glass-erp-backend
sleep 2
echo "✅ Backend restarted"
EOF
