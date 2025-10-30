# 🎧 Branchr Phase 8 – AI Voice Ride Assistant (+ User Toggle)

**Objective:**  
Add a smart voice assistant that:
- Gives real-time spoken feedback during rides (distance, speed, goals)
- Responds to simple voice commands ("pause tracking", "resume", "end ride")
- Can be **toggled on/off** in Settings or Ride View

---

## 🧠 Technical Goals
1. ✅ Implement **VoiceAssistantService** using **AVSpeechSynthesizer** for spoken updates.  
2. ✅ Add **SpeechCommandService** using **Speech Framework** for command recognition.  
3. ✅ Provide a **user toggle** (`voiceAssistantEnabled`) persisted in UserDefaults.  
4. ✅ Integrate with `LocationTrackingService` and `RideMapView`.  
5. ✅ Ensure background audio mode enabled for live rides.

---

## 📂 File Structure

~/Documents/branchr/
│
├── Services/
│   ├── VoiceAssistantService.swift
│   ├── SpeechCommandService.swift
│   └── UserPreferenceManager.swift
│
└── Views/
│   ├── VoiceSettingsView.swift
│   ├── RideMapView.swift      (update)
│   └── RideSummaryView.swift  (update)

---

## ⚙️ Cursor Prompt Instructions

> Extend **Branchr** (Swift 5.9 / iOS 18.2 / Xcode 16.2) to include a real-time AI Voice Ride Assistant with a user on/off switch.

### 1️⃣ `VoiceAssistantService.swift`
- Use `AVSpeechSynthesizer` for speech output.  
- Expose:
  ```swift
  @Published var isEnabled: Bool
  func speak(_ message: String)
  func announceProgress(distance: Double, speed: Double)
  ```

•    Typical messages:
    •    Every 0.5 mi: "You've reached 0.5 miles."
    •    Every mile: "You've completed 3 miles in 12 minutes — keep it up!"
    •    At ride end: "Ride finished. Total distance: 5.8 miles."
    •    Respect isEnabled; no speech when off.
    •    Voice style: AVSpeechSynthesisVoice(language: "en-US").

### 2️⃣ `SpeechCommandService.swift`
•    Use SFSpeechRecognizer.
•    Recognize simple keywords:
    •    "pause tracking"
    •    "resume ride"
    •    "stop ride"
    •    "status update"
•    Publish recognized commands via Combine:

```swift
@Published var detectedCommand: RideVoiceCommand?
enum RideVoiceCommand { case pause, resume, stop, status }
```

•    Runs only if voice assistant enabled and permission granted.

### 3️⃣ `UserPreferenceManager.swift`
•    Singleton managing persistent settings via UserDefaults.
•    Store/retrieve:

```swift
@Published var voiceAssistantEnabled: Bool
```

•    Sync with SwiftUI @AppStorage("voiceAssistantEnabled").

### 4️⃣ `VoiceSettingsView.swift`
•    Glass-style settings screen.
•    Toggle:

```
[ Voice Assistant 🔊 ]  ⟶  ON / OFF
```

•    Description: "Hear real-time ride updates and use voice commands hands-free."
•    Changes update UserPreferenceManager.voiceAssistantEnabled.

### 5️⃣ `RideMapView.swift` (Update)
•    Inject both services.
•    On start tracking:
    •    If voice assistant enabled → VoiceAssistantService.speak("Ride tracking started.")
•    On distance milestones → auto announce.
•    .onReceive(SpeechCommandService.$detectedCommand):
    •    .pause → pause tracking + say "Ride paused."
    •    .resume → resume tracking + say "Resuming ride."
    •    .stop → stop tracking + say "Ride ended."
    •    .status → announce distance + speed.
•    Button 🎙 toggles listening on/off.

### 6️⃣ `RideSummaryView.swift` (Update)
•    After ride ends, if assistant enabled → speak final summary.

---

## 🔐 Info.plist Additions

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Branchr uses voice recognition for hands-free ride commands.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Branchr uses your microphone to listen for ride commands.</string>
```

---

## 🧪 Testing Checklist
1.    Enable Voice Assistant in Settings.
2.    Start ride → hear "Ride tracking started."
3.    Speak commands:
    •    "Pause tracking" → ride pauses + confirmation.
    •    "Resume ride" → ride resumes.
    •    "Stop ride" → tracking ends.
4.    Toggle off Voice Assistant → no speech or listening occurs.
5.    Confirm setting persists across app launches.

---

## ✅ Success Criteria
•    Voice feedback and commands work hands-free.
•    Toggle fully controls assistant activity.
•    Smooth integration with ride tracking engine.
•    No battery drain or crashes.
•    0 warnings / 0 errors.

---

Save as:
~/Documents/branchr/phase8_branchr_voice_assistant.md

Then open this file in Cursor and type:

"Generate all code for Phase 8 – AI Voice Ride Assistant (+ User Toggle)."

---

## 🏁 Next Phase Preview

Next we'll add Phase 9 – Safety Mode & Auto-Duck, where Branchr automatically lowers music volume when speeds increase or wind noise rises, and includes a quick "SOS" button to alert contacts in an emergency 🆘 🏍️✨
