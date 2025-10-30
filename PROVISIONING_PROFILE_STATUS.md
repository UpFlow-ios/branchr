# 🔍 Provisioning Profile Verification

**Date:** October 28, 2025  
**Location:** `~/Library/MobileDevice/Provisioning Profiles/`

---

## ❌ Status: Provisioning profile not yet installed locally.

### **What This Means:**

The provisioning profile has not been downloaded to this Mac yet.

### **Why This Happens:**

Provisioning profiles are only installed when:
1. You build for a physical device in Xcode
2. You manually download from Apple Developer Portal
3. You use "Download Manual Profiles" in Xcode Settings

### **Current Situation:**

- ✅ Profile exists on Apple's servers (you created it)
- ❌ Profile not downloaded to this Mac
- ✅ Simulator builds work (don't need profile)
- ⚠️ Device builds need the profile

---

## 🎯 How to Install the Profile

### **Option 1: Let Xcode Download It (Automatic)**

1. **In Xcode:**
   - Go to **Settings** (Cmd + ,)
   - Click **Accounts** tab
   - Select your Apple ID
   - Click **Download Manual Profiles**
   - Wait 10-30 seconds

2. **Profile should install automatically**

### **Option 2: Manual Download from Portal**

1. **Go to:** https://developer.apple.com/account/resources/profiles/list
2. **Find:** "kkkk" or "Branchr Dev Profile (MusicKit)"
3. **Click:** Download button
4. **Double-click** the `.mobileprovision` file
5. **Xcode will install it**

### **Option 3: Build for Device (Triggers Download)**

1. **Connect your iPhone**
2. **Select it as the build target**
3. **Press Cmd + R**
4. **Xcode will try to download the profile**

---

## 🧪 How to Verify After Installing

Run this command:

```bash
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | grep -E "application-identifier|com.apple.developer.music"
```

You should see:
```
<key>application-identifier</key>
<string>69Y49KN8KD.com.joedormond.branchr</string>
<key>com.apple.developer.music-user-token</key>
<true/>
<key>com.apple.developer.music.subscription-service</key>
<true/>
```

---

## ✅ What's Already Working

Even without the device profile:

1. **✅ Entitlements configured correctly**
   - `branchr.entitlements` has all MusicKit keys

2. **✅ Simulator builds work**
   - Can test MusicKit on simulator
   - BUILD SUCCEEDED

3. **✅ Code signing configured**
   - Team ID: `69Y49KN8KD`
   - Bundle ID: `com.joedormond.branchr`

---

## 🎯 Next Step

**Choose one:**

1. **Download profile from Apple Developer Portal** → Double-click to install
2. **In Xcode:** Settings → Accounts → Download Manual Profiles
3. **Connect iPhone and build** → Xcode will download automatically

Then run this verification again! 🎶📱

