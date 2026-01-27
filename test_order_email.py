#!/usr/bin/env python3
"""Test order creation with email and PDF on live VPS"""
import requests
import json
import time

BASE_URL = "http://147.79.104.84"

print("=" * 60)
print("🧪 TESTING ORDER CREATION WITH EMAIL AND PDF")
print("=" * 60)

# Step 1: Login
print("\n📝 Step 1: Logging in...")
login_response = requests.post(
    f"{BASE_URL}/api/auth/login",
    json={
        "email": "admin@lucumaaglass.in",
        "password": "admin123"
    }
)

if login_response.status_code != 200:
    print(f"❌ Login failed: {login_response.text}")
    exit(1)

token = login_response.json()["token"]
print(f"✅ Login successful. Token: {token[:50]}...")

headers = {"Authorization": f"Bearer {token}"}

# Step 2: Create order with design
print("\n📝 Step 2: Creating order with design...")
order_data = {
    "customer_name": "Test Customer",
    "customer_email": "kiranpatil86@gmail.com",
    "customer_phone": "9876543210",
    "glass_config": {
        "width_mm": 1000,
        "height_mm": 800,
        "thickness_mm": 6,
        "glass_type": "tempered",
        "color_name": "clear",
        "application": "door",
        "cutouts": [
            {
                "type": "Heart",
                "shape": "heart",
                "x": 300,
                "y": 300,
                "diameter": 100
            },
            {
                "type": "Star",
                "shape": "star",
                "x": 600,
                "y": 300,
                "diameter": 100
            },
            {
                "type": "Hole",
                "shape": "circle",
                "x": 450,
                "y": 550,
                "diameter": 80
            }
        ]
    },
    "quantity": 1,
    "notes": "Test order with heart, star, and circle cutouts - Testing email PDF"
}

response = requests.post(
    f"{BASE_URL}/api/orders/with-design",
    json=order_data,
    headers=headers
)

print(f"Status: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    print(f"✅ Order created successfully!")
    print(f"   Order ID: {result.get('order_id')}")
    print(f"   Order Number: {result.get('order_number')}")
    print(f"   Amount: ₹{result.get('total_amount')}")
    
    order_id = result.get('order_id')
    order_number = result.get('order_number')
    
    # Wait for email to be sent
    print("\n⏳ Waiting 10 seconds for email to be sent...")
    time.sleep(10)
    
    # Step 3: Check backend logs for email status
    print("\n📝 Step 3: Checking email status in logs...")
    print("   ⏳ Check server logs on VPS for email send status")
    print(f"   Command: ssh root@147.79.104.84 'tail -50 /tmp/backend.log | grep -i email'")
    
    print("\n✅ Test order created successfully!")
    print(f"   Check your email: kiranpatil86@gmail.com")
    print(f"   Order Number: {order_number}")
    print(f"   Look for PDF attachment with cutout shapes (heart, star, circle)")
else:
    print(f"❌ Order creation failed: {response.text}")
    exit(1)
