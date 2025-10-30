# 🎧 Apple Music Xcode Setup Guide

## ⚠️ IMPORTANT: Required Xcode Configuration

Before the Apple Music features will work, you **MUST** add the Apple Music capability in Xcode.

---

## 🔧 Step-by-Step Setup

### 1. Open Your Project in Xcode
```bash
cd /Users/joedormond/Documents/branchr
open branchr.xcodeproj
```

---

### 2. Select Your Project Target

1. Click **branchr** in the Project Navigator (left sidebar)
2. Select the **branchr** target (not the project)
3. Click the **Signing & Capabilities** tab

---

### 3. Add Apple Music Capability

1. Click the **+ Capability** button (top left)
2. Scroll down and find **Apple Music**
3. Click to add it to your project

**Result:** You'll see a new "Apple Music" section appear

---

### 4. (Optional) Verify Background Modes

Ensure these are checked under **Background Modes**:
- ✅ Audio, AirPlay, and Picture in Picture
- ✅ Bluetooth Central
- ✅ Bluetooth Peripheral
- ✅ Remote notifications
- ✅ Background fetch

*Note: Most of these should already be configured from previous phases*

---

### 5. Build and Run

**Clean Build:**
```bash
# In Terminal
cd /Users/joedormond/Documents/branchr
xcodebuild -project branchr.xcodeproj -scheme branchr clean
```

**Fresh Build:**
```bash
xcodebuild -project branchr.xcodeproj -scheme branchr -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

**Or in Xcode:**
- Press **⇧⌘K** (Shift+Cmd+K) to clean
- Press **⌘R** (Cmd+R) to build and run

---

## 📱 Testing Apple Music Integration

### On Real Device (Recommended):
Apple Music works best on a **real iPhone** with:
- ✅ Active Apple Music subscription
- ✅ Signed in to Apple ID
- ✅ Music library synced

### On Simulator (Limited):
- ⚠️ Apple Music may not work fully
- ✅ Authorization flow will still appear
- ✅ UI will display correctly
- ⚠️ Playback may not work

---

## 🧪 Testing Steps

### 1. Launch App
```bash
# Run in simulator or device
# Press Cmd+R in Xcode
```

### 2. Open DJ Controls
- Tap DJ Controls button (🎛️) on HomeView
- DJ Control Sheet opens

### 3. Authorize Apple Music
- Tap "Connect Apple Music" button
- iOS authorization dialog appears
- Tap "Allow" to grant permission

### 4. Test Playback
- After authorization, you'll see playback controls
- Tap the large Play button (▶️)
- *Note: Requires actual Apple Music subscription on real device*

---

## 🔍 Troubleshooting

### Issue: "Apple Music capability not found"
**Solution:**
1. Make sure you added the capability in Xcode
2. Clean build folder (⇧⌘K)
3. Rebuild project (⌘B)

### Issue: "Authorization fails immediately"
**Possible Causes:**
- No Apple Music subscription
- Not signed in to Apple ID
- Running on simulator (limited support)

**Solution:**
- Test on real iPhone
- Verify Apple Music subscription active
- Check Settings → Music → Apple Music is enabled

### Issue: "Playback doesn't work"
**Possible Causes:**
- Testing on simulator
- No Apple Music subscription
- Not authorized

**Solution:**
- Must test on real device
- Must have active Apple Music subscription
- Must grant authorization when prompted

### Issue: Build fails with entitlement errors
**Solution:**
1. Go to Signing & Capabilities
2. Make sure your Team is selected
3. Make sure Bundle ID is correct
4. Try automatic signing

---

## 📝 Capability Checklist

After adding capabilities, verify these are present:

**In Xcode → Signing & Capabilities:**
- ✅ Apple Music
- ✅ Background Modes (with Audio checked)
- ✅ iCloud (from Phase 13)
- ✅ App Groups (from Phase 12)

**In branchr.entitlements:**
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.joedormond.branchr</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

**In Info.plist (already configured):**
```xml
<key>NSAppleMusicUsageDescription</key>
<string>Branchr uses Apple Music to play and sync music during group rides.</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    ...
</array>
```

---

## 🎯 What to Expect After Setup

### ✅ Authorization Flow:
1. DJ Controls button opens sheet
2. "Connect Apple Music" card displays
3. Tap button shows iOS system dialog
4. Grant permission
5. UI updates to show playback controls

### ✅ Playback Controls:
- Large Play/Pause button (center)
- Previous/Next buttons (sides)
- Stop button (full width)
- Album artwork (if available)
- Song title and artist

### ✅ Now Playing Info:
- Updates in real-time
- Shows current song
- Displays artist name
- Loads album artwork
- Green "Playing" indicator

---

## 🚀 Quick Test

```bash
# 1. Add Apple Music capability in Xcode
# 2. Clean and build
xcodebuild -project branchr.xcodeproj -scheme branchr clean
xcodebuild -project branchr.xcodeproj -scheme branchr build

# 3. Run on device (not simulator for full testing)
# 4. Tap DJ Controls
# 5. Tap Connect Apple Music
# 6. Grant permission
# 7. Test playback controls
```

---

## 💡 Tips

### For Development:
- Use a real device for testing
- Have an Apple Music subscription
- Keep authorization granted
- Test with good internet connection

### For Users:
- Apple Music subscription required
- First-time setup needs authorization
- Works offline with downloaded songs
- Integrates with existing Music app

---

## 📚 Additional Resources

**Apple Documentation:**
- [MusicKit Overview](https://developer.apple.com/musickit/)
- [Apple Music API](https://developer.apple.com/documentation/musickit)
- [App Capabilities](https://developer.apple.com/documentation/xcode/capabilities)

**Branchr Documentation:**
- `PHASE_18_4_COMPLETE.md` - Full implementation details
- `DJ_SYSTEM_USAGE_GUIDE.md` - User guide
- `SIMULATOR_LAUNCH_GUIDE.md` - General testing

---

## ✅ Completion Checklist

**Before Testing:**
- [ ] Added Apple Music capability in Xcode
- [ ] Verified Background Modes includes Audio
- [ ] Clean build completed
- [ ] Fresh build succeeded
- [ ] Running on real device (recommended)

**During Testing:**
- [ ] DJ Controls button works
- [ ] Connect Apple Music appears
- [ ] Authorization dialog shows
- [ ] Permission granted successfully
- [ ] Playback controls visible

**Features Working:**
- [ ] Play button starts music
- [ ] Pause button stops playback
- [ ] Skip buttons change tracks
- [ ] Stop button resets
- [ ] Album art displays
- [ ] Song info updates

---

## 🎉 You're Ready!

Once you've added the Apple Music capability in Xcode and rebuilt, all Phase 18.4 features will work!

**Your Branchr DJ system will support:**
- ✅ Full Apple Music streaming
- ✅ Professional playback controls
- ✅ Real-time now playing info
- ✅ Album artwork display
- ✅ Voice + music mixing

**Happy streaming!** 🎧🚀

