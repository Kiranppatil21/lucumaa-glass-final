#!/bin/bash
# Create operator, sales, and HR users

DATABASE="glass_erp"

echo "🔄 Creating additional users in MongoDB..."
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
create_user "operator@lucumaaglass.in" "operator123" "Operator User" "operator"
create_user "sales@lucumaaglass.in" "sales123" "Sales User" "sales"
create_user "hr@lucumaaglass.in" "hr123" "HR User" "hr"

echo ""
echo "============================================================"
echo "📋 NEW USER LOGIN CREDENTIALS"
echo "============================================================"
echo ""
echo "OPERATOR (ERP Access):"
echo "  URL: https://lucumaaglass.in/erp/login"
echo "  Email: operator@lucumaaglass.in"
echo "  Password: operator123"
echo ""
echo "SALES (ERP Access):"
echo "  URL: https://lucumaaglass.in/erp/login"
echo "  Email: sales@lucumaaglass.in"
echo "  Password: sales123"
echo ""
echo "HR (ERP Access):"
echo "  URL: https://lucumaaglass.in/erp/login"
echo "  Email: hr@lucumaaglass.in"
echo "  Password: hr123"
echo ""
echo "============================================================"
