#!/usr/bin/env bash
set -euo pipefail

echo "[1/5] Updating apt index..."
sudo apt-get update

echo "[2/5] Installing Linux desktop build dependencies..."
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev

echo "[3/5] Installing browser for Flutter web run..."
if apt-cache show chromium >/dev/null 2>&1; then
  sudo apt-get install -y chromium
elif apt-cache show chromium-browser >/dev/null 2>&1; then
  sudo apt-get install -y chromium-browser
else
  echo "No chromium package found in apt repositories."
  echo "Install Chrome/Chromium manually, then set CHROME_EXECUTABLE."
fi

echo "[4/5] Enabling Flutter targets..."
flutter config --enable-linux-desktop --enable-web

echo "[5/5] Verifying environment..."
flutter doctor -v

if command -v chromium >/dev/null 2>&1; then
  echo "Exporting CHROME_EXECUTABLE for current shell: $(command -v chromium)"
  export CHROME_EXECUTABLE="$(command -v chromium)"
elif command -v chromium-browser >/dev/null 2>&1; then
  echo "Exporting CHROME_EXECUTABLE for current shell: $(command -v chromium-browser)"
  export CHROME_EXECUTABLE="$(command -v chromium-browser)"
fi

echo "Environment setup complete."
echo "Next:"
echo "  cd /workspaces/smart_class_app/smart_class_app"
echo "  flutter pub get"
echo "  flutter run -d linux   # or: flutter run -d chrome"