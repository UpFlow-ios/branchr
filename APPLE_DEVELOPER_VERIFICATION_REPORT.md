# 🔍 Apple Developer Configuration Verification Report

**Generated:** $(date)  
**Project:** Branchr  
**Bundle ID:** com.joedormond.branchr2025  
**Team ID:** 69Y49KN8KD

---

## ✅ Verification Results

### 1. App ID Configuration
**Status:** ⚠️ Cannot verify automatically (requires Apple Developer Portal access)

**Expected Entitlements:**
- `com.apple.developer.music-user-token` ✅
- `com.apple.developer.music.subscription-service` ✅
- `com.apple.security.application-groups` → `group.com.joedormond.branchr2025` ✅
- `com.apple.developer.applesignin` ✅
- `com.apple.developer.icloud-services` (CloudKit) ✅

**Manual Verification Required:**
1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles** → **Identifiers**
3. Select App ID: `com.joedormond.branchr2025`
4. Verify all above entitlements are enabled

---

### 2. Entitlements File (`branchr/branchr.entitlements`)

**Status:** ✅ **CORRECT**

**Verified Entitlements:**
```xml
✅ com.apple.developer.music-user-token = true
✅ com.apple.developer.music.subscription-service = true
✅ com.apple.security.application-groups = ["group.com.joedormond.branchr2025"]
✅ com.apple.developer.applesignin = ["Default"]
✅ com.apple.developer.icloud-services = ["CloudKit"]
✅ com.apple.developer.team-identifier = "69Y49KN8KD"
✅ aps-environment = "development"
```

**Location:** `branchr/branchr.entitlements`

---

### 3. Developer Certificate

**Status:** ✅ **VERIFIED AND VALID**

**Certificate Details:**
- **Name:** Apple Development: Joseph Dormond (8SKVRG3B6Q)
- **Team ID:** 69Y49KN8KD
- **Serial:** 3N4658FXUL
- **Valid From:** October 29, 2025
- **Valid Until:** October 29, 2026
- **Status:** ✅ Not expired
- **Location:** Keychain Access → Login → Certificates

---

### 4. MusicKit Private Key

**Status:** ✅ **FOUND**

**Key Details:**
- **File:** `Resources/AuthKey_S8S2CSHCZ7.p8`
- **Expected Key ID:** S8S2CSHCZ7
- **Location:** ✅ Exists in project
- **Size:** 257 bytes
- **Last Modified:** October 29, 2025

**⚠️ Security Note:** This file should NOT be committed to Git. Verify `.gitignore` includes `*.p8`

---

### 5. Provisioning Profile

**Status:** ❌ **NOT FOUND - ACTION REQUIRED**

**Issue:** No provisioning profiles detected in:
```
~/Library/MobileDevice/Provisioning Profiles/
```

**Expected Profile:**
- **Name:** Branchr Dev Profile 2025 (Final Verified)
- **Type:** iOS App Development
- **App ID:** com.joedormond.branchr2025
- **Certificate:** Apple Development: Joseph Dormond (8SKVRG3B6Q)
- **Must Include Entitlements:**
  - MusicKit (user-token + subscription-service)
  - App Groups (group.com.joedormond.branchr2025)
  - Sign in with Apple
  - iCloud / CloudKit
  - Push Notifications (development)

**Required Actions:**
1. Go to Apple Developer Portal → **Certificates, Identifiers & Profiles** → **Profiles**
2. Find or recreate profile: "Branchr Dev Profile 2025 (Final Verified)"
3. Ensure it includes:
   - ✅ Correct App ID (`com.joedormond.branchr2025`)
   - ✅ Development certificate (8SKVRG3B6Q)
   - ✅ Your test device UDID
   - ✅ All required entitlements (MusicKit, App Groups, etc.)
4. Download the `.mobileprovision` file
5. Double-click to install (or drag to Xcode)
6. Wait 15-30 minutes for Apple backend sync if profile was just updated

---

### 6. Xcode Project Configuration

**Status:** ⚠️ **NEEDS ATTENTION**

**Bundle ID:** ✅ `com.joedormond.branchr2025` (correct)

**Provisioning Profile Specifier:**
- **iOS Device:** "PRO DEV ID" (needs update to match actual profile name)
- **macOS:** "Branchr Dev Profile 2025 (Final Verified) 1"

**Recommended Fix:**
Update `PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]` in Xcode project settings to match the exact profile name after downloading it.

**Code Signing Entitlements:**
- Main App: References multiple entitlements files
  - Debug: `branchr/branchrDebug.entitlements`
  - Release: Should reference `branchr/branchr.entitlements`
- Widget Extension: `BranchrWidgetExtensionExtension.entitlements`

**Recommendation:** Verify in Xcode → Target → Signing & Capabilities that the correct entitlements file is selected for each configuration.

---

## 📊 Summary Status

| Component | Status | Notes |
|-----------|--------|-------|
| **App ID** | ⚠️ Manual Check | Verify in Developer Portal |
| **Entitlements File** | ✅ Correct | All MusicKit & App Groups present |
| **Certificate** | ✅ Valid | Not expired, in Keychain |
| **MusicKit Key** | ✅ Found | `AuthKey_S8S2CSHCZ7.p8` exists |
| **Provisioning Profile** | ❌ Missing | **Must download & install** |

---

## 🎯 Final Verdict

### ❌ **NOT READY FOR DEVICE BUILD YET**

**Primary Issue:** Provisioning profile is missing or not installed locally.

**Required Actions Before Building:**

1. **Download Provisioning Profile**
   - Go to [developer.apple.com](https://developer.apple.com)
   - Navigate to **Profiles** → Find "Branchr Dev Profile 2025 (Final Verified)"
   - If it doesn't exist or entitlements are missing:
     - Edit App ID → Enable MusicKit + App Groups
     - Recreate the profile
     - Wait 15-45 minutes for Apple backend sync
   - Download the `.mobileprovision` file
   - Double-click to install

2. **Verify Profile Installation**
   ```bash
   ls -la ~/Library/MobileDevice/Provisioning\ Profiles/
   ```
   Should show at least one `.mobileprovision` file containing "Branchr"

3. **Update Xcode Project**
   - Open Xcode → Project Settings → Signing & Capabilities
   - Select the downloaded profile from dropdown
   - Or update `PROVISIONING_PROFILE_SPECIFIER` in project.pbxproj

4. **Clean Build**
   ```bash
   # In Xcode: Product → Clean Build Folder (Shift + Cmd + K)
   # Or command line:
   xcodebuild clean -project branchr.xcodeproj -scheme branchr
   ```

5. **Build & Test**
   ```bash
   xcodebuild -project branchr.xcodeproj \
     -scheme branchr \
     -destination 'platform=iOS,name=Your Device Name' \
     build
   ```

---

## 🔄 Next Steps

1. ✅ **Download and install provisioning profile** (Critical)
2. ✅ **Verify profile includes MusicKit entitlements**
3. ✅ **Update Xcode project to reference correct profile**
4. ✅ **Clean build folder**
5. ✅ **Attempt device build**
6. ✅ **If build fails with entitlement errors:**
   - Wait 30-60 minutes for Apple backend sync
   - Re-download profile
   - Try again

---

## 📝 Notes

- **Apple Backend Sync Delay:** After enabling entitlements or recreating profiles, Apple's servers can take 15-45 minutes to propagate changes. If you see entitlement mismatch errors immediately after updating the App ID, wait and retry.

- **Automatic vs Manual Profiles:** Xcode can automatically manage profiles, but for complex entitlements like MusicKit, manual profiles are often more reliable.

- **Certificate Expiration:** Current certificate expires October 29, 2026. Set a reminder to renew before expiration.

---

**Generated:** $(date)  
**Verification Tool:** Apple Developer Configuration Checker

