#!/usr/bin/env python3
"""
Fix all existing users in MongoDB - normalize password field names
This script will:
1. Find all users with any password field variant
2. Standardize to 'password_hash' field
3. Ensure all required fields exist
"""
import asyncio
import bcrypt
import uuid
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv

load_dotenv()

async def fix_users():
    mongo_url = os.environ.get('MONGO_URL', 'mongodb://localhost:27017')
    db_name = os.environ.get('DB_NAME', 'lucumaa')
    
    print(f"🔗 Connecting to MongoDB at {mongo_url}...")
    client = AsyncIOMotorClient(mongo_url, serverSelectionTimeoutMS=5000)
    db = client[db_name]
    
    try:
        # Test connection
        await client.admin.command('ping')
        print("✓ Connected to MongoDB")
    except Exception as e:
        print(f"✗ Failed to connect to MongoDB: {e}")
        return False
    
    try:
        # Get all users
        users = await db.users.find({}).to_list(None)
        print(f"\n📊 Found {len(users)} users in database")
        
        if len(users) == 0:
            print("⚠️  No users found in database")
            return True
        
        fixed_count = 0
        
        for user in users:
            updated = False
            update_doc = {}
            
            email = user.get("email", "unknown")
            print(f"\n👤 Processing: {email}")
            
            # Check password field variants
            password_hash = user.get("password_hash") or user.get("hashed_password") or user.get("password")
            
            if not password_hash:
                print(f"   ⚠️  No password field found, skipping")
                continue
            
            # Standardize to password_hash
            if user.get("hashed_password") or user.get("password"):
                update_doc["password_hash"] = password_hash
                # Remove old field names
                if user.get("hashed_password"):
                    await db.users.update_one({"_id": user["_id"]}, {"$unset": {"hashed_password": ""}})
                    print(f"   ✓ Removed 'hashed_password' field")
                if user.get("password"):
                    await db.users.update_one({"_id": user["_id"]}, {"$unset": {"password": ""}})
                    print(f"   ✓ Removed 'password' field")
                updated = True
            
            # Ensure id field exists
            if not user.get("id"):
                user_id = user.get("user_id") or str(uuid.uuid4())
                update_doc["id"] = user_id
                print(f"   ✓ Added 'id' field: {user_id[:8]}...")
                updated = True
            
            # Ensure other required fields
            if not user.get("role"):
                update_doc["role"] = "customer"
                print(f"   ✓ Set role to 'customer'")
                updated = True
            
            if not user.get("name"):
                update_doc["name"] = email.split("@")[0]
                print(f"   ✓ Set name from email")
                updated = True
            
            # Apply updates
            if updated and update_doc:
                result = await db.users.update_one(
                    {"_id": user["_id"]},
                    {"$set": update_doc}
                )
                if result.modified_count > 0:
                    fixed_count += 1
                    print(f"   ✓ User updated successfully")
                else:
                    print(f"   ℹ️  No changes needed")
            else:
                print(f"   ℹ️  User already correct")
        
        print(f"\n✅ Fixed {fixed_count} users")
        
        # Verify all users now have proper fields
        print("\n🔍 Verifying all users...")
        all_valid = True
        
        broken_users = await db.users.find({
            "$or": [
                {"password_hash": {"$exists": False}, "hashed_password": {"$exists": False}, "password": {"$exists": False}},
                {"id": {"$exists": False}},
                {"role": {"$exists": False}}
            ]
        }).to_list(None)
        
        if broken_users:
            print(f"⚠️  Found {len(broken_users)} users with missing fields:")
            for u in broken_users:
                print(f"   - {u.get('email')}")
            all_valid = False
        else:
            print("✓ All users have required fields")
        
        return all_valid
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        client.close()

if __name__ == "__main__":
    success = asyncio.run(fix_users())
    exit(0 if success else 1)
