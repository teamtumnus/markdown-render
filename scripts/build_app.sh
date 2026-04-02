#!/bin/zsh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
BUILD_DIR="$ROOT_DIR/.build"
DIST_DIR="$ROOT_DIR/dist/MarkdownRender.app"
MODULE_CACHE_DIR="${TMPDIR%/}/clang-module-cache"
SWIFTPM_CACHE_DIR="${TMPDIR%/}/swiftpm-module-cache"

mkdir -p "$MODULE_CACHE_DIR" "$SWIFTPM_CACHE_DIR"

export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR"
export SWIFTPM_MODULECACHE_OVERRIDE="$SWIFTPM_CACHE_DIR"

swift build \
  --configuration release \
  --disable-sandbox \
  --product MarkdownRender \
  --package-path "$ROOT_DIR"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/Contents/MacOS" "$DIST_DIR/Contents/Resources"

cp "$BUILD_DIR/release/MarkdownRender" "$DIST_DIR/Contents/MacOS/MarkdownRender"

PLIST_PATH="$DIST_DIR/Contents/Info.plist"
cat > "$PLIST_PATH" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>MarkdownRender</string>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeExtensions</key>
      <array>
        <string>md</string>
        <string>markdown</string>
      </array>
      <key>CFBundleTypeName</key>
      <string>Markdown Document</string>
      <key>CFBundleTypeRole</key>
      <string>Viewer</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
      <key>LSItemContentTypes</key>
      <array>
        <string>net.daringfireball.markdown</string>
      </array>
    </dict>
  </array>
  <key>CFBundleExecutable</key>
  <string>MarkdownRender</string>
  <key>CFBundleIdentifier</key>
  <string>local.markdown-render</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>MarkdownRender</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>UTImportedTypeDeclarations</key>
  <array>
    <dict>
      <key>UTTypeConformsTo</key>
      <array>
        <string>public.plain-text</string>
      </array>
      <key>UTTypeDescription</key>
      <string>Markdown Document</string>
      <key>UTTypeIdentifier</key>
      <string>net.daringfireball.markdown</string>
      <key>UTTypeTagSpecification</key>
      <dict>
        <key>public.filename-extension</key>
        <array>
          <string>md</string>
          <string>markdown</string>
        </array>
        <key>public.mime-type</key>
        <string>text/markdown</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
PLIST

echo "Built app bundle at $DIST_DIR"
