# Lucumaa Glass ERP (Flutter)

Production-oriented Flutter app skeleton implementing:
- Riverpod state management
- Dio REST client with JWT + refresh + 401 auto-logout
- Role-based routing (Admin/Manager/Operator/Sales/HR/Dealer)
- Material 3 + dark mode
- Firebase push notifications (skeleton)

## Setup

1. Install Flutter (latest stable) and run:
   - `flutter doctor`

2. Fetch packages:
   - `flutter pub get`

3. Firebase (required for push notifications):
   - Add `android/app/google-services.json`
   - Add `ios/Runner/GoogleService-Info.plist`
   - Ensure Firebase is configured for your bundle IDs.

4. Run:
   - `flutter run`

## Build an installable Android APK

### Option A: Local build (recommended)

1. Install Flutter and ensure it works:
   - `flutter --version`
   - `flutter doctor`

2. Build APK:
   - `bash scripts/build_android_apk.sh`

Output file:
- `build/app/outputs/flutter-apk/app-release.apk`

### Option B: GitHub Actions (no local Flutter required)

1. Push this repo to GitHub.
2. Open **Actions** → **Build Android APK** → **Run workflow**.
3. Download artifact `lucumaa-glass-erp-android-apk` → `app-release.apk`.

## Environments (dev/staging/prod)

This app reads environment via dart-define:
- `APP_ENV`: dev | staging | prod
- `API_BASE_URL`: override base API URL (optional)

Examples:
- `flutter run --dart-define=APP_ENV=dev`
- `flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://example.com/api`

## Tests

- `flutter test`

## Native platform folders

This repo currently contains the Dart/Flutter `lib/` implementation. If `android/` and `ios/` folders are missing in your workspace, generate them with:
- `flutter create .`

## Secure Screens (Prevent Screenshots)

Sensitive screens are wrapped with `SensitiveScreen`, which calls a platform `MethodChannel` (`lucumaa_glass/security`).

Add native implementations:
- Android: set/clear `FLAG_SECURE` on the activity window
- iOS: use a secure overlay technique (commonly a secure text field layer)

## Backend

Base URL: `https://lucumaaglass.in/api/`

Endpoints used in this skeleton (adjust to your real API contract):
- `POST /auth/login`
- `POST /auth/refresh`
- `GET /me`

You can update endpoints in `lib/core/config/app_config.dart`.
