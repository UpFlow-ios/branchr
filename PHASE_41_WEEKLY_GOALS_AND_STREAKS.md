# Phase 41 – Weekly Ride Goals & Streaks

**Status:** ✅ Complete  
**Date:** November 25, 2025

---

## Overview

Added weekly ride goals and streak tracking to Branchr, making it feel more like a personal coach. Users can set a weekly distance goal and see their progress on the home screen, along with consecutive day streaks.

---

## Features Implemented

### 1. Weekly Goal Preference

**File:** `Services/UserPreferenceManager.swift`

- **`weeklyDistanceGoalMiles`** property
  - Default value: 25.0 miles
  - Stored in UserDefaults
  - Published property for reactive UI updates
  - Included in `resetToDefaults()` method
  - Logs changes: `Branchr: Weekly distance goal updated: X mi`

### 2. Goal & Streak Helpers in RideDataManager

**File:** `Services/RideDataManager.swift`

Added three new methods:

#### `totalDistanceThisWeek() -> Double`
- Computes total distance for the current calendar week (starting Sunday)
- Uses the same week calculation logic as `weeklySummary()`
- Filters rides from this week and sums distance
- Returns miles rounded to 2 decimal places
- Logs: `📊 RideDataManager: totalDistanceThisWeek = X mi`

#### `currentStreakDays() -> Int`
- Computes consecutive days with at least one ride, ending on today
- Groups rides by day (using `Calendar.startOfDay`)
- Iterates backward from today, counting consecutive days with rides
- Stops when a day with no rides is encountered
- Returns streak length (0 if no recent rides)
- Logs: `📊 RideDataManager: currentStreakDays = X`

#### `bestStreakDays() -> Int`
- Computes the longest streak of consecutive days with at least one ride in entire history
- Groups all rides by day
- Finds the longest consecutive sequence of days with rides
- Returns best streak length (0 if no rides)
- Logs: `📊 RideDataManager: bestStreakDays = X`

### 3. Weekly Goal Card UI

**File:** `Views/Home/WeeklyGoalCardView.swift` (NEW)

Complete goal progress card component:

#### Design Features
- **Header**: "Weekly Goal" title with target icon, flame icon for streak
- **Progress Bar**: Horizontal gradient bar showing completion percentage
  - Uses `theme.accentColor` to `theme.brandYellow` gradient
  - Animated with spring animation
  - Shows percentage (e.g., "45%")
- **Progress Text**: "X.X / Y mi" format showing current vs goal
- **Bottom Row**:
  - Left: "This week" label with current miles
  - Right: Streak info with flame icon, current streak, and best streak (if different)

#### Theme Integration
- Uses `ThemeManager.shared` for all colors
- Card background: `theme.cardBackground`
- Text: `theme.primaryText` / `theme.secondaryText`
- Accents: `theme.accentColor` / `theme.brandYellow`
- Fully theme-aware for light/dark mode

### 4. HomeView Integration

**File:** `Views/Home/HomeView.swift`

- Added `@ObservedObject` references:
  - `rideDataManager = RideDataManager.shared`
  - `userPreferences = UserPreferenceManager.shared`
- Added state variables:
  - `totalThisWeekMiles: Double`
  - `currentStreakDays: Int`
  - `bestStreakDays: Int`
- Added `updateGoalAndStreakData()` helper method
- Card placement: Between connection status and audio controls
- Auto-updates:
  - On `onAppear`
  - When `rideDataManager.rides.count` changes
  - When `userPreferences.weeklyDistanceGoalMiles` changes

### 5. Settings: Weekly Goal Editor

**File:** `Views/Settings/SettingsView.swift`

- Added "Ride Goals" section card
- Stepper control for weekly distance goal:
  - Range: 5 to 200 miles
  - Step: 5 miles
  - Shows current value: "X mi"
  - Persists to `UserPreferenceManager.weeklyDistanceGoalMiles`
  - Theme-aware styling matching other settings sections

---

## Technical Details

### Week Calculation

Uses the same logic as `weeklySummary()`:
- Calendar weeks start on Sunday (standard iOS calendar)
- Uses `Calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)`
- Filters rides where `ride.date >= thisWeekStart && ride.date < thisWeekEnd`

### Streak Calculation

**Current Streak:**
1. Groups all rides by day (using `Calendar.startOfDay`)
2. Starts from today
3. Counts backward day by day
4. Stops when a day with no rides is found
5. Returns consecutive count

**Best Streak:**
1. Groups all rides by day
2. Sorts days chronologically
3. Finds longest consecutive sequence
4. Returns maximum streak length

### Progress Calculation

```swift
progress = min(totalThisWeekMiles / max(goalMiles, 0.1), 1.0)
```

- Prevents division by zero (uses 0.1 minimum goal)
- Caps at 1.0 (100%) even if goal exceeded
- Used for progress bar width and percentage display

---

## Files Modified

1. **Services/UserPreferenceManager.swift**
   - Added `weeklyDistanceGoalMiles` property
   - Added initialization from UserDefaults (default: 25.0)
   - Added to `resetToDefaults()` method

2. **Services/RideDataManager.swift**
   - Added `totalDistanceThisWeek()` method
   - Added `currentStreakDays()` method
   - Added `bestStreakDays()` method

3. **Views/Home/WeeklyGoalCardView.swift** (NEW)
   - Complete goal card component with progress bar and streak display

4. **Views/Home/HomeView.swift**
   - Added goal/streak state variables
   - Added `updateGoalAndStreakData()` helper
   - Integrated `WeeklyGoalCardView` into layout
   - Added auto-update triggers

5. **Views/Settings/SettingsView.swift**
   - Added "Ride Goals" section
   - Added stepper control for weekly goal editing

---

## User Experience

### Before Phase 41
- No way to set weekly goals
- No visual progress tracking
- No streak information
- No motivation to maintain consistency

### After Phase 41
- Clear weekly goal setting (default: 25 mi)
- Visual progress bar on home screen
- Current streak display with flame icon
- Best streak tracking for motivation
- Easy goal adjustment in Settings
- Real-time updates when rides are completed

---

## Safety & Non-Regression

✅ **No breaking changes**:
- Existing ride tracking unchanged
- Ride metrics calculation unchanged
- Voice Coach logic unchanged
- Calendar saving unchanged
- Background location safety unchanged

✅ **Read-only card**:
- Goal card only displays data
- No destructive actions
- No modification of ride history

✅ **Performance**:
- Calculations are efficient (O(n) for streaks)
- Updates only when needed (ride count or goal changes)
- No blocking operations

---

## Testing Checklist

- [x] Build succeeds for simulator and device
- [x] Weekly goal card appears on home screen
- [x] Progress bar shows correct percentage
- [x] Current streak displays correctly
- [x] Best streak displays when different from current
- [x] Goal can be adjusted in Settings
- [x] Card updates when goal changes
- [x] Card updates when new rides are added
- [x] All UI is theme-aware (light/dark mode)
- [x] Calculations work correctly with test rides
- [x] No new warnings introduced

---

## Limitations & Future Enhancements

### Current Limitations
- Goal is only for distance (not duration or rides count)
- Streak resets if a single day is missed (no grace period)
- Best streak only shows if different from current
- No notifications for goal milestones

### Future Enhancements (Not in Phase 41)
- Multiple goal types (distance, duration, rides count)
- Streak grace period (e.g., 1 missed day doesn't break streak)
- Goal achievement celebrations
- Weekly goal history/charts
- Custom goal presets (Easy/Moderate/Ambitious buttons)

---

## Acceptance Criteria Met

✅ App builds successfully for simulator and device  
✅ No new warnings beyond existing Swift 6 concurrency warnings  
✅ Home screen shows Weekly Goal & Streak card with:
  - Total distance this week
  - Goal distance
  - Streak days (consecutive days with rides)
  - Best streak (when different from current)  
✅ Changing weekly goal in Settings updates the card  
✅ Ride history drives all goal/streak numbers correctly  
✅ All new UI components are fully theme-aware  
✅ Card updates automatically when rides change  

---

## Notes

- Weekly goal defaults to 25 miles (reasonable starting point)
- Streak calculation is strict (must have at least one ride per day)
- Progress bar uses gradient for visual appeal
- Flame icon (🔥) used for streak to match common fitness app patterns
- All calculations use existing `RideDataManager` ride history
- No external dependencies or API calls required

---

**Phase 41 Complete** ✅

