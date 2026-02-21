# Lucumaa Glass ERP Mobile App - Current Status & Issues

## CRITICAL FIXES APPLIED ✓

### 1. Email/Password Parameter Alignment (FIXED)
- **Issue**: AuthNotifier.login() had `username` parameter but should be `email`
- **Fix Applied**: 
  - Changed AuthNotifier.login(username:) → login(email:)
  - Updated LoginFormNotifier to call with email: parameter
  - **Root Cause**: Login was working but parameter naming mismatch could cause confusion
  - **Status**: ✓ FIXED in code

### 2. Role-Based Dashboard Routing  
- **Current Status**: Code structure is correct
  - Role enum has proper fromApi() conversion (handles string → enum)
  - AuthRepository calls api.meWithToken() after login to fetch user profile
  - RoleHomeShell maps role correctly to dashboard screens
  - **Possible Issues**:
    1. API response may have role in unexpected format (e.g., {"user": {"role": "admin"}})
    2. API's /auth/me might return different user format than /auth/login
  - **Next Debugging Step**: Inspect actual API responses with curl

### 3. Login Failure for kiranpatil86@gmail.com
- **Cause**: Unknown - could be:
  - Token parsing issue (api.meWithToken might fail if user fetch fails)
  - API response format mismatch
  - Network/SSL certificate issue
  - Credentials wrong on backend
- **Next Debugging Step**: Test with curl commands to inspect live backend responses

## BUILD INFRASTRUCTURE ISSUE

### Android SDK / Gradle Mismatch
- **Error**: `Error resolving plugin [id: 'dev.flutter.flutter-plugin-loader', version: '1.0.0'] > 25.0.2`
- **Cause**: Gradle 8.1.0 requires Android SDK build-tools 25.0.2+ but system doesn't have it
- **Options**:
  1. Downgrade android/settings.gradle to Gradle 7.x (compatible with current SDK)
  2. Install missing Android SDK build-tools
  3. Use previous working APK for testing while fixing Gradle

**RECOMMENDED**: Use existing APK at `build/app/outputs/apk/release/app-release.apk` for front-end testing while investigating Gradle build separately.

---

## DEBUGGING STEPS FOR FUNCTIONAL ISSUES

### Test 1: Inspect Live Backend Login Response
```bash
curl -X POST https://lucumaaglass.in/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email": "kiranpatil86@gmail.com", "password": "YOUR_PASSWORD"}' \
  -v
```
**What to look for**:
- Does `access_token` field exist?
- Any other token fields (token, jwt, data.access_token)?
- Response structure?

### Test 2: Inspect Profile Response
```bash
curl -X GET https://lucumaaglass.in/api/auth/me \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -v
```
**What to look for**:
- Does response have `role` field?
- Is role a string "admin" or nested like `data.role`?
- Does response have user wrapped in `data` or at root?
- What are all fields returned?

### Test 3: Check App Logs After Login
When you install the new APK:
1. Run `flutter run` with `--dart-define=APP_ENV=prod` 
2. Watch console output for:
   - Token parsing logs
   - API response logs (LoggingInterceptor should log all responses)
   - Role parsing logs

### Test 4: Verify Role Mapping
After login, you should see:
- Admin role → Admin Dashboard with (Dashboard, Orders, Reports tabs)
- Operator role → Operator Dashboard with (Orders, Update Status, Photos tabs)
- Dealer role → Dealer Dashboard with (Dashboard, Orders, Payments tabs)

---

## FILES MODIFIED (This Session)
1. ✓ lib/providers/auth/auth_notifier.dart - Fixed parameter username→email
2. ✓ lib/providers/auth/login_form.dart - Fixed parameter call email:

## PREVIOUSLY WORKING STATE
- APK built successfully before Gradle issue
- Located at: `build/app/outputs/apk/release/app-release.apk`
- Installed on device - login screen appears and accepts input
- Needs: Testing with actual backend credentials and debugging role display

---

## NEXT STEPS (Prioritized)

### PRIORITY 1: Debug Actual Backend Responses
- Run curl commands above with real credentials
- Document exact API response format
- Update code if needed to match actual backend responses

### PRIORITY 2: Fix Gradle Build
- Either downgrade Android Gradle Plugin to 7.x
- OR install Android SDK build-tools 25.0.2+
- Goal: Get `flutter build apk --release` working without errors

### PRIORITY 3 : Install & Test Fixed APK
- Build new APK with auth parameter fixes
- Test login with actual backend user
- Verify correct role dashboard displays
- Capture logs for any login/role parsing errors

### PRIORITY 4: Add Debugging Logs
- Add log statements in auth_repository.dart for token parsing
- Add log statements in user.dart for role parsing
- Make it easier to identify issues when real users test

---

## TECHNICAL CONTEXT

**Backend API** (confirmed):
- Login: POST /api/auth/login (expects email + password)
- Profile: GET /api/auth/me (needs Bearer token)
- Logout: Not yet implemented
- Refresh: No endpoint found (disabled in-app)

**App Structure**:
- State: Riverpod (AuthNotifier maintains user + tokens)
- Network: Dio with custom interceptors (auth, 401 handling, logging)
- Storage: flutter_secure_storage (tokens only)
- Forms: Formz with custom validators
- Routing: GoRouter with role-based guards

**Test User**:
- Email: kiranpatil86@gmail.com
- Status: Exists in backend database
- Issue: Login fails (unknown cause - needs debugging)

