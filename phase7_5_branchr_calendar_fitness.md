# 📅 Branchr Phase 7.5 – Ride Calendar & Fitness Overview

**Objective:**  
Add a **calendar interface** that lets users see:
- Which days they rode  
- Distance for each day (miles/km)  
- Estimated calories burned  
- Weekly/monthly totals for motivation  

Integrate this with existing `RideDataManager` and `AIInsightService`.

---

## 🧠 Technical Goals
1. ✅ Build a SwiftUI **Calendar View** showing ride activity by date.  
2. ✅ Compute total distance and calories for each ride.  
3. ✅ Display summary metrics (weekly distance, total rides, calories burned).  
4. ✅ Allow tapping a date to view ride details.  
5. ✅ Integrate with streak tracker and AI goal system.  

---

## 📂 File Structure

~/Documents/branchr/
│
├── Services/
│   └── CalorieCalculator.swift
│
└── Views/
├── RideCalendarView.swift
├── RideDayDetailView.swift
└── RideSummaryView.swift (minor update)

---

## ⚙️ Cursor Prompt Instructions

> You are extending the **Branchr** iOS SwiftUI app (Swift 5.9 / Xcode 16.2 / iOS 18.2 SDK).  
> Implement a ride-tracking calendar and calorie tracking logic.

### 1️⃣ `CalorieCalculator.swift`
- Pure Swift service to estimate calories burned.  
- Formula (for cycling example):  

Calories = MET × Weight(kg) × Duration(hrs)

Where:
- MET = 8.0 for moderate cycling, 10.0 for intense  
- Default user weight = 70kg (store adjustable value later)
- Add helper:
```swift
func calculateCalories(distance: Double, duration: TimeInterval, avgSpeed: Double) -> Double
```

Use average speed to adjust MET dynamically (slower = 6.0, faster = 10.0).
• Return calories as Double (kcal).

### 2️⃣ `RideCalendarView.swift`
• SwiftUI calendar component using DatePicker in .graphical style or custom grid.
• Highlights days with recorded rides using data from RideDataManager.
• Shows total rides, total miles, total calories for selected month.
• Below calendar, show summary list:

🗓 This Month
- Total Distance: 47.8 mi
- Total Calories: 3,482 kcal
- Total Rides: 8

• Tap a date → opens RideDayDetailView.

### 3️⃣ `RideDayDetailView.swift`
• Displays all rides on that selected date.
• Each ride row: distance, duration, calories.
• Tapping opens that ride's summary map.

### 4️⃣ `RideSummaryView.swift` (Update)
• After saving a ride, compute calories via CalorieCalculator and include it in RideRecord.

```swift
struct RideRecord: Identifiable, Codable {
    var id: UUID
    var date: Date
    var distance: Double
    var duration: TimeInterval
    var averageSpeed: Double
    var calories: Double
    var route: [CLLocationCoordinate2D]
}
```

---

## 🧩 Integration Logic
1. After each ride, calories are auto-calculated and stored.
2. RideCalendarView aggregates ride data by date and month.
3. Calendar colors:
   • 🟢 Light Green → short ride
   • 🟡 Yellow → medium distance
   • 🔴 Red → long ride
4. Tapping a date opens details with all rides + stats.

---

## 🧪 Test Checklist
1. Run multiple simulated rides across different dates.
2. Open Calendar Tab:
   • See colored markers on ride days.
   • Tap a date → rides appear correctly.
3. Check calorie values update based on distance/time.
4. Verify monthly totals (sum of all rides).
5. Confirm data persists after relaunch.

---

## ✅ Success Criteria
• Calendar shows all rides by date.
• Calories computed automatically.
• Accurate totals for distance/time/calories.
• Smooth navigation and UI animation.
• No performance drops or build warnings.

---

Save as:
~/Documents/branchr/phase7_5_branchr_calendar_fitness.md

Then open this file in Cursor and type:

"Generate all code for Phase 7.5 – Ride Calendar & Fitness Overview."

---

🏁 Next Phase Preview

After this, we'll move into Phase 8 – AI Voice Ride Assistant,
which adds real-time voice feedback like

"You've hit 3 miles — great pace!"
and allows simple voice commands like
"Pause tracking" or "Show stats." 🎧🗣️
