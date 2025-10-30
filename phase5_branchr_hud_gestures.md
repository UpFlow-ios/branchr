# 🚀 Branchr Phase 5 – Smart Ride HUD & Gesture Controls (Hands-Free)

**Objective:**  
Add a **Ride HUD overlay** with big, glanceable indicators and **gesture controls** so riders can adjust **music vs voice** *without touching the screen*:
- **Head gestures** (CoreMotion): nods/tilts/shakes to change mix modes or volumes
- **Earbud / car controls** (MPRemoteCommandCenter): map play/pause/next to quick actions
- **Haptics + sound cues** for confirmation
- Optional **Live Activity / Dynamic Island** mini-HUD

> Important: We'll use only public APIs:
> - Head gestures via **CoreMotion** (accelerometer/gyro) + simple on-device classification (no ML frameworks required).
> - Earbud controls via **MPRemoteCommandCenter** (maps play/pause/next/prev to our actions).
> - We **cannot** read "AirPods tap" directly; we instead leverage standard remote commands.

---

## 📂 New/Updated Files & Paths

~/Documents/branchr/
│
├── Services/
│   ├── GestureControlService.swift        // CoreMotion sampling + gesture classification
│   ├── HUDManager.swift                   // State for HUD, haptics, and announcements
│   └── HapticsService.swift               // Taptic feedback helpers
│
├── Views/
│   ├── RideHUDView.swift                  // Overlay HUD: mode, volumes, peer count
│   └── GroupRideView.swift                // (update) add HUD button + sheet/toggle
│
└── App/
└── RemoteCommandRegistrar.swift       // MPRemoteCommandCenter wiring. ---

## ⚙️ Implement This Exactly

You are updating the **Branchr** iOS SwiftUI app (Swift 5.9+, Xcode 16.2, iOS 18.2 SDK).  
Use only Apple frameworks (no third-party dependencies).  
Integrate with existing services from prior phases:
- `AudioMixerService` (voice/music volumes, modes)
- `VoiceChatService`, `MusicSyncService`
- `GroupSessionManager` (optional HUD peer count)

### 1) `GestureControlService.swift`
- Use `CoreMotion` (`CMMotionManager` or `CMHeadphoneMotionManager` if available; fall back to `CMMotionManager`).
- Sample at ~60 Hz, low-latency.
- Implement lightweight gesture detection with debouncing:
  - **Head Nod (Down)** → **decrease music volume** by -0.05 (clamped 0…1)
  - **Head Nod (Up)** → **increase music volume** by +0.05
  - **Tilt Left** (roll < −θ) → **voice-only mode**
  - **Tilt Right** (roll > +θ) → **music-only mode**
  - **Quick Shake** (|accel| spike) → **both mode** (toggles back to mixed)
- Expose:
  ```swift
  @Published var lastGesture: RideGesture? // .nodUp, .nodDown, .tiltLeft, .tiltRight, .shake
  func start()
  func stop(). ---

•    Ensure thread safety; publish UI updates on main queue.
    •    Provide sensitivity constants (pitchThreshold, rollThreshold, shakeMagnitude, deadZone, minIntervalBetweenGestures).

2) HapticsService.swift
    •    Tiny wrapper around UINotificationFeedbackGenerator and UIImpactFeedbackGenerator.
    •    Methods:
    •    success(), warning(), error()
    •    lightTap(), mediumTap(), heavyTap()

3) HUDManager.swift
    •    Central observable state for the HUD overlay:
    •    @Published var isVisible: Bool
    •    @Published var currentMode: AudioMode // .voiceOnly, .musicOnly, .both
    •    @Published var musicVolume: Float
    •    @Published var voiceVolume: Float
    •    @Published var peerCount: Int
    •    func flash(_ message: String) to briefly show a banner/badge in the HUD
    •    Subscribes to GestureControlService and updates AudioMixerService accordingly.
    •    Triggers HapticsService on mode/volume changes.

4) RideHUDView.swift
    •    SwiftUI overlay (glassmorphism) pinned top-center with large, legible info:
    •    Mode pill: VOICE ONLY / MUSIC ONLY / BOTH
    •    Two horizontal bar meters (music vs voice volumes)
    •    Small row: peers connected • connection status
    •    Temporary toast/label for recent action (e.g., "Music +5%")
    •    Animations for value changes; keep it performant.
    •    Safe-area aware; dark mode first.

5) RemoteCommandRegistrar.swift
    •    Register with MPRemoteCommandCenter.shared():
    •    togglePlayPause → toggle Both ↔ Voice Only
    •    nextTrack → Music Only
    •    previousTrack → Both
    •    stop → Voice Only
    •    Mark handlers as enabled, return .success on handled.
    •    Keep all UI changes on the main queue.
    •    Ensure AVAudioSession already set with .playAndRecord + .allowBluetooth.

6) GroupRideView.swift (Update)
    •    Add a persistent button (e.g., 👁 or 🎛) to show/hide the HUD.
    •    Start/stop GestureControlService with ride lifecycle:
    •    Start when entering ride view; stop on leave.

7) Optional: Live Activity Mini-HUD
    •    If ActivityKit is already used, add a simple Live Activity with mode + volumes.
    •    Optional—not required to pass the phase.

⸻

🧩 Integration Rules
    •    Volumes & Modes: call into AudioMixerService:
    •    setMusicVolume(_:), setVoiceVolume(_:), switchMode(_:)
    •    Clamping: always clamp volumes to [0, 1].
    •    Debounce: ignore repeat gestures within minIntervalBetweenGestures (e.g., 600 ms).
    •    Safety: never block the main thread; CoreMotion on a background queue.

🔐 Info.plist Additions (if missing). 

<key>NSMotionUsageDescription</key>
<string>Branchr uses motion data to enable safe, hands-free gesture controls while riding.</string>
<key>UIApplicationSceneManifest</key>
<!-- (Leave your existing scene manifest; no extra keys strictly required here) -->. Note: NSMicrophoneUsageDescription, NSBluetoothAlwaysUsageDescription, NSAppleMusicUsageDescription should already be present from earlier phases.

⸻

🧪 Test Plan

Environment
    •    Two iPhones, connected and in an active Group Ride.
    •    Bluetooth on; Mic + Motion permissions granted.

Scenarios
    1.    HUD Toggle
    •    Tap HUD button → overlay appears.
    •    Verify mode label + volumes reflect current AudioMixerService state.
    2.    Head Gestures
    •    Nod Up: Music volume +0.05, haptic feedback, HUD toast: "Music +5%".
    •    Nod Down: Music volume −0.05, haptic, toast.
    •    Tilt Left: Mode → Voice Only, haptic success, toast.
    •    Tilt Right: Mode → Music Only, haptic success, toast.
    •    Quick Shake: Mode → Both, medium tap, toast.
    3.    Remote Commands (Earbud/Car)
    •    Play/Pause: toggles Both ↔ Voice Only.
    •    Next: Music Only.
    •    Previous: Both.
    •    Stop: Voice Only.
    4.    Ride Lifecycle
    •    Enter GroupRideView → gestures start.
    •    Leave ride → gestures stop; HUD hides.

Pass Criteria
    •    All gestures recognized reliably without false positives.
    •    Volumes/modes update instantly (<100 ms perceived).
    •    No crashes, frame hitches, or audio pops.
    •    CPU usage stays reasonable; battery impact acceptable.

⸻

✅ Deliverables

Return full Swift code for:
    •    Services/GestureControlService.swift
    •    Services/HapticsService.swift
    •    Services/HUDManager.swift
    •    Views/RideHUDView.swift
    •    App/RemoteCommandRegistrar.swift
    •    Updated Views/GroupRideView.swift (HUD toggle + lifecycle hooks)

All code must:
    •    Compile with 0 errors / 0 warnings on iOS 18.2 SDK, Xcode 16.2.
    •    Use DispatchQueue.main.async for UI property changes.
    •    Include clear comments and constants for thresholds.

⸻

🔧 Constants (Suggested Defaults)
    •    pitchThreshold = 0.20 rad (≈ 11.5°) for nod up/down
    •    rollThreshold  = 0.25 rad (≈ 14.3°) for left/right tilts
    •    shakeMagnitude = 2.2 g (peak)
    •    minIntervalBetweenGestures = 0.6 s
    •    volumeStep = 0.05

You may tune thresholds for stability.

⸻

🏁 After Generation
    1.    Build & run on device.
    2.    Enable Motion permission when prompted.
    3.    Open Group Ride → toggle HUD → try gestures.
    4.    Confirm haptics and HUD toasts match the action.
    5.    Validate remote commands with earbuds or car steering controls.
