#!/usr/bin/env python3
"""
Script to create all role users for testing
"""
import asyncio
import bcrypt
import uuid
from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorClient
import os

async def setup_users():
    mongo_url = "mongodb://localhost:27017"
    db_name = "glass_manufacturing"
    
    print(f"Connecting to MongoDB...")
    client = AsyncIOMotorClient(mongo_url, serverSelectionTimeoutMS=5000)
    db = client[db_name]
    
    try:
        await client.admin.command('ping')
        print("✓ Connected to MongoDB")
    except Exception as e:
        print(f"✗ Failed: {e}")
        return False
    
    # Users to create
    users = [
        {
            "email": "admin@lucumaaglass.in",
            "password": "admin123",
            "name": "Super Admin",
            "phone": "9999999999",
            "role": "super_admin"
        },
        {
            "email": "manager@lucumaaglass.in",
            "password": "manager123",
            "name": "Manager",
            "phone": "9999999998",
            "role": "manager"
        },
        {
            "email": "customer@lucumaaglass.in",
            "password": "customer123",
            "name": "Test Customer",
            "phone": "9999999997",
            "role": "customer"
        },
        {
            "email": "dealer@lucumaaglass.in",
            "password": "dealer123",
            "name": "Test Dealer",
            "phone": "9999999996",
            "role": "dealer"
        }
    ]
    
    print("\n📝 Creating users...")
    for user_data in users:
        existing = await db.users.find_one({"email": user_data["email"]})
        
        password_hash = bcrypt.hashpw(user_data["password"].encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        user_doc = {
            "id": str(uuid.uuid4()),
            "email": user_data["email"],
            "name": user_data["name"],
            "phone": user_data["phone"],
            "password_hash": password_hash,
            "role": user_data["role"],
            "is_credit_customer": False,
            "credit_limit": 0,
            "wallet_balance": 0,
            "created_at": datetime.now(timezone.utc).isoformat()
        }
        
        if existing:
            await db.users.update_one(
                {"email": user_data["email"]},
                {"$set": user_doc}
            )
            print(f"  ✓ Updated: {user_data['email']} (Password: {user_data['password']})")
        else:
            await db.users.insert_one(user_doc)
            print(f"  ✓ Created: {user_data['email']} (Password: {user_data['password']})")
    
    print("\n" + "="*60)
    print("🎉 ALL USERS CREATED SUCCESSFULLY!")
    print("="*60)
    print("\n📋 LOGIN CREDENTIALS:")
    print("-" * 60)
    for user_data in users:
        print(f"\n{user_data['role'].upper().replace('_', ' ')}:")
        print(f"  Email: {user_data['email']}")
        print(f"  Password: {user_data['password']}")
    print("-" * 60)
    
    return True

if __name__ == "__main__":
    success = asyncio.run(setup_users())
    exit(0 if success else 1)
