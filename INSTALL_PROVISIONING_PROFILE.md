# 📱 Installing Branchr Provisioning Profile

## 🎯 Quick Method (Recommended)

### Option 1: Double-Click Installation ✅ **EASIEST**

1. **Download** the `.mobileprovision` file from Apple Developer Portal
2. **Double-click** the file
3. macOS will automatically:
   - Install it to the correct location
   - Register it with Xcode
   - Make it available for code signing

**Done!** ✅

---

### Option 2: Drag into Xcode

1. **Open Xcode**
2. **Download** the `.mobileprovision` file
3. **Drag and drop** it into the Xcode window
4. Xcode will install it automatically

---

## 📂 Manual Installation (If Needed)

If double-click doesn't work, you can manually copy:

### Destination Folder:
```
~/Library/MobileDevice/Provisioning Profiles/
```

### Steps:
1. Open Finder
2. Press `Cmd + Shift + G` (Go to Folder)
3. Paste this path:
   ```
   ~/Library/MobileDevice/Provisioning Profiles
   ```
4. Copy your `.mobileprovision` file into this folder
5. **Important:** Rename the file to match its UUID (Xcode does this automatically if you double-click)

---

## 🔍 Verify Installation

After installing, verify it's there:

```bash
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/
```

You should see a file named something like:
```
XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.mobileprovision
```

Or check in Xcode:
1. Xcode → **Settings** (or Preferences)
2. Click **Accounts** tab
3. Select your Apple ID
4. Click **Manage Certificates...** or **Download Manual Profiles**

---

## ✅ What Should Happen

Once installed, Xcode will:
- Automatically detect the profile
- Show it in the Signing & Capabilities dropdown
- Use it for code signing when building for devices

---

## 🐛 Troubleshooting

### Profile Not Showing in Xcode?

1. **Restart Xcode** after installing
2. **Clean Build Folder**: `Shift + Cmd + K`
3. **Check Profile Name**: In Xcode → Target → Signing & Capabilities, the profile name should appear in the dropdown

### Still Not Working?

1. **Verify Profile Matches App ID**:
   - Profile must be for `com.joedormond.branchr2025`
   - Must include MusicKit entitlements

2. **Check Profile Expiration**:
   - Profiles expire after 1 year
   - Download a fresh one if expired

3. **Regenerate Profile** (if needed):
   - Apple Developer Portal → Profiles
   - Edit or recreate the profile
   - Wait 15-30 minutes for Apple backend sync
   - Download again

---

**Quick Tip:** Double-clicking the `.mobileprovision` file is always the easiest and most reliable method! 🎯

