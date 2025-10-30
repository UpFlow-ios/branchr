# 🎵 MusicKit Entitlements Fix - Complete Guide

## ✅ What We Just Did

1. **Added MusicKit entitlements** to `branchr/branchr.entitlements`:
   - `com.apple.developer.music-user-token` ✅
   - `com.apple.developer.music.subscription-service` ✅
   - `com.apple.developer.team-identifier: 69Y49KN8KD` ✅

2. **Added verification logging** to `MusicService.swift`
3. **Verified app entry point** (`branchrApp.swift` → `BranchrAppRoot()`) ✅

---

## ⚠️ Current Issue

Build error:
```
Provisioning profile "Mac Team Provisioning Profile: com.joedormond.branchr" 
doesn't include the com.apple.developer.music-user-token and 
com.apple.developer.music.subscription-service entitlements.
```

**Why this happens:**
- We added entitlements to the file
- But the provisioning profile on Apple's servers doesn't include them yet
- Xcode needs to regenerate the provisioning profile

---

## 🔧 Fix Option 1: Automatic Provisioning (Recommended)

### **Steps:**

1. **Open Xcode:**
   ```bash
   cd /Users/joedormond/Documents/branchr
   open branchr.xcodeproj
   ```

2. **Select the `branchr` target:**
   - Click on project name in left sidebar
   - Select `branchr` under TARGETS

3. **Go to Signing & Capabilities tab**

4. **Enable Automatic Signing:**
   - Check "Automatically manage signing"
   - Select Team: **Joe Dormond (69Y49KN8KD)**

5. **Xcode will automatically:**
   - Read the new entitlements from `branchr.entitlements`
   - Generate a new provisioning profile
   - Upload it to Apple's servers
   - Download and install it

6. **Wait for "Signing Certificate" to appear** (usually 10-30 seconds)

7. **Build again:**
   - Press `Cmd + B`
   - Should succeed! ✅

---

## 🔧 Fix Option 2: Manual Profile Refresh

If automatic doesn't work:

1. **Open Xcode** → `branchr` target → Signing & Capabilities

2. **Uncheck** "Automatically manage signing"

3. **Wait 2 seconds**

4. **Re-check** "Automatically manage signing"

5. **Select team again:** Joe Dormond (69Y49KN8KD)

6. **Xcode will regenerate** the provisioning profile

7. **Build:** `Cmd + B`

---

## 🔧 Fix Option 3: Developer Portal Update

If Xcode can't auto-generate:

### **A. Enable MusicKit for App ID:**

1. Go to: https://developer.apple.com/account
2. Certificates, Identifiers & Profiles
3. Identifiers → Find `com.joedormond.branchr`
4. Scroll to **"App Services"**
5. Check **"MusicKit"** checkbox
6. Click **"Configure"**
7. Select your Music ID: `media.com.joedormond.branchr`
8. Click **"Save"**
9. Click **"Continue"** → **"Save"**

### **B. Regenerate Provisioning Profile:**

1. Still in developer.apple.com
2. Click **"Profiles"** (left sidebar)
3. Find profile: `Mac Team Provisioning Profile: com.joedormond.branchr`
4. Click **"Edit"**
5. Click **"Generate"** or **"Download"**
6. Download the `.mobileprovision` file

### **C. Install in Xcode:**

1. Double-click the downloaded `.mobileprovision` file
2. Xcode will import it automatically
3. Or manually: `~/Library/MobileDevice/Provisioning Profiles/`

### **D. Build:**

```bash
cd /Users/joedormond/Documents/branchr
xcodebuild -project branchr.xcodeproj -scheme branchr clean build
```

---

## 🔧 Fix Option 4: iOS Simulator Workaround

For testing in simulator (bypasses provisioning):

1. **Change destination to simulator:**
   ```bash
   cd /Users/joedormond/Documents/branchr
   xcodebuild -project branchr.xcodeproj -scheme branchr \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
     clean build
   ```

2. **Simulator doesn't require provisioning profiles**
3. **MusicKit will still work** (with library fallback)

---

## 🎯 Verification Steps

Once build succeeds:

### **1. Check Entitlements in Xcode:**

- Open Xcode
- Select `branchr` target
- Go to **Signing & Capabilities**
- Look for section showing:
  ```
  ✅ MusicKit
     - User Token
     - Subscription Service
  ```

### **2. Run the App:**

```bash
# Simulator (easier for testing)
xcodebuild -project branchr.xcodeproj -scheme branchr \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Then in Xcode: Cmd + R to run
```

### **3. Test DJ Controls:**

1. Open app
2. Tap "DJ Controls"
3. Tap "Connect Apple Music"
4. Tap "Play"

### **4. Watch Console for:**

```
🎵 Apple Music status: authorized
✅ MusicService: Apple Music access granted
✅ MusicKit entitlements verified and active.
```

---

## 📋 Complete Entitlements File

Your `branchr/branchr.entitlements` now contains:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
    
    <!-- ✅ MusicKit Entitlements (NEWLY ADDED) -->
    <key>com.apple.developer.music-user-token</key>
    <true/>
    <key>com.apple.developer.music.subscription-service</key>
    <true/>
    <key>com.apple.developer.team-identifier</key>
    <string>69Y49KN8KD</string>
    
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.joedormond.branchr</string>
    </array>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

---

## 🚀 Quick Solution (Recommended Path)

**For immediate testing:**

```bash
# 1. Build for simulator (bypasses provisioning)
cd /Users/joedormond/Documents/branchr
xcodebuild -project branchr.xcodeproj -scheme branchr \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' clean build

# 2. Open in Xcode and run
open branchr.xcodeproj
# Press Cmd + R
```

**For device/production:**

1. Open Xcode
2. Select `branchr` target
3. Signing & Capabilities tab
4. Enable "Automatically manage signing"
5. Select team: Joe Dormond (69Y49KN8KD)
6. Wait for profile regeneration
7. Build!

---

## ✅ Expected Results

### **Build Success:**
```
** BUILD SUCCEEDED **
```

### **Console Output:**
```
🎵 MusicService: Initialized (Hybrid Mode)
🎵 MusicService: Current authorization status: .authorized
✅ MusicKit entitlements verified and active.
🔍 Step 1: Attempting catalog search...
✅ Found in catalog: [Song Name]
🎶 Now playing from CATALOG: [Song Name]
```

---

## 🔍 Troubleshooting

### **Still getting provisioning error?**

**Try:**
1. Xcode → Preferences → Accounts
2. Select your Apple ID
3. Click "Download Manual Profiles"
4. Wait for sync
5. Build again

### **"Signing certificate not found"?**

**Try:**
1. Xcode → Preferences → Accounts
2. Apple ID → "Manage Certificates"
3. Click "+" → "Apple Development"
4. Close and rebuild

### **MusicKit still not appearing in capabilities?**

**Make sure:**
1. `branchr.entitlements` file is in project
2. Target → Build Settings → "Code Signing Entitlements" = `branchr/branchr.entitlements`
3. File is added to target (not just in folder)

---

## 📞 Quick Commands Reference

```bash
# Clean build
cd /Users/joedormond/Documents/branchr
xcodebuild -project branchr.xcodeproj -scheme branchr clean

# Build for simulator (recommended for testing)
xcodebuild -project branchr.xcodeproj -scheme branchr \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Build for device (requires valid provisioning)
xcodebuild -project branchr.xcodeproj -scheme branchr \
  -destination 'generic/platform=iOS' build

# Open in Xcode
open branchr.xcodeproj
```

---

## 🎯 Summary

✅ **Entitlements Added:**
- `com.apple.developer.music-user-token`
- `com.apple.developer.music.subscription-service`
- `com.apple.developer.team-identifier: 69Y49KN8KD`

✅ **Verification Logging Added:**
- "✅ MusicKit entitlements verified and active."

✅ **App Entry Point Verified:**
- `branchrApp` → `BranchrAppRoot()` ✅

⏳ **Next Step:**
- Enable automatic signing in Xcode (Fix Option 1)
- OR build for simulator (Fix Option 4)

---

**Made by:** Joe Dormond  
**Phase:** 18.4E - MusicKit Entitlements Integration  
**Date:** October 27, 2025

