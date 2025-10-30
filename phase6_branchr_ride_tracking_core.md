# 🚴‍♂️ Branchr Phase 6 – Ride Tracking & Route Logging (Core Build)

**Objective:**  
Add full GPS-based ride tracking so users can see:
- Their live position and route on a map  
- Total distance traveled (miles / km with decimals)  
- Elapsed time and average speed  
- A saved history of rides for later viewing  

No social-media or export features in this phase.

---

## 🧠 Technical Goals
1. ✅ Implement a clean `LocationTrackingService` using **CoreLocation**.  
2. ✅ Compute and display distance, duration, average speed in real time.  
3. ✅ Render route on a **MapKit** map (polyline).  
4. ✅ Log each ride in local storage (`RideDataManager`) for history.  
5. ✅ Build UI screens: live map + ride summary list.

---

## 📂 File Layout

~/Documents/branchr/
│
├── Services/
│    ├── LocationTrackingService.swift
│    └── RideDataManager.swift
│
└── Views/
├── RideMapView.swift
├── RideHistoryView.swift
└── RideSummaryView.swift

---

## ⚙️ Cursor Prompt Instructions

> You are extending the **Branchr** iOS SwiftUI app (Swift 5.9 / Xcode 16.2 / iOS 18.2 SDK).  
> Implement the ride-tracking core system described below.  
> No social-sharing features.

### 1️⃣ `LocationTrackingService.swift`
- Conform to `ObservableObject` + `CLLocationManagerDelegate`.  
- Properties:
  ```swift
  @Published var locations: [CLLocation]
  @Published var distanceTraveled: Double   // meters
  @Published var elapsedTime: TimeInterval
  @Published var isTracking: Bool

•    Functions:
    •    startTracking()
    •    pauseTracking()
    •    stopTracking()
    •    reset()
    •    Compute incremental distance:

if let last = locations.last { distance += location.distance(from: last) }

•    Set accuracy = .bestForNavigation and activity type = .fitness.
    •    Use a 1 Hz update interval; update UI on main thread.

2️⃣ RideDataManager.swift
    •    Local persistence via FileManager or UserDefaults (for MVP).
    •    Stores array of RideRecord structs:

struct RideRecord: Identifiable, Codable {
    var id: UUID
    var date: Date
    var distance: Double
    var duration: TimeInterval
    var averageSpeed: Double
    var route: [CLLocationCoordinate2D]
}

•    Functions:
    •    saveRide(_:)
    •    loadRides() -> [RideRecord]
    •    clearAll()

3️⃣ RideMapView.swift
    •    SwiftUI view embedding Map (MapKit) with live polyline.
    •    Overlays a small frosted-glass dashboard showing:
    •    Distance (automatic miles/km based on locale)
    •    Duration (timer)
    •    Average speed
    •    Buttons: Start / Pause / Stop.

4️⃣ RideSummaryView.swift
    •    Displays results after stopping tracking:
    •    Total distance, duration, avg speed.
    •    Date/time.
    •    Route snapshot (static Map with polyline).

5️⃣ RideHistoryView.swift
    •    Lists all previous rides stored by RideDataManager.
    •    Tap any ride → navigates to RideSummaryView (read-only mode).

⸻

🔐 Info.plist Permissions

<key>NSLocationWhenInUseUsageDescription</key>
<string>Branchr uses your location to record your route and distance.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Branchr continues tracking when the screen is locked during rides.</string>

🧪 Test Checklist
    1.    Launch Branchr → tap "Start Ride Tracking."
    2.    Grant location access.
    3.    Move (or use Xcode Simulator > Features > Location > City Run).
    4.    Verify:
    •    Polyline draws live.
    •    Distance updates smoothly (e.g., 0.2 → 1.5 → 5.9 mi).
    •    Pause/Resume/Stop works.
    5.    After stopping:
    •    Summary screen shows correct distance + time.
    •    Ride saves to History view.
    6.    Relaunch app → saved rides persist.

⸻

✅ Success Criteria
    •    Continuous GPS tracking (1 Hz).
    •    Accurate distance and time measurements.
    •    Smooth polyline drawing (MapKit).
    •    Local data persistence without errors.
    •    0 build warnings or crashes.

⸻

Save as:
~/Documents/branchr/phase6_branchr_ride_tracking_core.md

Then open in Cursor and type:

"Generate all code for Phase 6 – Ride Tracking & Route Logging (Core Build)."

⸻

🏁 Next Phase Preview

After route logging works, we'll move to Phase 7
