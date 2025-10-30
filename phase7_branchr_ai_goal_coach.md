# 🚴‍♂️ Branchr Phase 7 – AI Ride Insights & Goal Coach

**Objective:**  
When a ride ends, Branchr should automatically analyze the ride data and display:
- A personalized AI summary (distance, pace, comparison to past rides)  
- Progress feedback (e.g. "2.4 mi farther than yesterday")  
- Suggested goals for the next ride (e.g. "Try to reach 7 mi tomorrow")  
- A streak tracker to visualize consistency  

---

## 🧠 Technical Goals
1. ✅ Add `AIInsightService` to generate summaries and next-goal recommendations.  
2. ✅ Extend `RideDataManager` to compute history-based metrics.  
3. ✅ Add `RideInsightsView` for results UI.  
4. ✅ Integrate with existing `RideSummaryView` — shown automatically after a ride ends.  
5. ✅ Store basic achievement streak data for motivational tracking.  

---

## 📂 File Structure

~/Documents/branchr/
│
├── Services/
│   ├── AIInsightService.swift
│   └── AchievementTracker.swift
│
└── Views/
├── RideInsightsView.swift
└── RideSummaryView.swift (update)

---

## ⚙️ Cursor Prompt Instructions

> You are extending the **Branchr** iOS SwiftUI app (Swift 5.9 / Xcode 16.2 / iOS 18.2 SDK).  
> Implement automatic AI-driven ride summaries and goal suggestions.

### 1️⃣ `AIInsightService.swift`
- Pure Swift logic (no network calls; use on-device calculations / ML if available).  
- Inputs: `recentRide: RideRecord`, `[RideRecord]` (history).  
- Output:  
  ```swift
  struct RideInsight {
      let summary: String
      let comparison: String
      let nextGoal: String
      let improvementPercent: Double
  }
  ```
• Compute:
  • Difference vs. previous ride (Δdistance, ΔavgSpeed)
  • Average improvement over last 5 rides
  • Suggested goal = current distance × (1 + target growth 0.05–0.1)
  • Return natural-language strings:
  • "You rode 6.4 mi in 32 min — your fastest pace this week!"
  • "You improved by 8% over yesterday. Goal: 7.0 mi next ride."

### 2️⃣ `AchievementTracker.swift`
• Maintains streaks & achievements.
• `@Published var currentStreakDays: Int`
• `@Published var longestStreakDays: Int`
• Updates after each ride:
  • If ride within 24 h of previous → +1 day streak
  • Else reset to 1
• Persist to UserDefaults.

### 3️⃣ `RideInsightsView.swift`
• SwiftUI card layout (same glass style).
• Displays:
  • Ride Summary: distance, duration, avg speed
  • AI Insights: improvement + comparison
  • Next Goal: target distance + emoji encouragement
  • Streak Indicator: 🔥 x days in a row
• Animations: fade-in on appear; smooth number counters.
• Button: "Done" → returns to Home.

### 4️⃣ `RideSummaryView.swift` (Update)
• When stopTracking() is called:
  1. Save ride record to RideDataManager.
  2. Call AIInsightService.generateInsights() using recent rides.
  3. Navigate to RideInsightsView showing the results.

---

## 🧩 Data Flow

```
Ride ends
   ↓
LocationTrackingService.stopTracking()
   ↓
RideDataManager.saveRide()
   ↓
AIInsightService.generateInsights()
   ↓
RideInsightsView → shows summary + goals
```

---

## 🧪 Testing Checklist
1. Complete 3–5 rides (simulated or real).
2. After each ride:
   • Insights appear automatically.
   • "You rode __ mi" and "Goal: __ mi next time" texts generate.
3. Check:
   • Streak count updates correctly.
   • Improvement % matches ride differences.
   • No crashes when no prior rides exist (handle first-ride case gracefully).

---

## ✅ Success Criteria
• Insight generation instant (< 0.5 s).
• Correct comparisons vs. history.
• Streak logic accurate + persistent.
• Smooth, motivating UI feedback.
• 0 build errors / warnings.

---

Save as:
~/Documents/branchr/phase7_branchr_ai_goal_coach.md

Then open this file in Cursor and type:

"Generate all code for Phase 7 – AI Ride Insights & Goal Coach."

---

🏁 Next Phase Preview

Next, we'll move into Phase 8
