# 🎧 Branchr DJ System - Usage Guide

## 🎯 Quick Start

### HomeView Audio Controls

Your HomeView now has **3 interactive audio buttons**:

```
[Unmuted] [Music On] [DJ Controls]
```

---

## 🎛️ Button Functions

### 1. Voice Button (Left)
**Icon:** 🎤 `mic.fill` / `mic.slash.fill`
**States:** Unmuted ↔ Muted

**What it does:**
- Toggles voice mute state
- Triggers automatic music fade when active
- Logs to console: "Voice muted" / "Voice unmuted"

**Use case:** Quickly mute/unmute your microphone during group rides

---

### 2. Music Button (Middle)
**Icon:** 🎵 `music.note` / `speaker.slash.fill`
**States:** Music On ↔ Music Off

**What it does:**
- Stops music playback when toggled off
- Updates icon and title to reflect state
- Logs to console: "Music muted" / "Music unmuted"

**Use case:** Quick mute for music without opening DJ controls

---

### 3. DJ Controls Button (Right)
**Icon:** 🎛️ `music.quarternote.3`
**Action:** Opens DJ Control Sheet

**What it does:**
- Opens full DJ control modal
- Access to playback, volume, and group controls
- Real-time status updates

**Use case:** Full DJ mode for managing group music and audio

---

## 🎛️ DJ Control Sheet

### Opening the Sheet:
Tap the **DJ Controls** button on HomeView

### Features:

#### 1. DJ Mode Toggle
- Enable/disable DJ controls
- Theme: Yellow accent switch

#### 2. Now Playing Section
- Shows current song name
- Green indicator when playing
- Updates in real-time

#### 3. Playback Controls
**Play Music Button (Yellow):**
- Starts music playback
- Currently plays: `ride_track.mp3`
- Updates "Now Playing" status

**Stop Button (Red):**
- Stops music immediately
- Resets status to "No song playing"

#### 4. Voice Simulation Button (Orange)
- Tests auto-fade behavior
- Simulates voice chat activity
- Music fades to 30% for 2 seconds

#### 5. Mute All Voices (Gray)
- Placeholder for group controls
- Future: Mutes all group members
- Console logs action

---

## 🔊 Auto-Fade Behavior

### How it Works:

**When Voice is Active:**
1. Music volume fades to **30%** over 0.5 seconds
2. Allows clear voice communication
3. Console: "🔉 Music faded to 30% for voice"

**When Voice Stops:**
1. Music volume restores to **100%** over 0.5 seconds
2. Full music quality returns
3. Console: "🔊 Music restored to 100%"

**Trigger Points:**
- Manual: Tap Voice button
- Automatic: "Hey Branchr" wake word detection
- Test: "Simulate Voice Chat" in DJ sheet

---

## 📝 Console Logs

### Voice Actions:
```
Voice muted
Voice unmuted
🎙 AudioManager: Voice chat active
🎙 AudioManager: Voice chat inactive
```

### Music Actions:
```
Music muted
Music unmuted
🎵 AudioManager: Playing ride_track
⏹ AudioManager: Music stopped
```

### Fade Actions:
```
🔉 AudioManager: Music faded to 30% for voice
🔊 AudioManager: Music restored to 100%
```

---

## 🎵 Adding Music Files

### To test playback:

1. **Add MP3 to Project:**
   - Right-click in Xcode Project Navigator
   - Select "Add Files to branchr"
   - Choose your MP3 file(s)
   - Ensure "Copy items if needed" is checked
   - Click "Add"

2. **Name Convention:**
   - Default: `ride_track.mp3`
   - Additional: `ride_track2.mp3`, etc.

3. **Update DJ Sheet:**
   - Change `playMusic(named: "ride_track")` to your filename
   - Omit the `.mp3` extension in the code

---

## 🚀 Advanced Usage

### Multiple Songs:
Add more buttons in `DJControlSheetView.swift`:
```swift
Button(action: {
    audioManager.playMusic(named: "ride_track2")
}) {
    Label("Play Track 2", systemImage: "play.circle.fill")
    // ... styling
}
```

### Volume Control:
Future feature - slider for manual volume adjustment

### Group Sync:
Future feature - synchronized playback across all riders

---

## 🎯 Best Practices

### For Developers:
1. **Always test audio on real device** (not simulator)
2. **Check console logs** for audio state changes
3. **Add proper error handling** for missing MP3 files
4. **Test with Bluetooth headphones** for real-world scenarios

### For Users:
1. **Start with DJ Controls** to play music
2. **Use Voice button** for quick mute during conversations
3. **Monitor Now Playing** for current status
4. **Stop music before switching tracks** (future: auto-stop)

---

## ⚠️ Known Limitations

### Current Phase (18.3):
- ✅ Local MP3 playback only
- ✅ Single track at a time
- ✅ No playlist support yet
- ✅ No Apple Music integration yet

### Coming in Phase 18.4:
- 🔜 Apple Music API integration
- 🔜 User playlist access
- 🔜 Album artwork display
- 🔜 Multi-track queue system

---

## 🎉 Summary

Your Branchr DJ system now has:
- ✅ **3 interactive audio buttons** on HomeView
- ✅ **Full DJ Control Sheet** with playback controls
- ✅ **Auto-fade logic** for voice/music balance
- ✅ **Real-time status updates** for now playing
- ✅ **Professional audio session** management
- ✅ **Theme-consistent UI** with yellow accents

**Ready to ride with music!** 🚴‍♂️🎵

