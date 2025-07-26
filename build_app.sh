#!/bin/bash

set -e

echo "Building Noted.app..."

# Clean previous builds
rm -rf Noted.app
rm -rf .build

# Build the Swift executable
swift build -c release

# Create app bundle structure
mkdir -p Noted.app/Contents/MacOS
mkdir -p Noted.app/Contents/Resources

# Copy executable
cp .build/release/Noted Noted.app/Contents/MacOS/

# Create Info.plist
cat > Noted.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Noted</string>
    <key>CFBundleExecutable</key>
    <string>Noted</string>
    <key>CFBundleIdentifier</key>
    <string>com.noted.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Noted</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Make executable
chmod +x Noted.app/Contents/MacOS/Noted

echo "✅ Noted.app created successfully!"
echo "🚀 Run with: open Noted.app"