# Quick Debug Guide - Test Your Live Backend

## Does Login Work With Actual Credentials?

### Test 1: Verify Backend API (No App Needed)

Open your terminal and run this command with YOUR actual password:

```bash
curl -X POST https://lucumaaglass.in/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "kiranpatil86@gmail.com",
    "password": "YOUR_ACTUAL_PASSWORD"
  }' \
  -s | python3 -m json.tool
```

**What to look for:**
- ✓ HTTP 200 = Success! You should get a token
- ✗ HTTP 401 = Wrong credentials or user doesn't exist
- ✗ HTTP 500 = Server error

**Expected Success Response Format:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "...",
    "name": "...",
    "email": "kiranpatil86@gmail.com",
    "role": "admin"  // This is important!
  }
}
```

OR:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "...",
  "expires_in": 3600
}
```

Save the `access_token` or `token` value (copy the full token string).

---

### Test 2: Verify Profile Endpoint

Use the token from Test 1:

```bash
curl -X GET https://lucumaaglass.in/api/auth/me \
  -H 'Authorization: Bearer PASTE_YOUR_TOKEN_HERE' \
  -H 'Content-Type: application/json' \
  -s | python3 -m json.tool
```

**What to look for:**
- ✓ HTTP 200 = User profile returned
-  ✗ HTTP 401 = Token not accepted
- ✗ HTTP 403 = Not authenticated
- ✗ HTTP 404 = Endpoint doesn't exist

**Expected Success Response:**
```json
{
  "id": "user-id",
  "name": "User Name",
  "email": "kiranpatil86@gmail.com",
  "role": "admin"  // or "manager", "operator", etc.
}
```

OR with wrapper:
```json
{
  "data": {
    "id": "...",
    "name": "...",
    "email": "...",
    "role": "admin"
  }
}
```

---

## Troubleshooting

### If Login Gets Token but Profile Fails

**Problem:** API returns different user data format in login vs profile endpoints

**Solution:** Contact backend team about format consistency or we'll update the parser

### If Login Returns "Unknown"

**Problem:** You might be getting back fields named differently than expected

**Solution:** Copy the ENTIRE response you got from Test 1 and share it

### If Login Returns Empty Fields

**Problem:** API might be returning token without user object

**Solution:** App will need to do TWO API calls: login (get token), then fetch me() with token

---

## What the App Expects

The app is configured to work with these token field names (in this order of priority):
1. `access_token`
2. `accessToken`
3. `token`
4. `jwt`
5. Or nested: `data.access_token` or `data.token`

The app expects the role field to be:
1. At root level: `role: "admin"`
2. Or nested: `data.role: "admin"`
3. Or in user object: `user: {role: "admin"}`

---

## Send This Information

Once you've run the curl tests, please provide:

1. **Full JSON response from login endpoint**
2. **Full JSON response from me endpoint**
3. **Any error messages from either endpoint**
4. **Token field names used** (is it `access_token` or `token`?)
5. **Role location in response** (at root or nested?)

Example of what to send:

```
Login Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123",
    "name": "Kiran Patil",
    "email": "kiranpatil86@gmail.com",
    "role": "admin"
  },
  "expires_in": 86400
}

Profile Response:
{
  "data": {
    "id": "123",
    "name": "Kiran Patil",
    "email": "kiranpatil86@gmail.com",
    "role": "admin"
  }
}
```

Then the developer can update the app parsers to match exactly.

---

## If Auth Codes Are Protected

If your backend requires special authorization to test these endpoints, you might need to:

1. Ask backend team to run tests
2. Provide a special test user/password
3. Verify API is working in a separate REST client (Postman, Insomnia, etc.)

---

**Main Goal:** Understand exactly what format your live backend returns so the app can parse it correctly.
