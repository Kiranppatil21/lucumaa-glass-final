# 🔧 Fix 403 Forbidden Error for lucumaaglass.in

## 🔍 Problem Identified

The domain `lucumaaglass.in` is returning **403 Forbidden** because traffic is being routed through **Hostinger's LiteSpeed proxy** instead of directly to your VPS's Nginx server.

**Evidence:**
- Direct IP access works: ✅ http://147.79.104.84 (Returns 200 OK with Nginx)
- Domain access fails: ❌ http://lucumaaglass.in (Returns 403 with LiteSpeed)
- DNS resolves correctly to: 147.79.104.84

---

## ✅ Solution: Disable Hostinger Proxy/CDN

You need to log into Hostinger and change the DNS settings to point **DIRECTLY** to your VPS IP without any proxy.

### Step-by-Step Instructions:

1. **Login to Hostinger Control Panel (hPanel)**
   - Go to: https://hpanel.hostinger.com
   - Login with your credentials

2. **Navigate to Domain Settings**
   - Click on "Domains" in the left menu
   - Find and click on `lucumaaglass.in`

3. **Check DNS Records**
   - Go to "DNS / Nameservers" section
   - Look for these records:

   **Current (Incorrect) Setup - Using Proxy:**
   ```
   Type: A
   Name: @
   Points to: [Some Hostinger IP or proxy]
   Proxy Status: ON (Orange cloud icon if using Cloudflare-style proxy)
   ```

   **Required (Correct) Setup - Direct:**
   ```
   Type: A
   Name: @
   Points to: 147.79.104.84
   Proxy Status: OFF (Gray cloud icon or no proxy)
   TTL: 14400 (or 3600)
   ```

4. **Update A Records**
   - Set `@` (root domain) to point to: `147.79.104.84`
   - Set `www` subdomain to point to: `147.79.104.84`
   - Make sure "Proxy" or "CDN" is **DISABLED** (turned OFF)

5. **Verify No Redirect Rules**
   - Check if there are any redirect rules in Hostinger
   - Remove any redirects for lucumaaglass.in

6. **Wait for DNS Propagation**
   - DNS changes can take 5-30 minutes
   - Sometimes up to 24 hours for full global propagation

---

## 🎯 Alternative: Use Host Header to Bypass (Temporary)

While waiting for DNS to fully propagate, you can access your site by forcing the host header:

```bash
curl -H "Host: lucumaaglass.in" http://147.79.104.84
```

Or add this to your local hosts file (`/etc/hosts` on Mac/Linux):
```
147.79.104.84  lucumaaglass.in
```

---

## ✅ Verification Commands

After making DNS changes, wait 10-15 minutes, then test:

```bash
# Test 1: Check DNS resolution
nslookup lucumaaglass.in
# Should show: Address: 147.79.104.84

# Test 2: Check server response
curl -I http://lucumaaglass.in
# Should show: Server: nginx (NOT LiteSpeed)

# Test 3: Check HTML content
curl -s http://lucumaaglass.in | head -5
# Should show your React app HTML

# Test 4: Check for Hostinger headers
curl -I http://lucumaaglass.in 2>&1 | grep -i "platform\|litespeed\|hostinger"
# Should return NOTHING (empty)
```

---

## 📋 Current Status

| Test | Status | Notes |
|------|--------|-------|
| VPS IP (147.79.104.84) | ✅ Works | Returns 200 OK with Nginx |
| Domain (lucumaaglass.in) | ❌ Fails | Returns 403 with LiteSpeed |
| DNS Resolution | ✅ Correct | Points to 147.79.104.84 |
| Issue | 🔍 Found | Hostinger proxy/CDN interfering |

---

## 🚨 Common Hostinger Settings to Check

### 1. Website Management
- **Setting:** Website → Manage
- **Action:** Make sure website is NOT pointing to any Hostinger hosting
- **Should be:** Empty or pointing to VPS

### 2. CDN Settings
- **Setting:** Advanced → CDN
- **Action:** Disable any CDN service
- **Should be:** OFF/Disabled

### 3. DNS Management
- **Setting:** DNS Zone
- **Action:** 
  - Remove any CNAME records pointing to Hostinger servers
  - Ensure A records point directly to 147.79.104.84
  - No proxy enabled

### 4. Nameservers
- **Current:** Should be using Hostinger's nameservers OR custom nameservers
- **If using Hostinger NS:** Make sure A records are correct (see above)
- **Alternative:** Use external DNS like Cloudflare (with proxy OFF) or Google Cloud DNS

---

## 🔄 If Using Cloudflare

If you're routing through Cloudflare:

1. Login to Cloudflare dashboard
2. Select `lucumaaglass.in` domain
3. Go to DNS settings
4. Find A records for `@` and `www`
5. **Click the orange cloud icon to turn it GRAY** (Proxy OFF)
6. Verify A record points to: 147.79.104.84
7. Wait 5-10 minutes

---

## ✅ What Should Happen After Fix

Once DNS is properly configured (no proxy):

1. **Domain will work:** http://lucumaaglass.in
2. **Shows your app:** Glass ERP login page
3. **Server header:** nginx (not LiteSpeed)
4. **No 403 error:** Returns 200 OK
5. **Can login with:** admin@lucumaa.in / Lucumaa@@123

---

## 🆘 If Still Not Working After 30 Minutes

Try these additional steps:

1. **Clear DNS Cache (on your Mac):**
   ```bash
   sudo dscacheutil -flushcache
   sudo killall -HUP mDNSResponder
   ```

2. **Check from Different Location:**
   - Use: https://www.whatsmydns.net/#A/lucumaaglass.in
   - Should show 147.79.104.84 globally

3. **Use Different DNS Server:**
   ```bash
   nslookup lucumaaglass.in 8.8.8.8
   ```

4. **Test with VPN or Mobile Data:**
   - Your ISP might be caching old DNS

---

## 📞 Contact Hostinger Support

If you can't find the proxy/CDN setting:

**Support Info:**
- Live Chat: https://www.hostinger.com/contact
- Tell them: "I need to disable any proxy/CDN for lucumaaglass.in and point it directly to my VPS IP 147.79.104.84"

---

## ✅ Once Fixed - Test Login

After the domain works:

1. Open: http://lucumaaglass.in
2. Should see Glass ERP login page
3. Login with:
   - Email: **admin@lucumaa.in**
   - Password: **Lucumaa@@123**

---

## 🎯 Summary

**The Problem:** Hostinger's LiteSpeed proxy is intercepting traffic

**The Solution:** Disable proxy/CDN in Hostinger DNS settings

**The Result:** Traffic goes directly to your VPS Nginx → Your app works

**Timeline:** 5-30 minutes after making DNS changes

---

**Current Working URL:** http://147.79.104.84 (Use this until domain is fixed)
