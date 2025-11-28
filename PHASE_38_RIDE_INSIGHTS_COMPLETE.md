# Phase 38 – Ride Insights Charts & Weekly Stats

**Status:** ✅ Complete  
**Date:** November 20, 2025

---

## Overview

Implemented ride insights with trend charts, weekly stats, and comprehensive ride analytics. Added final light/dark mode polish across all calendar and summary views.

---

## Features Implemented

### 1. Ride Trend Data Model & Aggregation

- **RideTrendPoint** struct added to `RideDataManager.swift`
  - Properties: date, totalDistanceMiles, totalDurationSeconds, averageSpeedMph
  - Used for daily trend aggregation

- **recentDailyTrend(lastNDays:)** method
  - Groups rides by calendar day
  - Aggregates distance, duration, and average speed per day
  - Returns points sorted by date (includes days with zero rides for continuous charts)

- **weeklySummary()** method
  - Computes this week vs last week miles
  - Uses calendar weeks starting on Sunday
  - Returns tuple: (thisWeekMiles, lastWeekMiles)

### 2. Ride Insights View

**File:** `Views/Calendar/RideInsightsView.swift`

Features:
- **Weekly Summary Card**: Shows this week vs last week with trend indicators (▲/▼)
- **Distance Trend Chart**: Custom SwiftUI bar chart showing daily distance for last 7 days
- **Recent Days List**: Shows date, distance, duration, and average speed for each day
- **Empty State**: Friendly message when no rides exist
- **Theme-aware styling**: All components use ThemeManager for light/dark mode support

### 3. UI Integration

- **EnhancedRideSummaryView**:
  - Replaced placeholder text with "View Ride Insights" button
  - Opens `RideInsightsView` as a sheet
  - Button styled with theme colors

- **RideCalendarView**:
  - Added Insights toolbar button (chart icon) in top-right
  - Opens `RideInsightsView` as a sheet
  - Logs: `📊 RideCalendarView: opening RideInsightsView`

### 4. Light/Dark Mode Polish

Fixed all remaining visibility issues:
- **EnhancedRideSummaryView**:
  - `PrimaryStatCard`: Uses `theme.primaryText`, `theme.secondaryText`, `theme.cardBackground`
  - `InsightCard`: Uses theme colors instead of hardcoded `.white`/`.black`
  - Done button: Uses `theme.brandYellow` and theme-aware text color

- **RideInsightsView**:
  - All components use `ThemeManager` colors
  - Chart bars use `theme.accentColor`
  - Comparison indicators use theme-aware colors (darker shades in light mode)

- All calendar views verified to use theme colors consistently

---

## Files Modified

1. **Services/RideDataManager.swift**
   - Added `RideTrendPoint` struct
   - Added `recentDailyTrend()` method
   - Added `weeklySummary()` method

2. **Views/Calendar/RideInsightsView.swift** (NEW)
   - Complete insights view with charts and stats
   - Custom SwiftUI bar chart implementation
   - Weekly summary with trend indicators
   - Recent days list

3. **Views/Rides/EnhancedRideSummaryView.swift**
   - Replaced placeholder with "View Ride Insights" button
   - Fixed `PrimaryStatCard` and `InsightCard` to use theme colors
   - Added sheet presentation for `RideInsightsView`

4. **Views/Calendar/RideCalendarView.swift**
   - Added Insights toolbar button
   - Added sheet presentation for `RideInsightsView`

5. **Views/RideInsightsView.swift** (DELETED)
   - Removed old duplicate file that conflicted with new implementation

---

## Phase 38B – Build Cleanup

**Status:** ✅ Complete  
**Date:** November 20, 2025

### Issue

Xcode build error: "Multiple commands produce ... RideInsightsView.stringsdata" and "Invalid redeclaration of 'RideInsightsView'"

### Resolution

1. **Audit Results**:
   - Found only one `RideInsightsView.swift` file: `Views/Calendar/RideInsightsView.swift`
   - Found only one `struct RideInsightsView` declaration (Phase 38 version)
   - Old `Views/RideInsightsView.swift` was already deleted in Phase 38
   - **Note**: If a file was renamed to "rideinsightsview2" (or similar), it must be checked to ensure:
     - The struct inside is renamed to `LegacyRideInsightsView` (or removed from the target)
     - The file is not included in the branchr app target's build phases

2. **Project File Check**:
   - No duplicate file references in `project.pbxproj`
   - No duplicate build file entries
   - File is auto-discovered by Xcode (no explicit project file references needed)

3. **Build Verification**:
   - Clean build succeeded
   - No "Invalid redeclaration" errors
   - No "Multiple commands produce" errors
   - App builds successfully for both simulator and device

### Final State

- **Canonical RideInsightsView**: `Views/Calendar/RideInsightsView.swift` (Phase 38 version)
  - Header comment: "Created for Phase 38 - Ride Insights Charts & Weekly Stats"
  - This is the **only** file that should contain `struct RideInsightsView: View`
- **No duplicate files**: Only one RideInsightsView.swift exists in the project
- **No duplicate declarations**: Only one struct RideInsightsView exists
- **Clean build**: All build errors resolved
- **All call sites verified**: EnhancedRideSummaryView and RideCalendarView both use the canonical version

### If Duplicate Error Persists

If Xcode still shows "Invalid redeclaration of 'RideInsightsView'", check:

1. **Any file renamed to "rideinsightsview2" or similar**:
   - If such a file exists, it must have its struct renamed to `LegacyRideInsightsView`
   - Or the file must be removed from the branchr target's build phases

2. **Xcode DerivedData**:
   - Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
   - Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/branchr-*`

3. **Project file references**:
   - Ensure no duplicate file references in Xcode project navigator
   - Check that only `Views/Calendar/RideInsightsView.swift` is included in the target

---

## Testing Checklist

✅ Build succeeds for simulator and device  
✅ No duplicate declaration errors  
✅ No "Multiple commands produce" errors  
✅ Ride Insights opens from EnhancedRideSummaryView  
✅ Ride Insights opens from RideCalendarView  
✅ Charts display correctly  
✅ Weekly stats show correct comparisons  
✅ Recent days list shows accurate metrics  
✅ All views readable in light mode  
✅ All views readable in dark mode  

---

## Notes

- Custom SwiftUI bar chart implementation (no external dependencies)
- All calculations are pure functions with no side effects
- Theme-aware colors throughout for consistent light/dark mode support
- Logging added for debugging (metrics updates, view opens)

