# MongoDB Atlas - Free Database Setup Guide

## Why MongoDB Atlas?
- ✅ **Free tier available** (512MB storage)
- ✅ **No credit card required** for free tier
- ✅ **Automatic backups**
- ✅ **Built-in security**
- ✅ **High availability**
- ✅ **No server maintenance**

---

## Step-by-Step Setup (15 minutes)

### 1. Create Account
1. Go to: https://www.mongodb.com/cloud/atlas/register
2. Sign up with email or Google
3. Verify your email

### 2. Create Free Cluster
1. Click **"Build a Database"**
2. Choose **"FREE"** tier (M0)
3. Select provider: **AWS** (recommended)
4. Region: Choose closest to your users
   - US East (Virginia) for USA
   - Mumbai for India
   - Frankfurt for Europe
5. Cluster Name: `glass-erp-cluster` (or keep default)
6. Click **"Create"**
7. Wait 3-5 minutes for cluster creation

### 3. Create Database User
1. You'll see "Security Quickstart"
2. Choose **"Username and Password"**
3. Username: `glassadmin`
4. Password: Click **"Autogenerate Secure Password"**
5. **SAVE THIS PASSWORD!** You'll need it
6. Click **"Create User"**

### 4. Set IP Whitelist
1. Choose **"My Local Environment"**
2. Click **"Add My Current IP Address"**
3. **Important**: Also add **"0.0.0.0/0"** to allow from anywhere
   - This lets your Hostinger server connect
   - Click "Add IP Address" again
   - Enter: `0.0.0.0/0`
   - Description: "Allow from anywhere"
4. Click **"Finish and Close"**

### 5. Get Connection String
1. Click **"Connect"** button on your cluster
2. Choose **"Connect your application"**
3. Driver: **Python**
4. Version: **3.12 or later**
5. Copy the connection string:
   ```
   mongodb+srv://glassadmin:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
6. **Important**: Replace `<password>` with your actual password

### 6. Create Database
1. Click **"Browse Collections"**
2. Click **"Add My Own Data"**
3. Database name: `lucumaa`
4. Collection name: `users`
5. Click **"Create"**

---

## Connection String Examples

### Standard Format
```
mongodb+srv://glassadmin:YOUR_PASSWORD@cluster0.ab1cd.mongodb.net/?retryWrites=true&w=majority
```

### With Database Specified
```
mongodb+srv://glassadmin:YOUR_PASSWORD@cluster0.ab1cd.mongodb.net/lucumaa?retryWrites=true&w=majority
```

### Important Notes:
- Remove `<` and `>` around password
- If password has special characters, URL encode them:
  - `@` becomes `%40`
  - `#` becomes `%23`
  - `%` becomes `%25`
  - Or use a simple password (letters + numbers)

---

## Test Connection (Before Deployment)

### Using MongoDB Compass (GUI)
1. Download: https://www.mongodb.com/try/download/compass
2. Install and open
3. Paste your connection string
4. Click "Connect"
5. You should see your `lucumaa` database

### Using Python (from your Mac)
```bash
pip install pymongo[srv]

python3 -c "
from pymongo import MongoClient
client = MongoClient('YOUR_CONNECTION_STRING')
db = client.lucumaa
print('✓ Connected to MongoDB Atlas')
print('Collections:', db.list_collection_names())
"
```

---

## Seed Admin User to Atlas

### Option 1: Using Your Seed Script
Update `seed_admin.py` connection:
```python
# Update this line
mongo_url = "mongodb+srv://glassadmin:PASSWORD@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority"
```

Then run:
```bash
cd /Users/admin/Desktop/Glass/backend
source ../.venv/bin/activate
python seed_admin.py
```

### Option 2: Using MongoDB Atlas UI
1. Go to your cluster
2. Click **"Collections"**
3. Select `lucumaa` database
4. Select `users` collection
5. Click **"Insert Document"**
6. Switch to **"Code"** view
7. Paste this (generate bcrypt hash first):

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "admin@lucumaa.in",
  "name": "Super Admin",
  "phone": "9999999999",
  "password_hash": "$2b$12$BCRYPT_HASH_HERE",
  "role": "super_admin",
  "is_active": true,
  "created_at": "2026-01-07T00:00:00Z"
}
```

To generate bcrypt hash:
```bash
python3 -c "
import bcrypt
password = 'adminpass'.encode('utf-8')
hashed = bcrypt.hashpw(password, bcrypt.gensalt())
print(hashed.decode('utf-8'))
"
```

---

## Security Best Practices

### ✅ DO:
- Use strong passwords (20+ characters)
- Change default admin password after first login
- Use IP whitelist when possible
- Enable 2FA on MongoDB Atlas account
- Regular database backups (automatic in Atlas)

### ❌ DON'T:
- Share your connection string publicly
- Commit connection string to git
- Use simple passwords
- Leave database publicly accessible forever

---

## Monitoring & Limits

### Free Tier (M0) Limits:
- Storage: 512 MB
- RAM: Shared
- Backup: Limited
- Connections: 500 concurrent

### Check Usage:
1. Go to cluster dashboard
2. Click **"Metrics"** tab
3. Monitor:
   - Storage used
   - Network traffic
   - Operations per second

### Upgrade When Needed:
- M10 cluster: $9/month
- More storage, RAM, and features
- Upgrade anytime with 1-click

---

## Troubleshooting

### "Authentication Failed"
- Double-check username and password
- Ensure special characters in password are URL-encoded
- Verify user was created with correct privileges

### "Connection Timeout"
- Check IP whitelist (add 0.0.0.0/0)
- Verify internet connection
- Check if your ISP blocks MongoDB port 27017

### "Database Not Found"
- Database is auto-created when you first write data
- Make sure you specified database name in connection string
- Or create it manually in Atlas UI

### "Too Many Connections"
- Free tier has 500 connection limit
- Close unused connections in your app
- Consider connection pooling

---

## Get Your Connection String

After completing setup, your `.env.production` should have:

```env
MONGO_URL=mongodb+srv://glassadmin:YOUR_ACTUAL_PASSWORD@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
DB_NAME=lucumaa
```

✅ Test this connection before deploying to Hostinger!

---

## Free Alternatives

If you need more than 512MB:

1. **MongoDB Cloud** (MongoDB.com) - Free 512MB
2. **Railway.app** - Free 512MB MongoDB
3. **Self-hosted** on Hostinger VPS - Unlimited but requires management

For production apps > 512MB, consider:
- Upgrading to M10 ($9/month)
- Moving to dedicated server
- Implementing data cleanup policies
