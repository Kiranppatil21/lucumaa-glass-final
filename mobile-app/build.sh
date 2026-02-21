#!/bin/bash
set -e

# Configure Flutter mirrors for faster downloads
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export PUB_HOSTED_URL=https://pub.flutter-io.cn

FLUTTER_BIN="./.tools/flutter/bin/flutter"

echo "===== STEP 1: Flutter Doctor ====="
"$FLUTTER_BIN" doctor

echo ""
echo "===== STEP 2: Clean Build ====="
"$FLUTTER_BIN" clean

echo ""
echo "===== STEP 3: Get Dependencies ====="
"$FLUTTER_BIN" pub get

echo ""
echo "===== STEP 4: Build Release APK ====="
"$FLUTTER_BIN" build apk --release --dart-define=APP_ENV=prod

echo ""
echo "===== BUILD COMPLETE ====="
echo "APK location: build/app/outputs/apk/release/app-release.apk"
