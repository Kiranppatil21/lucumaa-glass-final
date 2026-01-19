#!/bin/bash
# Create test users directly using mongosh - V2 with proper escaping

DATABASE="glass_admin_database"

echo "🔄 Creating users in MongoDB..."
echo "   Database: $DATABASE"
echo ""

# Function to create user with mongosh
create_user() {
    local email=$1
    local password=$2
    local name=$3
    local role=$4
    
    # Generate password hash and UUID using Python
    local pass_hash=$(python3 -c "import bcrypt; print(bcrypt.hashpw('$password'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'))")
    local user_id=$(python3 -c "import uuid; print(str(uuid.uuid4()))")
    
    # Insert into MongoDB using heredoc to avoid shell expansion
    mongosh "mongodb://localhost:27017/$DATABASE" --quiet <<EOF
db.users.updateOne(
  {email: '$email'},
  {\$set: {
    email: '$email',
    password_hash: '$pass_hash',
    name: '$name',
    role: '$role',
    id: '$user_id',
    is_active: true
  }},
  {upsert: true}
)
EOF
    
    echo "✓ Created: $email (Password: $password)"
}

# Create users
create_user "admin@lucumaaglass.in" "admin123" "Admin User" "super_admin"
create_user "manager@lucumaaglass.in" "manager123" "Manager User" "manager"
create_user "customer@lucumaaglass.in" "customer123" "Customer User" "customer"
create_user "dealer@lucumaaglass.in" "dealer123" "Dealer User" "dealer"

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
