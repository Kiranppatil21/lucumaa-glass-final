#!/usr/bin/env python3
"""
Script to manually seed the admin user into MongoDB
Run this after MongoDB is started
"""
import asyncio
import bcrypt
import uuid
from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv

load_dotenv()

async def seed_admin():
    mongo_url = os.environ.get('MONGO_URL', 'mongodb://localhost:27017')
    db_name = os.environ.get('DB_NAME', 'lucumaa')
    
    print(f"Connecting to MongoDB at {mongo_url}...")
    client = AsyncIOMotorClient(mongo_url, serverSelectionTimeoutMS=5000)
    db = client[db_name]
    
    try:
        # Test connection
        await client.admin.command('ping')
        print("✓ Connected to MongoDB")
    except Exception as e:
        print(f"✗ Failed to connect to MongoDB: {e}")
        return False
    
    # Check if admin already exists
    existing = await db.users.find_one({"email": "admin@lucumaaglass.in"})
    
    # Create admin user with bcrypt password hash
    password_hash = bcrypt.hashpw("admin123".encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    admin_doc = {
        "id": str(uuid.uuid4()),
        "email": "admin@lucumaaglass.in",
        "name": "Super Admin",
        "phone": "9999999999",
        "password_hash": password_hash,  # Standardized field name
        "role": "super_admin",
        "active": True,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    if existing:
        # Update existing user
        await db.users.update_one(
            {"email": "admin@lucumaaglass.in"},
            {"$set": admin_doc}
        )
        print("✓ Admin user updated successfully!")
    else:
        # Create new user
        await db.users.insert_one(admin_doc)
        print("✓ Admin user created successfully!")
    
    print(f"   Email: admin@lucumaaglass.in")
    print(f"   Password: admin123")
    print(f"   Role: super_admin")
    
    return True

if __name__ == "__main__":
    success = asyncio.run(seed_admin())
    exit(0 if success else 1)
