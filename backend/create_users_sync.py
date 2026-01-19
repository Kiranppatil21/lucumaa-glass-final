#!/usr/bin/env python3
"""
Create test users for all roles using synchronous pymongo
"""
from pymongo import MongoClient
import bcrypt
import uuid
import sys

# MongoDB connection
MONGO_URL = "mongodb://localhost:27017"
DATABASE_NAME = "glass_admin_database"

def hash_password(password: str) -> str:
    """Hash a password using bcrypt"""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def create_user(collection, email: str, password: str, name: str, role: str):
    """Create or update a user"""
    hashed_password = hash_password(password)
    
    user_data = {
        "email": email,
        "hashed_password": hashed_password,
        "name": name,
        "role": role,
        "user_id": str(uuid.uuid4()),
        "is_active": True
    }
    
    # Update if exists, insert if not
    result = collection.update_one(
        {"email": email},
        {"$set": user_data},
        upsert=True
    )
    
    action = "Updated" if result.matched_count > 0 else "Created"
    return action

def main():
    try:
        # Connect to MongoDB
        client = MongoClient(MONGO_URL)
        db = client[DATABASE_NAME]
        users_collection = db.users
        
        print("🔄 Creating users in MongoDB...")
        print(f"   Database: {DATABASE_NAME}")
        print()
        
        # Define users to create
        users = [
            ("admin@lucumaaglass.in", "admin123", "Admin User", "super_admin"),
            ("manager@lucumaaglass.in", "manager123", "Manager User", "manager"),
            ("customer@lucumaaglass.in", "customer123", "Customer User", "customer"),
            ("dealer@lucumaaglass.in", "dealer123", "Dealer User", "dealer"),
        ]
        
        # Create each user
        for email, password, name, role in users:
            action = create_user(users_collection, email, password, name, role)
            print(f"✓ {action}: {email} (Password: {password})")
        
        print()
        print("=" * 60)
        print("📋 LOGIN CREDENTIALS")
        print("=" * 60)
        print()
        print("ADMIN (Full Access):")
        print("  URL: https://lucumaaglass.in/erp/login")
        print("  Email: admin@lucumaaglass.in")
        print("  Password: admin123")
        print()
        print("MANAGER (ERP Access):")
        print("  URL: https://lucumaaglass.in/erp/login")
        print("  Email: manager@lucumaaglass.in")
        print("  Password: manager123")
        print()
        print("CUSTOMER (Portal Access):")
        print("  URL: https://lucumaaglass.in/login")
        print("  Email: customer@lucumaaglass.in")
        print("  Password: customer123")
        print()
        print("DEALER (Portal Access):")
        print("  URL: https://lucumaaglass.in/login")
        print("  Email: dealer@lucumaaglass.in")
        print("  Password: dealer123")
        print()
        print("=" * 60)
        
        client.close()
        return 0
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
