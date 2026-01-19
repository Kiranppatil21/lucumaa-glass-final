#!/usr/bin/env python3
"""Test authentication endpoints and database connection"""
import asyncio
import sys
import os
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / 'backend'))

async def test_auth():
    from motor.motor_asyncio import AsyncIOMotorClient
    from dotenv import load_dotenv
    import bcrypt
    
    # Load env
    load_dotenv(Path(__file__).parent / 'backend' / '.env')
    
    mongo_url = os.environ.get('MONGO_URL', 'mongodb://localhost:27017')
    db_name = os.environ.get('DB_NAME', 'lucumaa')
    
    print(f"🔍 Testing MongoDB connection to: {mongo_url}")
    print(f"📊 Database: {db_name}\n")
    
    try:
        client = AsyncIOMotorClient(mongo_url, serverSelectionTimeoutMS=5000)
        db = client[db_name]
        
        # Test connection
        await client.admin.command('ping')
        print("✅ MongoDB connection successful!\n")
        
        # Check users collection
        user_count = await db.users.count_documents({})
        print(f"👥 Total users in database: {user_count}")
        
        if user_count > 0:
            print("\n📋 Sample users:")
            users = await db.users.find({}, {"_id": 0, "email": 1, "name": 1, "role": 1}).limit(5).to_list(5)
            for u in users:
                print(f"   - {u.get('email')} ({u.get('role')}) - {u.get('name')}")
        else:
            print("\n⚠️  No users found in database!")
            print("   Creating a test user...")
            
            # Create test user
            test_user = {
                "id": "test-user-001",
                "email": "test@lucumaaglass.in",
                "name": "Test User",
                "phone": "+919999999999",
                "role": "customer",
                "password_hash": bcrypt.hashpw("test123".encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
                "created_at": "2026-01-08T00:00:00"
            }
            await db.users.insert_one(test_user)
            print(f"\n✅ Test user created!")
            print(f"   Email: test@lucumaaglass.in")
            print(f"   Password: test123")
        
        # Test password verification
        print("\n🔐 Testing password hashing...")
        test_pwd = "test123"
        hashed = bcrypt.hashpw(test_pwd.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        verified = bcrypt.checkpw(test_pwd.encode('utf-8'), hashed.encode('utf-8'))
        print(f"   Password hash: {hashed[:30]}...")
        print(f"   Verification: {'✅ PASS' if verified else '❌ FAIL'}")
        
        client.close()
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        print("\n💡 Troubleshooting:")
        print("   1. Make sure MongoDB is running (check with 'mongosh' or 'docker ps')")
        print("   2. Verify MONGO_URL in backend/.env")
        print("   3. Check network/firewall settings")
        return False
    
    return True

if __name__ == "__main__":
    success = asyncio.run(test_auth())
    sys.exit(0 if success else 1)
