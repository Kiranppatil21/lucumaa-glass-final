#!/usr/bin/env python3
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import bcrypt
import uuid
from datetime import datetime, timezone

async def create_admin():
    client = AsyncIOMotorClient('mongodb://localhost:27017')
    db = client['glass_erp']
    
    # Check if admin exists
    existing = await db.users.find_one({'email': 'admin@lucumaaglass.in'})
    
    # Hash password
    password = 'admin123'
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    admin_user = {
        'id': str(uuid.uuid4()),
        'email': 'admin@lucumaaglass.in',
        'password': hashed,
        'name': 'Admin',
        'role': 'super_admin',
        'phone': '',
        'created_at': datetime.now(timezone.utc).isoformat(),
        'active': True
    }
    
    if existing:
        # Update existing
        await db.users.update_one(
            {'email': 'admin@lucumaaglass.in'},
            {'$set': admin_user}
        )
        print('✅ Admin user UPDATED')
    else:
        # Create new
        await db.users.insert_one(admin_user)
        print('✅ Admin user CREATED')
    
    print('')
    print('Login Credentials:')
    print('  Email: admin@lucumaaglass.in')
    print('  Password: admin123')
    print('  Role: super_admin')
    print('')
    print('Login at: https://lucumaaglass.in/login')
    
    client.close()

if __name__ == '__main__':
    asyncio.run(create_admin())
