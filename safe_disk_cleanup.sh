#!/bin/bash
# Safe Disk Cleanup - Preserves StryVr & Branchr projects

echo "🧹 Safe Disk Cleanup for Xcode"
echo "================================"
echo ""

echo "📊 Current disk usage in target folders:"
du -sh ~/Library/Developer/Xcode/iOS\ DeviceSupport 2>/dev/null
du -sh ~/Library/Developer/CoreSimulator 2>/dev/null
du -sh ~/Library/Developer/XCPGDevices 2>/dev/null
du -sh ~/Library/Developer/Xcode/DocumentationCache 2>/dev/null

echo ""
echo "✅ These are SAFE to delete (Xcode will re-download when needed):"
echo ""

# Clean iOS DeviceSupport (5.2GB)
echo "🧹 Cleaning iOS DeviceSupport (5.2GB)..."
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*
echo "✅ Freed ~5.2GB"

# Clean old simulators (6.1GB)
echo "🧹 Cleaning old iOS Simulators (6.1GB)..."
xcrun simctl delete unavailable 2>/dev/null || true
echo "✅ Cleaned unavailable simulators"

# Clean XCPGDevices (1.4GB)
echo "🧹 Cleaning Playground Devices (1.4GB)..."
rm -rf ~/Library/Developer/XCPGDevices/*
echo "✅ Freed ~1.4GB"

# Clean DocumentationCache (236MB)
echo "🧹 Cleaning Documentation Cache (236MB)..."
rm -rf ~/Library/Developer/Xcode/DocumentationCache/*
echo "✅ Freed ~236MB"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📊 Remaining Xcode folders (preserved):"
du -sh ~/Library/Developer/Xcode/UserData 2>/dev/null
echo ""
echo "💡 Xcode will re-download device support and simulators as needed."
echo "💡 Your StryVr and Branchr projects are untouched."

