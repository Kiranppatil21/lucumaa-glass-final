# Release Checklist (Play Store / App Store)

## Flavors
- Build with `--dart-define=APP_ENV=dev|staging|prod`
- Optionally set `--dart-define=API_BASE_URL=...`

## Android
- Enable ProGuard / R8, verify `minSdkVersion` and `targetSdkVersion`
- Set appId / versionName / versionCode
- Configure signing (upload key + keystore)
- Verify `FLAG_SECURE` native implementation if you need screenshot prevention

## iOS
- Set bundle identifier, version, build number
- Configure signing + capabilities
- Verify notification permission strings in `Info.plist`

## General
- Ensure Firebase configs are added
- Verify logout on 401 works with backend
- Run `flutter test`
- Run `flutter analyze`
