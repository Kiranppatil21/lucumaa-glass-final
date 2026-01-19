# Deploy Glass ERP to Railway.app (FREE)

## Why Railway?
- ✅ **FREE tier**: 500 hours/month (~17 days runtime)
- ✅ **No credit card** required for trial
- ✅ **Built-in MongoDB** plugin
- ✅ **Auto-deploy** from Git
- ✅ **5 minute setup**
- ✅ **HTTPS included**

## Step-by-Step Deployment

### 1. Prepare Your Code (2 min)

Create `railway.json` in project root:
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "cd backend && uvicorn server:app --host 0.0.0.0 --port $PORT",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

Create `Procfile` in project root:
```
web: cd backend && uvicorn server:app --host 0.0.0.0 --port $PORT
```

Create `runtime.txt` in backend/:
```
python-3.11
```

### 2. Create Railway Account (1 min)

1. Go to https://railway.app
2. Click "Start a New Project"
3. Sign in with GitHub (recommended) or email
4. No credit card required!

### 3. Deploy Backend (2 min)

**Via GitHub (Recommended):**
1. Push your Glass project to GitHub
2. In Railway: "New Project" → "Deploy from GitHub repo"
3. Select your Glass repository
4. Railway auto-detects Python and builds

**Via CLI:**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Initialize in your project
cd /Users/admin/Desktop/Glass
railway init

# Deploy
railway up
```

### 4. Add MongoDB (30 seconds)

1. In Railway dashboard, click "+ New"
2. Select "Database" → "Add MongoDB"
3. Wait 30 seconds for provisioning
4. MongoDB automatically connects to your app!

### 5. Configure Environment Variables (1 min)

In Railway dashboard, go to your backend service → "Variables":

```bash
MONGO_URL=${{MongoDB.MONGO_URL}}  # Auto-populated by Railway
DB_NAME=lucumaa
JWT_SECRET=your-random-secret-64-chars
ALLOWED_ORIGINS=https://your-app.up.railway.app
PORT=8000
```

Railway automatically injects MongoDB connection string!

### 6. Deploy Frontend (1 min)

**Option A: Railway Static Site**
```bash
cd frontend
npm run build

# Deploy build folder
railway up --service frontend
```

**Option B: Netlify/Vercel (Better for static)**
1. Build: `npm run build`
2. Upload `build/` folder to Netlify
3. FREE forever!

### 7. Seed Admin User

In Railway dashboard:
1. Go to your backend service
2. Click "Terminal" (or use Railway CLI)
3. Run:
```bash
cd backend
python seed_admin.py
```

### 8. Access Your App! 🎉

Railway provides:
- Backend: `https://your-app.up.railway.app`
- Auto HTTPS/SSL
- Custom domain support (optional)

## Environment Variables Reference

```bash
# Automatically provided by Railway MongoDB plugin
MONGO_URL=${{MongoDB.MONGO_URL}}
MONGOHOST=${{MongoDB.MONGOHOST}}
MONGOPORT=${{MongoDB.MONGOPORT}}
MONGOUSER=${{MongoDB.MONGOUSER}}
MONGOPASSWORD=${{MongoDB.MONGOPASSWORD}}

# You set these
DB_NAME=lucumaa
JWT_SECRET=generate-random-64-char-string
ALLOWED_ORIGINS=https://your-app.up.railway.app
PORT=8000
```

## Cost Breakdown

### Free Tier (No Credit Card)
- **500 execution hours/month** (~17 days)
- **100GB outbound bandwidth**
- **MongoDB included** (512MB storage)
- **Perfect for testing/demo**

### Paid Tier (After free trial)
- **$5/month** for backend
- **$5/month** for MongoDB
- **Total: $10/month** for production

## Advantages Over Shared Hosting

| Feature | Shared Hosting | Railway |
|---------|---------------|---------|
| Python Support | ❌ No | ✅ Yes |
| MongoDB | ❌ No | ✅ Yes |
| Persistent Processes | ❌ No | ✅ Yes |
| HTTPS/SSL | 💰 Extra | ✅ Free |
| Auto-deploy | ❌ No | ✅ Yes |
| Scaling | ❌ No | ✅ Auto |
| Setup Time | N/A | ⚡ 5 min |

## Troubleshooting

### Build Fails
Check Railway logs:
```bash
railway logs
```

### MongoDB Connection Issues
Verify environment variable:
```bash
railway variables
# Should see MONGO_URL
```

### Port Issues
Railway assigns PORT automatically. Use `$PORT` in your start command.

## Alternative: Render.com

Similar to Railway but with different free tier:
- **750 hours/month** free
- Spins down after 15min inactivity
- Good for demos

Deploy on Render:
1. Go to https://render.com
2. "New" → "Web Service"
3. Connect GitHub repo
4. Build Command: `cd backend && pip install -r requirements.txt`
5. Start Command: `cd backend && uvicorn server:app --host 0.0.0.0 --port $PORT`
6. Add MongoDB: "New" → "MongoDB"

## Production Recommendation

For **production** with real customers:
- Use Railway/Render paid tier ($10-15/month)
- Or upgrade to Hostinger VPS ($4-8/month) with my deployment scripts
- Railway is easier, VPS is cheaper but needs management

## Summary

✅ **Best for testing:** Railway free tier  
✅ **Best for production budget:** Hostinger VPS ($4-8/month)  
✅ **Best for no DevOps:** Railway paid ($10/month)  
✅ **Cannot use:** Shared hosting (incompatible)
