import requests, json, sys
BASE = 'http://147.79.104.84:8000'
email = 'admin@lucumaaglass.in'
pwd = 'admin123'

r = requests.post(f'{BASE}/api/auth/login', json={'email': email, 'password': pwd})
print('LOGIN', r.status_code)
try:
    token = r.json().get('token')
except Exception:
    print('Login response', r.text)
    sys.exit(1)
print('TOKEN prefix', token[:20])
headers = {'Authorization': f'Bearer {token}'}

order_payload = {
    'order_data': {
        'customer_name': 'Test Customer E2E',
        'customer_email': 'kiranpatil86@gmail.com',
        'customer_phone': '9999999999',
        'quantity': 1,
        'notes': 'E2E order test with shapes heart/star/circle'
    },
    'glass_config': {
        'width_mm': 1000,
        'height_mm': 800,
        'thickness_mm': 6,
        'glass_type': 'tempered',
        'color_name': 'clear',
        'application': 'door',
        'cutouts': [
            {'type': 'heart', 'shape': 'heart', 'x': 300, 'y': 300, 'diameter': 120},
            {'type': 'star', 'shape': 'star', 'x': 600, 'y': 300, 'diameter': 120},
            {'type': 'hole', 'shape': 'circle', 'x': 450, 'y': 550, 'diameter': 80}
        ]
    }
}
resp = requests.post(f'{BASE}/api/orders/with-design', json=order_payload, headers=headers, timeout=20)
print('ORDER CREATE', resp.status_code, resp.text)
try:
    data = resp.json()
    print('ORDER_NUMBER', data.get('order_number'))
except Exception:
    print('Order resp', resp.text)

job_payload = {
    'customer_name': 'JobWork Test',
    'company_name': 'Test Co',
    'phone': '9999999999',
    'email': 'kiranpatil86@gmail.com',
    'items': [
        {'thickness_mm': 6, 'width_inch': 40, 'height_inch': 30, 'quantity': 2, 'notes': 'panel A'},
        {'thickness_mm': 8, 'width_inch': 50, 'height_inch': 36, 'quantity': 1, 'notes': 'panel B'}
    ],
    'delivery_address': 'Test address',
    'disclaimer_accepted': True,
    'notes': 'Job work test order',
    'transport_required': False,
    'transport_cost': 0
}
jw_resp = requests.post(f'{BASE}/job-work/orders', json=job_payload, headers=headers, timeout=20)
print('JOBWORK CREATE', jw_resp.status_code, jw_resp.text)
try:
    jw_data = jw_resp.json()
    jw_num = jw_data.get('job_work_number')
    jw_id = jw_data.get('order', {}).get('id')
    print('JOB_WORK_NUMBER', jw_num)
    print('JOB_WORK_ID', jw_id)
except Exception:
    print('Job work resp', jw_resp.text)
    sys.exit(0)

if jw_id:
    pdf_resp = requests.get(f'{BASE}/job-work/orders/{jw_id}/pdf', headers=headers, timeout=20)
    print('JOBWORK PDF', pdf_resp.status_code, 'bytes', len(pdf_resp.content))
