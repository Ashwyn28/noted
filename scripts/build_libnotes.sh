#!/bin/bash

# Build script for creating XCFramework from Zig library
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIBNOTES_DIR="$PROJECT_ROOT/libnotes"
BUILD_DIR="$PROJECT_ROOT/build"
FRAMEWORKS_DIR="$PROJECT_ROOT/NotesApp/Frameworks"

echo "Building libnotes for multiple architectures..."

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$FRAMEWORKS_DIR"

cd "$LIBNOTES_DIR"

# Build for macOS architectures
echo "Building for macOS arm64..."
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseFast
cp zig-out/lib/libnotes.a "$BUILD_DIR/libnotes-macos-arm64.a"

echo "Building for macOS x86_64..."
zig build -Dtarget=x86_64-macos -Doptimize=ReleaseFast
cp zig-out/lib/libnotes.a "$BUILD_DIR/libnotes-macos-x86_64.a"

# Create universal binary
echo "Creating universal binary..."
lipo -create \
    "$BUILD_DIR/libnotes-macos-arm64.a" \
    "$BUILD_DIR/libnotes-macos-x86_64.a" \
    -output "$BUILD_DIR/libnotes-universal.a"

# Generate header file
echo "Generating C header..."
zig build-lib src/main.zig -femit-h="$BUILD_DIR/libnotes.h" -target aarch64-macos --name libnotes

# Create framework structure
FRAMEWORK_DIR="$BUILD_DIR/libnotes.framework"
mkdir -p "$FRAMEWORK_DIR/Headers"
mkdir -p "$FRAMEWORK_DIR/Modules"

# Copy files to framework
cp "$BUILD_DIR/libnotes-universal.a" "$FRAMEWORK_DIR/libnotes"
cp "$BUILD_DIR/libnotes.h" "$FRAMEWORK_DIR/Headers/"

# Create Info.plist
cat > "$FRAMEWORK_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>libnotes</string>
    <key>CFBundleIdentifier</key>
    <string>com.noted.libnotes</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>libnotes</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF

# Create module map
cat > "$FRAMEWORK_DIR/Modules/module.modulemap" << EOF
framework module libnotes {
    umbrella header "libnotes.h"
    
    export *
    module * { export * }
}
EOF

# Create XCFramework
echo "Creating XCFramework..."
rm -rf "$FRAMEWORKS_DIR/libnotes.xcframework"
xcodebuild -create-xcframework \
    -framework "$FRAMEWORK_DIR" \
    -output "$FRAMEWORKS_DIR/libnotes.xcframework"

echo "✅ XCFramework created at: $FRAMEWORKS_DIR/libnotes.xcframework"
echo "🔗 You can now link this in your Xcode project"