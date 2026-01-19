#!/bin/bash
# Create admin user using backend registration API

echo "🔐 Creating Admin User via API"
echo "=============================="
echo ""

VPS_HOST="${VPS_HOST:-root@147.79.104.84}"
BACKEND_DIR="${BACKEND_DIR:-/root/glass-deploy-20260107-190639/backend}"

# Delete old admin first via MongoDB
ssh "$VPS_HOST" << ENDSSH
DB_NAME="lucumaa"
if [ -f "$BACKEND_DIR/.env" ]; then
  DB_NAME_FROM_ENV=$(grep -E '^DB_NAME=' "$BACKEND_DIR/.env" | head -n 1 | cut -d= -f2- | tr -d '"\r')
  if [ -n "$DB_NAME_FROM_ENV" ]; then
    DB_NAME="$DB_NAME_FROM_ENV"
  fi
fi

mongosh "$DB_NAME" --quiet --eval '
db.users.deleteMany({email: {$in: ["admin@lucumaaglass.in", "admin@lucumaa.in"]}});
print("✅ Old admin accounts deleted (DB: " + db.getName() + ")");
'
ENDSSH

echo ""
echo "📝 Registering new admin..."

# Register admin via API (this will use proper bcrypt hashing)
curl -X POST https://lucumaaglass.in/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@lucumaaglass.in",
    "password": "Admin@123",
    "name": "Super Admin",
    "phone": "+919284701985",
    "role": "super_admin"
  }'

echo ""
echo ""
echo "✅ Admin user created!"
echo ""
echo "🔑 Login credentials:"
echo "   Email: admin@lucumaaglass.in"
echo "   Password: Admin@123"
echo ""
echo "🌐 Login at: https://lucumaaglass.in/login"
echo ""
