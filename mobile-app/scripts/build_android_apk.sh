#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter not found. Install Flutter and ensure 'flutter' is on PATH."
  exit 127
fi

# Generate missing platform folders if needed (android/ios)
flutter create . >/dev/null

flutter pub get

# Build a release APK (installable on Android)
flutter build apk --release --dart-define=APP_ENV=prod

echo
echo "APK generated at: build/app/outputs/flutter-apk/app-release.apk"
