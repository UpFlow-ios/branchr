# 🔧 Fix: Provisioning Profile Missing MusicKit Entitlements

## ❌ Error Message

```
error: Provisioning profile "JJJJJJ" doesn't include the 
com.apple.developer.music-user-token and 
com.apple.developer.music.subscription-service entitlements.
```

## 🔍 Root Cause

The provisioning profile being used **does not have MusicKit entitlements enabled**. This happens when:

1. The App ID in Apple Developer Portal doesn't have MusicKit capability enabled
2. The provisioning profile was created/updated before MusicKit was enabled on the App ID
3. The profile needs to be regenerated after enabling MusicKit

---

## ✅ Solution Steps

### Step 1: Enable MusicKit on App ID (If Not Already Done)

1. **Go to Apple Developer Portal**
   - Visit [developer.apple.com](https://developer.apple.com)
   - Sign in with your Apple Developer account

2. **Navigate to App ID**
   - Go to **Certificates, Identifiers & Profiles**
   - Click **Identifiers**
   - Find and select: `com.joedormond.branchr2025`

3. **Enable MusicKit**
   - Scroll down to **Capabilities**
   - Check **MusicKit** ✅
   - Ensure **App Groups** is also checked ✅
   - Ensure **Sign in with Apple** is checked ✅
   - Click **Save**

4. **Wait for Apple Sync**
   - Apple's backend takes **15-45 minutes** to propagate changes
   - If you just enabled MusicKit, wait at least 30 minutes before proceeding

---

### Step 2: Update or Recreate Provisioning Profile

**Option A: Edit Existing Profile** (Recommended)

1. **Go to Profiles**
   - Apple Developer Portal → **Certificates, Identifiers & Profiles**
   - Click **Profiles**
   - Find **"PRO DEV ID"** (or "JJJJJJ" if that's your profile name)

2. **Edit Profile**
   - Click **Edit**
   - Verify the **App ID** is `com.joedormond.branchr2025`
   - Ensure **Certificate** is selected (Apple Development: Joseph Dormond)
   - Ensure your **test device** is included
   - Click **Generate** or **Save**

3. **Download New Profile**
   - Click **Download** button
   - Save the `.mobileprovision` file

**Option B: Create New Profile** (If editing doesn't work)

1. **Create New Profile**
   - Profiles → **+** button (top right)
   - Select **iOS App Development**
   - Select App ID: `com.joedormond.branchr2025`
   - Select Certificate: Apple Development: Joseph Dormond
   - Select Devices: Your test devices
   - Name it: **"Branchr Dev Profile 2025 (MusicKit)"**

2. **Download Profile**
   - Click **Download**

---

### Step 3: Install Updated Profile

1. **Double-click** the downloaded `.mobileprovision` file
2. macOS will install it automatically
3. It should appear in:
   ```
   ~/Library/MobileDevice/Provisioning Profiles/
   ```

---

### Step 4: Update Xcode Project (Already Done ✅)

The project has been updated to use "PRO DEV ID" instead of "JJJJJJ".

**To verify in Xcode:**
1. Open Xcode
2. Select project → Target: **branchr**
3. Go to **Signing & Capabilities** tab
4. Under **Provisioning Profile**, you should see:
   - "PRO DEV ID" or "Automatic"
   - If you see the profile, select it manually

**Alternative: Let Xcode Auto-Manage** (Recommended for Development)

1. In **Signing & Capabilities**
2. Check ✅ **"Automatically manage signing"**
3. Xcode will automatically find and use the correct profile

---

### Step 5: Clean and Rebuild

```bash
# In Xcode:
# Shift + Cmd + K (Clean Build Folder)
# Then Cmd + B (Build)
```

Or via command line:
```bash
xcodebuild clean -project branchr.xcodeproj -scheme branchr
xcodebuild -project branchr.xcodeproj -scheme branchr build
```

---

## 🔍 Verify Profile Has MusicKit

After downloading, verify the profile includes MusicKit:

```bash
# Check if profile includes MusicKit entitlements
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision \
  | grep -i "music-user-token"
```

You should see:
```xml
<key>com.apple.developer.music-user-token</key>
<true/>
```

---

## ⏱️ Timing Checklist

- [ ] Enable MusicKit on App ID in Developer Portal
- [ ] **WAIT 30-45 minutes** for Apple backend sync ⏰
- [ ] Edit or recreate provisioning profile
- [ ] Download new profile
- [ ] Double-click to install
- [ ] Update Xcode project settings (✅ Done)
- [ ] Clean build folder
- [ ] Rebuild project

---

## 🐛 If Still Failing

### Error: "Profile still missing MusicKit"

1. **Verify App ID has MusicKit enabled**
   - Double-check in Developer Portal
   - Ensure you clicked **Save**

2. **Wait Longer**
   - Apple sync can take up to 60 minutes
   - Try again after 1 hour

3. **Create Fresh Profile**
   - Delete old profile
   - Create completely new one with fresh name
   - Download and install

4. **Check Profile Contents**
   ```bash
   security cms -D -i ~/path/to/profile.mobileprovision | grep -i music
   ```
   Should show MusicKit entitlements

---

## ✅ Success Indicators

When everything is correct, you should see:
- ✅ Build succeeds without entitlement errors
- ✅ Profile appears in Xcode → Signing & Capabilities
- ✅ Profile includes MusicKit in its entitlements
- ✅ App launches on device

---

**Current Status:**
- ✅ Xcode project updated to use "PRO DEV ID"
- ⚠️ Need to verify/update profile in Developer Portal has MusicKit
- ⚠️ Need to download and install updated profile

