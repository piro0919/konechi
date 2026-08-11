#!/bin/bash
# Konechi をビルドして Konechi.app を作る。Xcode 本体は不要（Command Line Tools のみで動く）。
set -euo pipefail

cd "$(dirname "$0")"

APP="Konechi.app"
TARGET="arm64-apple-macos14.0"
SPARKLE_VERSION="2.9.5"

# 自動更新に Sparkle を使う。framework は大きいのでリポジトリに置かず、
# 無ければ取ってくる（Vendor/ は git の管理外）
if [ ! -d "Vendor/Sparkle.framework" ]; then
  echo "Sparkle $SPARKLE_VERSION を取得します…"
  mkdir -p Vendor
  TMP="$(mktemp -d)"
  curl -sL -o "$TMP/sparkle.tar.xz" \
    "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz"
  tar xf "$TMP/sparkle.tar.xz" -C "$TMP"
  cp -R "$TMP/Sparkle.framework" Vendor/
  cp -R "$TMP/bin" Vendor/
  rm -rf "$TMP"
fi

rm -rf "$APP" build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks"

cp -R Vendor/Sparkle.framework "$APP/Contents/Frameworks/"

swiftc \
  -parse-as-library \
  -target "$TARGET" \
  -O \
  -F Vendor \
  -framework AppKit \
  -framework Network \
  -framework SystemConfiguration \
  -framework Sparkle \
  -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
  -o "$APP/Contents/MacOS/Konechi" \
  Sources/Localization.swift Sources/Link.swift Sources/Icon.swift \
  Sources/Settings.swift Sources/Updater.swift Sources/SettingsWindow.swift Sources/main.swift

# キャラの絵は Resources に konechi-<状態>.png で置く。無ければ記号で代用されるので、
# ディレクトリが空でもビルドは通る
if [ -d Resources ]; then
  mkdir -p "$APP/Contents/Resources"
  cp -R Resources/. "$APP/Contents/Resources/"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Konechi</string>
  <key>CFBundleDisplayName</key><string>Konechi</string>
  <key>CFBundleExecutable</key><string>Konechi</string>
  <key>CFBundleIdentifier</key><string>local.konechi</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <!-- Dock とアプリ切替に出さず、メニューバーだけに常駐させる -->
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>

  <!-- 自動更新（Sparkle）。確認は起動時に1回だけ行い、見つかったときだけ画面を出す。
       この2つを false にしておかないと、初回起動で「自動で確認していいか」を尋ねる画面が出る -->
  <key>SUFeedURL</key><string>https://github.com/piro0919/konechi/releases/latest/download/appcast.xml</string>
  <!-- 更新の署名を確かめる公開鍵。対になる秘密鍵はログインキーチェーンにあり、これを失うと更新を配れなくなる -->
  <key>SUPublicEDKey</key><string>qYQq1iewXYNDhhkJJak1nXUXmFkZ0jAF6Gr+pjB4Bxo=</string>
  <key>SUEnableAutomaticChecks</key><false/>
  <key>SUAutomaticallyUpdate</key><false/>
</dict>
</plist>
PLIST

# framework は中から署名する。先にアプリを署名すると、後から中身が変わって壊れる
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Autoupdate" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app" 2>/dev/null || true
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework"
codesign --force --sign - "$APP"

echo "できました: $(pwd)/$APP"
