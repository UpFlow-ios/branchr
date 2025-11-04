# 🔧 Fix: Provisioning Profile Missing MusicKit Entitlements

## ❌ The Error

Xcode shows:
> "Provisioning profile "(Final Dev Branchr Profile)" doesn't include the `com.apple.developer.music-user-token` and `com.apple.developer.music.subscription-service` entitlements."

## ✅ What This Means

- ✅ Your entitlements file (`branchr.entitlements`) HAS the MusicKit entitlements
- ❌ Your provisioning profile on Apple's servers does NOT have them

## 🎯 Why This Happens

The profile was created **BEFORE** MusicKit was enabled on your App ID. Provisioning profiles are snapshots—they don't automatically update when you change App ID capabilities.

## 🚀 The Fix (3 Steps)

### Step 1: Enable MusicKit on App ID (15 minutes)

1. **Go to:** https://developer.apple.com/account/resources/identifiers/list/bundleId
2. **Find:** `com.joedormond.branchr2025`
3. **Click on it** to edit
4. **Scroll to Capabilities**
5. **Check these boxes:**
   - ☑️ **MusicKit**
   - ☑️ **App Groups** (add `group.com.joedormond.branchr2025`)
   - ☑️ **Sign in with Apple**
   - ☑️ **Push Notifications**
   - ☑️ **iCloud** (with CloudKit)
6. **Click "Save"**
7. **Wait 10-15 minutes** for Apple to sync

### Step 2: Regenerate Provisioning Profile (5 minutes)

1. **Go to:** https://developer.apple.com/account/resources/profiles/list
2. **Find:** "(Final Dev Branchr Profile)"
3. **Click "Remove"** (delete the old one)
4. **Click "+"** to create new profile
5. **Select:** "iOS App Development"
6. **App ID:** `com.joedormond.branchr2025`
7. **Certificates:** Select "Apple Development: Joseph Dormond (8SKVRG3B6Q)"
8. **Devices:** Select your iPhone
9. **Profile Name:** "Final Dev Branchr Profile"
10. **Click "Generate"**
11. **Click "Download"** and double-click to install

### Step 3: Refresh in Xcode (1 minute)

**Option A: Manual Download**
1. Xcode → **Settings** (Cmd + ,)
2. **Accounts** tab
3. Select your Apple ID
4. Click **"Download Manual Profiles"**
5. Wait 30 seconds

**Option B: Auto Download**
1. Connect your iPhone
2. Select your device in Xcode
3. Press **Cmd + R** to build
4. Xcode will download the new profile automatically

---

## ✅ After Fixing

You should see:
- ✅ No red error in Signing & Capabilities
- ✅ "Signing Certificate: Apple Development: Joseph Dormond (8SKVRG3B6Q)"
- ✅ Profile includes MusicKit entitlements
- ✅ Device build succeeds!

---

## 🎯 Quick Checklist

- [ ] Enable MusicKit on App ID `com.joedormond.branchr2025`
- [ ] Wait 10-15 minutes for sync
- [ ] Delete old "(Final Dev Branchr Profile)"
- [ ] Create new profile with same name
- [ ] Download and install profile
- [ ] Refresh in Xcode
- [ ] Build for device (Cmd + R)
- [ ] ✅ SUCCESS!

---

## 📝 Summary

**Your entitlements file is correct!**  
**The provisioning profile just needs to be regenerated** with MusicKit enabled.

Once you complete these steps, Xcode will stop showing that error! 🎵

