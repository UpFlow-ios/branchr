# 🎧 Apple Music Testing Guide - Branchr DJ Mode

## 🎯 Quick Test Checklist

**✅ = Working | ⚠️ = Needs Real Device | ❌ = Issue**

---

## 📱 Device Requirements

### **Simulator:**
- ✅ Authorization dialog
- ✅ UI updates
- ✅ Console logs
- ⚠️ **Music won't actually play**

### **Real iPhone:**
- ✅ Authorization dialog
- ✅ UI updates
- ✅ Console logs
- ✅ **Music WILL play** (requires Apple Music subscription)

---

## 🧪 Step-by-Step Test

### **1. Clean Build**
```bash
cd /Users/joedormond/Documents/branchr
xcodebuild -project branchr.xcodeproj -scheme branchr clean
```

### **2. Fresh Build**
```bash
xcodebuild -project branchr.xcodeproj -scheme branchr build
```

### **3. Run App**
- In Xcode: Press **⌘R**
- Or: Select device and tap Run

---

## 🎵 Test Flow

### **Step 1: Launch App**
```
✅ App opens
✅ HomeView displays
✅ DJ Controls button visible (🎛️)
```

### **Step 2: Open DJ Controls**
```
Tap DJ Controls button
↓
✅ Sheet opens
✅ "Connect Apple Music" card shows
```

### **Step 3: Authorize Apple Music**
```
Tap "Connect Apple Music" button
↓
✅ iOS dialog appears:
   "branchr Would Like to Access Apple Music"
   
   "Branchr needs access to your Apple Music
    library to play and sync music during group rides."
↓
Tap "OK"
↓
✅ Dialog dismisses
✅ UI updates to show playback controls
```

### **Step 4: Test Playback**
```
Tap large Play button (▶️)
↓
📍 Check Console:
   "🔍 Searching for Calvin Harris..."
   "🎵 Found song: Summer by Calvin Harris"
   "🎶 Now playing: Summer by Calvin Harris"
↓
✅ UI Updates:
   - Song title: "Summer" (or similar)
   - Artist: "Calvin Harris"
   - Album artwork loads
   - Green "Playing" indicator appears
↓
🎵 Music plays (on real device)
⚠️ Music won't play (on simulator - but UI updates)
```

### **Step 5: Test Controls**

**Pause Button:**
```
Tap Pause (⏸️)
↓
✅ Music pauses
✅ Button changes to Play icon
✅ Console: "⏸ MusicService: Playback paused"
```

**Resume:**
```
Tap Play (▶️) again
↓
✅ Music resumes from where it paused
✅ Button changes to Pause icon
✅ Console: "▶️ MusicService: Playback resumed"
```

**Stop:**
```
Tap Stop button (red, full width)
↓
✅ Music stops completely
✅ Song info resets to "No song playing"
✅ Console: "⏹ MusicService: Playback stopped"
```

**Play Again (After Stop):**
```
Tap Play (▶️) after stopping
↓
✅ Searches for song again
✅ Loads new song
✅ Starts playing from beginning
```

---

## 📊 Expected Console Output

### **Full Test Console Log:**

```
🎵 MusicService: Initialized
DJ Controls tapped - opening sheet
🎵 MusicService: Current authorization status: authorized
✅ MusicService: Apple Music access granted
🔍 Searching for Calvin Harris...
🎵 Found song: Summer by Calvin Harris
🎶 Now playing: Summer by Calvin Harris
🖼️ Artwork URL: https://is1-ssl.mzstatic.com/image/...
⏸ MusicService: Playback paused
▶️ MusicService: Playback resumed
⏹ MusicService: Playback stopped
```

---

## ⚠️ Troubleshooting

### **Issue: Authorization Dialog Doesn't Appear**

**Check:**
1. Info.plist has `NSAppleMusicUsageDescription`
2. Clean build and rebuild
3. Delete app from device and reinstall

**Fix:**
```bash
# Clean
xcodebuild -project branchr.xcodeproj -scheme branchr clean
# Rebuild
xcodebuild -project branchr.xcodeproj -scheme branchr build
```

---

### **Issue: "Not Authorized" Message in Console**

**Symptoms:**
```
⚠️ Not authorized. Please connect Apple Music first.
```

**Fix:**
1. Open DJ Controls
2. Tap "Connect Apple Music" again
3. Make sure to tap "OK" in iOS dialog
4. Try Play button again

---

### **Issue: "No Songs Found in Search"**

**Symptoms:**
```
⚠️ No songs found in search.
```

**Possible Causes:**
- No internet connection
- Apple Music servers unavailable
- Region restrictions

**Fix:**
1. Check internet connection
2. Open Apple Music app
3. Search for Calvin Harris manually
4. Return to Branchr and try again

---

### **Issue: Music Doesn't Play on Simulator**

**This is Normal!**
- ⚠️ Simulator doesn't support actual music playback
- ✅ UI will still update correctly
- ✅ Console logs will show successful search
- ✅ Authorization still works

**Solution:**
- Test on real iPhone for actual playback

---

### **Issue: "Playback Error" in Console**

**Symptoms:**
```
❌ Playback error: [error description]
```

**Common Causes:**
1. No Apple Music subscription
2. Not signed in to Apple ID
3. Network issue
4. Song not available in region

**Fix:**
1. Open Apple Music app
2. Play any song once to initialize
3. Sign in to Apple ID
4. Verify Apple Music subscription active
5. Return to Branchr and try again

---

## ✅ Success Criteria

### **All Green Checkmarks:**

**Authorization:**
- [x] Dialog appears
- [x] Permission can be granted
- [x] UI updates after grant

**Playback:**
- [x] Search finds song
- [x] Song info displays
- [x] Album artwork loads
- [x] Music plays (real device)

**Controls:**
- [x] Play button starts music
- [x] Pause button stops music
- [x] Resume works after pause
- [x] Stop resets everything

**UI:**
- [x] Song title updates
- [x] Artist name shows
- [x] Artwork displays
- [x] Green indicator when playing

---

## 📝 Test Matrix

| Action | Simulator | Real Device |
|--------|-----------|-------------|
| Authorization | ✅ Works | ✅ Works |
| UI Update | ✅ Works | ✅ Works |
| Song Search | ✅ Works | ✅ Works |
| Metadata Display | ✅ Works | ✅ Works |
| Album Artwork | ✅ Loads | ✅ Loads |
| **Actual Playback** | ⚠️ **No Sound** | ✅ **Plays** |
| Pause/Resume | ⚠️ UI Only | ✅ Works |
| Stop | ✅ Works | ✅ Works |

---

## 🎯 Quick Test Commands

### **One-Liner Test:**
```bash
cd /Users/joedormond/Documents/branchr && \
xcodebuild -project branchr.xcodeproj -scheme branchr clean && \
xcodebuild -project branchr.xcodeproj -scheme branchr build
```

### **Check for Errors:**
```bash
xcodebuild -project branchr.xcodeproj -scheme branchr build 2>&1 | grep "error:"
```

### **Check for Warnings:**
```bash
xcodebuild -project branchr.xcodeproj -scheme branchr build 2>&1 | grep "warning:" | wc -l
```

---

## 🎉 Final Checklist

**Before Marking Complete:**

- [ ] Built successfully (no errors)
- [ ] Ran on simulator
- [ ] Authorization works
- [ ] UI updates correctly
- [ ] Console logs show search
- [ ] Song info displays
- [ ] Album art loads
- [ ] (Optional) Tested on real device with actual playback

**If All Checked:**
✅ **Apple Music Integration Complete!**

---

## 📚 Related Documentation

- `PHASE_18_4B_COMPLETE.md` - Full implementation details
- `INFOPLIST_FIX_COMPLETE.md` - Info.plist setup
- `APPLE_MUSIC_CRASH_FIX.md` - Crash resolution
- `APPLE_MUSIC_CAPABILITY_FIX.md` - Capability setup

---

## 🚀 You're Ready!

**Test flow:**
1. Clean build ✅
2. Run app ✅
3. Open DJ Controls ✅
4. Connect Apple Music ✅
5. Tap Play ✅
6. Enjoy music! 🎶

**Happy testing!** 🎧🚀

