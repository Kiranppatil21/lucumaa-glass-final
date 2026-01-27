#!/usr/bin/env python3
import requests
import json

BASE = 'http://147.79.104.84:8000'

print("\n" + "="*60)
print("TESTING ALL FIXES - Jan 27, 2026")
print("="*60)

# Test 1: Login
print("\n[TEST 1] Login")
r = requests.post(f'{BASE}/api/auth/login', json={'email':'admin@lucumaaglass.in','password':'admin123'}, timeout=10)
if r.status_code == 200:
    token = r.json().get('token')
    h = {'Authorization': f'Bearer {token}'}
    print("✓ LOGIN SUCCESSFUL")
else:
    print(f"✗ LOGIN FAILED: {r.status_code}")
    exit(1)

# Test 2: Check pagination (default 10)
print("\n[TEST 2] Pagination (should default to 10 items)")
r = requests.get(f'{BASE}/api/admin/orders?page=1', headers=h, timeout=10)
if r.status_code == 200:
    data = r.json()
    orders_count = len(data.get('data', []))
    if orders_count <= 10:
        print(f"✓ PAGINATION OK: {orders_count} orders/page (max 10)")
    else:
        print(f"✗ PAGINATION FAIL: {orders_count} orders returned (expected ≤10)")
else:
    print(f"✗ PAGINATION ERROR: {r.status_code}")

# Test 3: Create order with HEART shape
print("\n[TEST 3] Create Order with HEART cutout")
order = {
    'order_data': {
        'customer_name': 'Test Heart',
        'customer_email': 'test@example.com',
        'customer_phone': '9999999999',
        'quantity': 1,
        'notes': 'Heart shape test'
    },
    'glass_config': {
        'width_mm': 1000,
        'height_mm': 800,
        'thickness_mm': 6,
        'glass_type': 'tempered',
        'color_name': 'clear',
        'application': 'door',
        'cutouts': [{'type': 'HR', 'shape': 'heart', 'x': 500, 'y': 400, 'diameter': 100}]
    }
}
r = requests.post(f'{BASE}/api/orders/with-design', json=order, headers=h, timeout=20)
if r.status_code in [200, 201]:
    order_num = r.json().get('order_number')
    print(f"✓ HEART ORDER CREATED: {order_num}")
else:
    print(f"✗ HEART ORDER FAILED: {r.status_code} - {r.text[:100]}")

# Test 4: Create order with STAR shape
print("\n[TEST 4] Create Order with STAR cutout")
order = {
    'order_data': {
        'customer_name': 'Test Star',
        'customer_email': 'test@example.com',
        'customer_phone': '9999999999',
        'quantity': 1,
        'notes': 'Star shape test'
    },
    'glass_config': {
        'width_mm': 1000,
        'height_mm': 800,
        'thickness_mm': 6,
        'glass_type': 'tempered',
        'color_name': 'clear',
        'application': 'door',
        'cutouts': [{'type': 'ST', 'shape': 'star', 'x': 500, 'y': 400, 'diameter': 100}]
    }
}
r = requests.post(f'{BASE}/api/orders/with-design', json=order, headers=h, timeout=20)
if r.status_code in [200, 201]:
    order_num = r.json().get('order_number')
    print(f"✓ STAR ORDER CREATED: {order_num}")
else:
    print(f"✗ STAR ORDER FAILED: {r.status_code} - {r.text[:100]}")

# Test 5: Create order with DIAMOND shape
print("\n[TEST 5] Create Order with DIAMOND cutout")
order = {
    'order_data': {
        'customer_name': 'Test Diamond',
        'customer_email': 'test@example.com',
        'customer_phone': '9999999999',
        'quantity': 1,
        'notes': 'Diamond shape test'
    },
    'glass_config': {
        'width_mm': 1000,
        'height_mm': 800,
        'thickness_mm': 6,
        'glass_type': 'tempered',
        'color_name': 'clear',
        'application': 'door',
        'cutouts': [{'type': 'DM', 'shape': 'diamond', 'x': 500, 'y': 400, 'width': 80, 'height': 80}]
    }
}
r = requests.post(f'{BASE}/api/orders/with-design', json=order, headers=h, timeout=20)
if r.status_code in [200, 201]:
    order_num = r.json().get('order_number')
    print(f"✓ DIAMOND ORDER CREATED: {order_num}")
else:
    print(f"✗ DIAMOND ORDER FAILED: {r.status_code} - {r.text[:100]}")

# Test 6: Check Job Work endpoint
print("\n[TEST 6] Job Work API Endpoint")
r = requests.get(f'{BASE}/api/erp/job-work/labour-rates', headers=h, timeout=10)
if r.status_code == 200:
    print(f"✓ JOB WORK API WORKING: Got labour rates")
else:
    print(f"✗ JOB WORK API ERROR: {r.status_code}")

print("\n" + "="*60)
print("✓ ALL TESTS COMPLETED")
print("="*60 + "\n")
