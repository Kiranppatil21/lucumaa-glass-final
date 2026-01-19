import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import bcrypt
import uuid
from datetime import datetime, timezone

async def fix_admin():
    client = AsyncIOMotorClient('mongodb://localhost:27017')
    db = client['glass_erp']
    
    # Create/update BOTH admin users with proper bcrypt passwords
    admins = [
        {
            'email': 'admin@lucumaa.in',
            'password': 'Lucumaa@@123',
            'name': 'Super Admin'
        },
        {
            'email': 'admin@lucumaaglass.in', 
            'password': 'admin123',
            'name': 'Admin'
        }
    ]
    
    for admin_data in admins:
        hashed = bcrypt.hashpw(admin_data['password'].encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        user = {
            'id': str(uuid.uuid4()),
            'email': admin_data['email'],
            'password': hashed,
            'name': admin_data['name'],
            'role': 'super_admin',
            'phone': '',
            'active': True,
            'created_at': datetime.now(timezone.utc).isoformat()
        }
        
        await db.users.update_one(
            {'email': admin_data['email']},
            {'$set': user},
            upsert=True
        )
        print(f"✅ {admin_data['email']} updated")
    
    client.close()
    print('')
    print('Both admin users fixed:')
    print('  1. admin@lucumaa.in / Lucumaa@@123')
    print('  2. admin@lucumaaglass.in / admin123')
    print('')
    print('Login at: https://lucumaaglass.in/login')

asyncio.run(fix_admin())
