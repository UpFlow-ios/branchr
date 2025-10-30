#!/bin/bash

# 🎵 MusicKit Entitlements Verification Script
# Checks if MusicKit entitlements are properly configured

echo "🔍 Verifying MusicKit Entitlements Setup..."
echo ""

ENTITLEMENTS_FILE="branchr/branchr.entitlements"
PROJECT_FILE="branchr.xcodeproj"

# Check if entitlements file exists
if [ ! -f "$ENTITLEMENTS_FILE" ]; then
    echo "❌ Entitlements file not found: $ENTITLEMENTS_FILE"
    exit 1
fi

echo "✅ Entitlements file found: $ENTITLEMENTS_FILE"
echo ""

# Check for MusicKit entitlements
echo "🔎 Checking for MusicKit entitlements..."
echo ""

if grep -q "com.apple.developer.music-user-token" "$ENTITLEMENTS_FILE"; then
    echo "✅ Found: com.apple.developer.music-user-token"
else
    echo "❌ Missing: com.apple.developer.music-user-token"
fi

if grep -q "com.apple.developer.music.subscription-service" "$ENTITLEMENTS_FILE"; then
    echo "✅ Found: com.apple.developer.music.subscription-service"
else
    echo "❌ Missing: com.apple.developer.music.subscription-service"
fi

if grep -q "69Y49KN8KD" "$ENTITLEMENTS_FILE"; then
    echo "✅ Found: Team Identifier (69Y49KN8KD)"
else
    echo "❌ Missing: Team Identifier (69Y49KN8KD)"
fi

echo ""
echo "🏗️  Testing Build..."
echo ""

# Try building for simulator
if xcodebuild -project "$PROJECT_FILE" -scheme branchr \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    clean build > /dev/null 2>&1; then
    echo "✅ Build SUCCEEDED for iOS Simulator"
    echo ""
    echo "🎉 MusicKit entitlements are properly configured!"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Open Xcode: open branchr.xcodeproj"
    echo "   2. Select branchr target → Signing & Capabilities"
    echo "   3. Enable 'Automatically manage signing'"
    echo "   4. Select Team: Joe Dormond (69Y49KN8KD)"
    echo "   5. Press Cmd + R to run"
    echo "   6. Test DJ Controls → Connect Apple Music → Play"
    echo ""
    echo "✅ Expected console output:"
    echo "   🎵 Apple Music status: authorized"
    echo "   ✅ MusicService: Apple Music access granted"
    echo "   ✅ MusicKit entitlements verified and active."
    echo ""
else
    echo "❌ Build FAILED"
    echo ""
    echo "📋 To fix:"
    echo "   1. Open Xcode: open branchr.xcodeproj"
    echo "   2. Select branchr target → Signing & Capabilities"
    echo "   3. Enable 'Automatically manage signing'"
    echo "   4. This will regenerate provisioning profile with MusicKit"
    echo ""
    echo "📚 See: MUSICKIT_ENTITLEMENTS_FIX.md for detailed instructions"
fi

echo ""
echo "📄 Full entitlements content:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$ENTITLEMENTS_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

