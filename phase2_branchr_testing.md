# ✅ Branchr Phase 2 – Real Device Testing & Verification Guide

**Objective:**  
Test Branchr's peer-to-peer Bluetooth/Wi-Fi Direct voice chat system on two real iPhones.  
Confirm that connection discovery, pairing, and two-way voice streaming all work seamlessly.

---

## 🧠 Test Overview
We will:
1. Pair two nearby iPhones (Device A and Device B)
2. Launch Branchr on both devices
3. Start peer discovery from one device
4. Verify successful connection
5. Test live voice and mute/unmute functionality
6. Confirm stable connection and low latency

---

## ⚙️ Pre-Test Configuration

### **On Both Devices**
- Connect both iPhones to the same Wi-Fi network **or** ensure Bluetooth is **enabled**.
- Open **Settings → Privacy → Microphone → Branchr** → ensure microphone access is allowed.
- Open **Settings → Privacy → Bluetooth → Branchr** → ensure Bluetooth access is allowed.

### **In Xcode**
1. Select **Branchr target → Signing & Capabilities**  
   - Ensure your **Developer Team** is selected.  
   - Enable **Background Modes → Audio, AirPlay, and Picture in Picture**.  
2. Build the app for both devices:
   - Connect Device A → **Run (▶️)**
   - Connect Device B → **Run (▶️)**

---

## 🎧 Phase 1: Peer Connection Test

### **Device A (Host)**
1. Tap **Start Connection**
2. Xcode console should show:  Advertising Branchr session… 

### **Device B (Client)**
1. Tap **Start Connection**
2. Xcode console should show:  Found peer: [Device A Name]
Sending invitation…

### **Expected Behavior**
- A connection alert appears on **Device A** ("Branchr wants to connect").
- Tap **Accept** → both devices show: Connected to [peer name]. 

If this works, your MultipeerConnectivity is correctly implemented ✅

---

## 🎤 Phase 2: Voice Chat Test

### **Device A**
1. Speak near the microphone.
2. You should hear your voice through **Device B's speaker**.

### **Device B**
1. Speak — Device A should hear it instantly.

**Expected Result:**  
- Real-time, low-latency audio transmission both ways.  
- Minimal delay (under 100–150 ms typical).  

---

## 🔇 Phase 3: Mute/Unmute Test

1. On either device, tap **"Mute Mic"**.
2. Speak — your voice should no longer transmit.
3. Tap **"Unmute Mic"** — audio should resume immediately.

**Expected Result:**  
Mute/unmute toggles instantly, without disconnecting peers.

---

## 🧩 Debugging Tips

| Issue | Likely Cause | Fix |
|-------|---------------|-----|
| No peers found | Bluetooth or Wi-Fi disabled | Enable both and retry |
| Voice not heard | Mic permission denied | Allow mic access in Settings |
| Audio delay | Testing too far apart / network lag | Stay within 5–10 ft range |
| Crash on start | AVAudioSession not active | Ensure `.setActive(true)` in `VoiceChatService` |
| Disconnects randomly | Background mode disabled | Enable "Audio" in Background Modes |

---

## 🧠 Optional: Add Live Debug Output

In `PeerConnectionService.swift`, inside `session(_:peer:didChange:)`, add:
```swift
print("Peer \(peerID.displayName) changed state: \(state.rawValue)")
```

In `VoiceChatService.swift`, inside `startVoiceChat()`:  
```swift
print("Voice engine started successfully.")
```

These logs help verify everything is working correctly in real-time from Xcode.

⸻

✅ Success Criteria
   •   Both iPhones discover each other automatically
   •   Connection is established with encryption enabled
   •   Audio is crystal clear, minimal delay
   •   Mute/unmute works perfectly
   •   Xcode shows no runtime errors or crashes

⸻

Save this file as:
~/Documents/branchr/phase2_branchr_testing.md

After you generate and build your Phase 2 code, open this in Cursor and type:

"Run full Phase 2 device test checklist for Branchr."

⸻

🏁 Next Phase Preview

Once Phase 2 is complete and tested, we'll move into Phase 3 – Music Sync & Group Riding Mode 🎵
That will let riders play synced music across connected devices while maintaining live voice chat — a full social audio riding experience.
