# 🚴‍♂️ Branchr Phase 6.5 – Auto-Detect Ride & Tracking Prompt

**Objective:**  
Enable Branchr to automatically detect when a user starts a ride (bike, run, jog) and gently prompt:
> "It looks like you're riding. Would you like to start tracking this session?"

If the user taps **Yes**, GPS tracking begins.  
If the user taps **No**, tracking is skipped and motion detection continues passively.

---

## 🧠 Technical Goals
1. ✅ Implement motion-type detection using **CoreMotion** (`CMMotionActivityManager`).  
2. ✅ Automatically prompt the user when biking or running motion is detected.  
3. ✅ Allow quick "Yes / No" response directly in-app.  
4. ✅ Integrate with `LocationTrackingService` from Phase 6.  
5. ✅ Maintain battery efficiency (no heavy polling).

---

## 📂 File Paths

~/Documents/branchr/
│
├── Services/
│   ├── MotionDetectionService.swift
│
└── Views/
├── RidePromptView.swift
└── RideMapView.swift (minor update)

---

## ⚙️ Cursor Prompt Instructions

> You are extending the **Branchr** iOS SwiftUI app (Swift 5.9+, iOS 18.2, Xcode 16.2).  
> Add automatic ride detection and prompt logic.

### 1️⃣ `MotionDetectionService.swift`
- Uses `CMMotionActivityManager` to detect motion types:
  - `.cycling`, `.running`, `.walking`
- Observe updates continuously (every few seconds).
- When `.cycling` or `.running` state becomes `true`, trigger a Combine publisher:
  ```swift
  @Published var rideDetected: Bool
  ```

• Include properties:

```swift
private let motionManager = CMMotionActivityManager()
private let queue = OperationQueue()
```

• Functions:

```swift
func startMonitoring()
func stopMonitoring()
```

• Optional: debounce detection (don't re-prompt if user declined recently).

### 2️⃣ `RidePromptView.swift`
• Simple alert-style overlay (SwiftUI Alert or custom frosted card):

```
🚴‍♀️ Looks like you're on a ride!
Would you like to start tracking this session?
[Start Tracking]   [No Thanks]
```

• When the user taps Start Tracking, call:

```swift
locationTrackingService.startTracking()
```

• If No Thanks, set a cooldown flag (e.g., 10 min) before prompting again.

### 3️⃣ `RideMapView.swift` (Update)
• Add `.onReceive(motionDetectionService.$rideDetected)` → show RidePromptView automatically.
• If user accepts → transition to tracking state and show map overlay.

---

## 🔐 Info.plist Additions

```xml
<key>NSMotionUsageDescription</key>
<string>Branchr uses motion data to detect when you begin a ride and ask if you'd like to track it.</string>
```

## 🧩 Integration Logic
• `MotionDetectionService` runs quietly in the background (or when app is active).
• It does not start GPS automatically — it only triggers the prompt.
• Once the user approves, `LocationTrackingService.startTracking()` is called.
• Tracking continues normally until stopped manually.
• Motion detection pauses while tracking to save power, resumes after ride ends.

---

## 🧪 Test Checklist
1. Launch app → wait a few seconds while moving (or simulate via Xcode Motion).
2. Shake or move phone → triggers `.cycling` or `.running` state.
3. Prompt appears:

```
It looks like you're on a ride!
Would you like to start tracking this session?
```

4. Tap Yes → starts ride tracking automatically.
5. Tap No → no tracking; prompt reappears only after cooldown period.

---

## ✅ Success Criteria
• Motion detection works reliably for cycling / jogging.
• Prompt triggers only once per detected session.
• GPS tracking starts only after explicit user consent.
• Low battery impact (no constant location polling).
• 0 build errors / warnings.

---

Save as:
~/Documents/branchr/phase6_5_branchr_autotrack_prompt.md

Then in Cursor, type:

"Generate all code for Phase 6.5 – Auto-Detect Ride & Tracking Prompt."

---

🏁 Next Phase Preview

After this phase, we'll move into Phase 7
