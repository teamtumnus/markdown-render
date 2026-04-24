#!/bin/zsh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
BUILD_DIR="$ROOT_DIR/.build"
DIST_DIR="$ROOT_DIR/dist/MarkdownRender.app"
ICON_SOURCE="$ROOT_DIR/Assets/MarkdownRenderIcon.svg"
ICON_PNG="$BUILD_DIR/MarkdownRenderIcon.png"
ICONSET_DIR="$BUILD_DIR/MarkdownRender.iconset"
ICON_DEST="$DIST_DIR/Contents/Resources/MarkdownRender.icns"
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

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

swift "$ROOT_DIR/scripts/render_icon.swift" "$ICON_SOURCE" "$ICON_PNG"

for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
  doubled=$((size * 2))
  sips -z "$doubled" "$doubled" "$ICON_PNG" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

if ! iconutil -c icns "$ICONSET_DIR" -o "$ICON_DEST" >/dev/null 2>&1; then
  swift "$ROOT_DIR/scripts/write_icns.swift" "$ICONSET_DIR" "$ICON_DEST"
fi

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
  <key>CFBundleIconFile</key>
  <string>MarkdownRender</string>
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

codesign --force --deep --sign - "$DIST_DIR"

echo "Built app bundle at $DIST_DIR"
