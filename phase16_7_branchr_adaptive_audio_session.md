# 🎧 Phase 16.7 – Adaptive Audio Session (Dynamic Mix & Ducking)

**Goal:**  
Let riders enjoy **full-quality music** while riding, and have Branchr automatically:
- detect voice activity,  
- switch the audio route for two-way talk,  
- duck (soft-fade) music when speaking starts, and  
- restore HD stereo when speech stops.

This mirrors FaceTime and AirPods "auto-duck" behavior.

---

## 1️⃣ Folder & File

~/Documents/branchr/
└── Services/
└── AudioManager.swift

---

## 2️⃣ File: AudioManager.swift

Adaptive audio session management with automatic music ducking and voice mode switching.

---

## 3️⃣ Voice-Detection Hook

Integration with VoiceActivationService to detect speech start/stop and automatically configure audio.

---

## 4️⃣ Info.plist

Ensure `UIBackgroundModes` includes `audio` for smooth background transitions.

---

## ✅ Success Criteria

• 🎵 Music plays in full quality until speech begins  
• 🎙 When voice detected → music ducks & switches to voiceChat mode  
• 🔈 After silence ~2s → returns to HD playback  
• 🧩 Works with Bluetooth or wired headsets  
• ⚙️ No audible pops when switching  
• 🧱 Build = 0 errors / 0 warnings

---

## 🚀 Next Phase

After this, we'll build Phase 17 – Safety AI / Context Guard:
detecting unsafe speeds or noise levels and pausing voice/music automatically to keep riders safe.

---

✅ **What this does right now:**  
- Keeps your Bluetooth connection stable  
- Delivers *great-quality music* (A2DP) when idle  
- Automatically ducks music when you speak  
- Restores full quality when silent

