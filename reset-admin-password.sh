#!/bin/bash
# Reset admin password on VPS

echo "🔐 Resetting Admin Password"
echo "==========================="
echo ""

# VPS backend directory (must match the PM2 cwd / deployed backend location)
VPS_HOST="${VPS_HOST:-root@147.79.104.84}"
BACKEND_DIR="${BACKEND_DIR:-/root/glass-deploy-20260107-190639/backend}"

ssh "$VPS_HOST" << ENDSSH
# Resolve DB_NAME from the backend .env (fallback to lucumaa)
DB_NAME="lucumaa"
if [ -f "$BACKEND_DIR/.env" ]; then
  DB_NAME_FROM_ENV=$(grep -E '^DB_NAME=' "$BACKEND_DIR/.env" | head -n 1 | cut -d= -f2- | tr -d '"\r')
  if [ -n "$DB_NAME_FROM_ENV" ]; then
    DB_NAME="$DB_NAME_FROM_ENV"
  fi
fi

# Connect to MongoDB and reset admin password
mongosh "$DB_NAME" <<'EOF'
// Check existing admin users
print("\n📋 Current admin users:");
db.users.find({role: {$in: ["admin", "super_admin"]}}, {email: 1, name: 1, role: 1}).forEach(printjson);

// Delete old admin accounts to avoid confusion
print("\n🗑️  Removing old admin accounts...");
db.users.deleteMany({email: {$in: ["admin@lucumaa.in", "admin@lucumaaglass.in"]}});

// Create fresh admin with known password
// Password: Admin@123
// Bcrypt hash generated for "Admin@123"
print("\n✅ Creating new admin account...");
db.users.insertOne({
  "id": "admin-001",
  "email": "admin@lucumaaglass.in",
  "name": "Admin User",
  "phone": "+919284701985",
  "role": "super_admin",
  "password_hash": "$2b$12$LmB8W0L1J4Xqh5HvY8y.bOYJ7gg0I5xJE0U5O3qV9wKJFGjHZPJ6K",
  "created_at": new Date().toISOString()
});

print("\n✅ Admin account created!");
print("\nLogin credentials:");
print("  Email: admin@lucumaaglass.in");
print("  Password: Admin@123");
print("");

// Verify it was created
var admin = db.users.findOne({email: "admin@lucumaaglass.in"});
if (admin) {
  print("✅ Verified: Admin account exists");
  print("   ID: " + admin.id);
  print("   Email: " + admin.email);
  print("   Role: " + admin.role);
} else {
  print("❌ Error: Admin account not found");
}
EOF
ENDSSH

echo ""
echo "✅ Admin password reset complete!"
echo ""
echo "🔑 New login credentials:"
echo "   Email: admin@lucumaaglass.in"
echo "   Password: Admin@123"
echo ""
echo "🌐 Login at: https://lucumaaglass.in/login"
echo ""
