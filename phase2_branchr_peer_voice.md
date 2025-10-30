# 🚀 Branchr Phase 2 – Peer Connection & Voice Chat Setup
**Objective:**  
Implement real-time voice communication and device pairing between nearby iPhones using **MultipeerConnectivity** and **AVAudioEngine**.  
This allows two riders to connect via Bluetooth/Wi-Fi Direct, talk hands-free, and mute/unmute their mic during rides.

---

## 🧠 Technical Goals

1. ✅ Create a service to **discover and connect nearby devices**.
2. ✅ Implement a **two-way voice streaming engine** with low latency.
3. ✅ Add a **mute toggle** for the microphone.
4. ✅ Wire it all into the **HomeView** UI.
5. ✅ Keep the entire implementation 100 % Swift (no bridging header).

---

## 📂 Target File Paths
All files go inside your cleaned structure: ~/Documents/branchr/
│
├── Services/
│   ├── PeerConnectionService.swift
│   └── VoiceChatService.swift
│
└── Views/
└── HomeView.swift ---

## ⚙️ Cursor Prompt Instructions

**Prompt for Cursor:**

> You are updating the Branchr iOS app (SwiftUI, pure Swift, no Objective-C).  
> Create two new service files in `/Services`:  
> 
> 1. `PeerConnectionService.swift` — handles discovery, invitation, and session management using `MultipeerConnectivity`.  
> 2. `VoiceChatService.swift` — uses `AVAudioEngine` for real-time voice streaming with start/stop/mute support.  
> 
> Then, update `/Views/HomeView.swift` to:
> - Initialize both services  
> - Show the connected peer's name  
> - Include buttons: **Start Connection**, **Mute/Unmute Mic**  
> - Use a clean, minimal SwiftUI layout matching Apple HIG (dark mode friendly).  
> 
> Ensure:
> - Concurrency safety (use `DispatchQueue.main.async` for UI updates).  
> - Proper `AVAudioSession` configuration: `.playAndRecord` with `.allowBluetooth`.  
> - Use `.required` encryption for MultipeerConnectivity.  
> - Include clear code comments.  
> - No external dependencies (pure Apple frameworks).  
> - No deprecated APIs.  
> 
> Finally, verify compilation with iOS 18.2 SDK and Xcode 16.2.  
> Return full Swift code for all three files.

---

## 🧩 Expected Output

Cursor should produce:

1. `PeerConnectionService.swift`  
   - Connects nearby peers  
   - Updates `@Published var connectedPeers: [MCPeerID]`

2. `VoiceChatService.swift`  
   - Starts/stops live voice chat  
   - Includes `mute(_:)` method  

3. `HomeView.swift`  
   - "Start Connection" button triggers discovery  
   - "Mute/Unmute Mic" toggles audio output  
   - Clean black-and-green Branchr styling  

---

## 🧱 Additional Notes

- Make sure `Info.plist` already includes:
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>Branchr needs microphone access for live voice chat.</string>
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>Branchr uses Bluetooth to connect with nearby riders.</string>
  <key>NSBluetoothPeripheralUsageDescription</key>
  <string>Branchr connects to nearby devices for voice and music sync.</string>
  ```
- Background Modes → Audio must be enabled in target Capabilities.

⸻

✅ Success Criteria

After generation:
   •   Two iPhones running Branchr can discover each other nearby.
   •   Voice transmits in real-time (low latency).
   •   Mute toggle functions instantly.
   •   UI displays connected peer name.
   •   Project builds with 0 errors / 0 warnings.

⸻

Save this file as:
~/Documents/branchr/phase2_branchr_peer_voice.md

Then in Cursor, open this file and type:

"Generate all code for this phase."
