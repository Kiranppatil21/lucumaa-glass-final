#!/bin/bash
# Create test users directly using mongosh

DATABASE="glass_admin_database"

# Function to hash password using Python bcrypt
hash_password() {
    python3 -c "import bcrypt; print(bcrypt.hashpw('$1'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'))"
}

# Function to generate UUID
generate_uuid() {
    python3 -c "import uuid; print(str(uuid.uuid4()))"
}

echo "🔄 Creating users in MongoDB..."
echo "   Database: $DATABASE"
echo ""

# Create Admin User
ADMIN_PASS_HASH=$(hash_password "admin123")
ADMIN_UUID=$(generate_uuid)
mongosh "mongodb://localhost:27017/$DATABASE" --quiet --eval "
db.users.updateOne(
  {email: 'admin@lucumaaglass.in'},
  {\$set: {
    email: 'admin@lucumaaglass.in',
    password_hash: '$ADMIN_PASS_HASH',
    name: 'Admin User',
    role: 'super_admin',
    id: '$ADMIN_UUID',
    is_active: true
  }},
  {upsert: true}
)
" > /dev/null 2>&1
echo "✓ Created: admin@lucumaaglass.in (Password: admin123)"

# Create Manager User
MANAGER_PASS_HASH=$(hash_password "manager123")
MANAGER_UUID=$(generate_uuid)
mongosh "mongodb://localhost:27017/$DATABASE" --quiet --eval "
db.users.updateOne(
  {email: 'manager@lucumaaglass.in'},
  {\$set: {
    email: 'manager@lucumaaglass.in',
    password_hash: '$MANAGER_PASS_HASH',
    name: 'Manager User',
    role: 'manager',
    id: '$MANAGER_UUID',
    is_active: true
  }},
  {upsert: true}
)
" > /dev/null 2>&1
echo "✓ Created: manager@lucumaaglass.in (Password: manager123)"

# Create Customer User
CUSTOMER_PASS_HASH=$(hash_password "customer123")
CUSTOMER_UUID=$(generate_uuid)
mongosh "mongodb://localhost:27017/$DATABASE" --quiet --eval "
db.users.updateOne(
  {email: 'customer@lucumaaglass.in'},
  {\$set: {
    email: 'customer@lucumaaglass.in',
    password_hash: '$CUSTOMER_PASS_HASH',
    name: 'Customer User',
    role: 'customer',
    id: '$CUSTOMER_UUID',
    is_active: true
  }},
  {upsert: true}
)
" > /dev/null 2>&1
echo "✓ Created: customer@lucumaaglass.in (Password: customer123)"

# Create Dealer User
DEALER_PASS_HASH=$(hash_password "dealer123")
DEALER_UUID=$(generate_uuid)
mongosh "mongodb://localhost:27017/$DATABASE" --quiet --eval "
db.users.updateOne(
  {email: 'dealer@lucumaaglass.in'},
  {\$set: {
    email: 'dealer@lucumaaglass.in',
    password_hash: '$DEALER_PASS_HASH',
    name: 'Dealer User',
    role: 'dealer',
    id: '$DEALER_UUID',
    is_active: true
  }},
  {upsert: true}
)
" > /dev/null 2>&1
echo "✓ Created: dealer@lucumaaglass.in (Password: dealer123)"

echo ""
echo "============================================================"
echo "📋 LOGIN CREDENTIALS"
echo "============================================================"
echo ""
echo "ADMIN (Full Access):"
echo "  URL: https://lucumaaglass.in/erp/login"
echo "  Email: admin@lucumaaglass.in"
echo "  Password: admin123"
echo ""
echo "MANAGER (ERP Access):"
echo "  URL: https://lucumaaglass.in/erp/login"
echo "  Email: manager@lucumaaglass.in"
echo "  Password: manager123"
echo ""
echo "CUSTOMER (Portal Access):"
echo "  URL: https://lucumaaglass.in/login"
echo "  Email: customer@lucumaaglass.in"
echo "  Password: customer123"
echo ""
echo "DEALER (Portal Access):"
echo "  URL: https://lucumaaglass.in/login"
echo "  Email: dealer@lucumaaglass.in"
echo "  Password: dealer123"
echo ""
echo "============================================================"
