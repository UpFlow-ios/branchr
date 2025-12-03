# Phase 74 – Resume Ride Button, Weekly Goal Pacing, HUD Stat Alignment

**Status:** ✅ Complete  
**Date:** January 2025

---

## Overview

Three targeted UI improvements:
1. **HomeView** – "Resume Ride Tracking" button behavior when ride is active
2. **Weekly Goal** – Increased default target from 25 to 75 miles for realistic weekly pacing
3. **Ride HUD** – Reorganized stat alignment with Host badge above Distance column

---

## Features Implemented

### 1. HomeView – "Resume Ride Tracking" Button

**File:** `Views/Home/HomeView.swift`

**Problem:**
- Button showed "Pause Ride" when ride was active, which was confusing
- Tapping it would pause the ride instead of just reopening the tracking view
- Users expected to resume/reopen the ride sheet, not pause it

**Solution:**
- Added `primaryRideActionTitle` computed property
- Shows "Resume Ride Tracking" when ride is active or paused
- Shows "Start Ride Tracking" when ride is idle or ended
- When ride is active/paused, tapping button only reopens the sheet (doesn't pause/resume)

**Implementation:**

**Before:**
```swift
PrimaryButton(
    rideSession.rideState == .idle || rideSession.rideState == .ended
        ? "Start Ride Tracking"
        : rideSession.rideState == .active
          ? "Pause Ride"
          : "Resume Ride",
    ...
) {
    if rideSession.rideState == .idle || rideSession.rideState == .ended {
        RideSessionManager.shared.startSoloRide(musicSource: musicSourceMode)
        withAnimation(.spring()) { showSmartRideSheet = true }
    } else if rideSession.rideState == .active {
        RideSessionManager.shared.pauseRide()  // ❌ This paused the ride
    } else if rideSession.rideState == .paused {
        RideSessionManager.shared.resumeRide()
    }
}
```

**After:**
```swift
// Phase 74: Primary ride action title
private var primaryRideActionTitle: String {
    let hasActiveRide = rideSession.rideState == .active || rideSession.rideState == .paused
    return hasActiveRide ? "Resume Ride Tracking" : "Start Ride Tracking"
}

PrimaryButton(
    primaryRideActionTitle,
    ...
) {
    if rideSession.rideState == .idle || rideSession.rideState == .ended {
        // Start new ride
        RideSessionManager.shared.startSoloRide(musicSource: musicSourceMode)
        withAnimation(.spring()) { showSmartRideSheet = true }
    } else {
        // Phase 74: If ride is active/paused, just reopen the sheet
        withAnimation(.spring()) { showSmartRideSheet = true }
    }
}
```

**Key Changes:**
- Added `primaryRideActionTitle` computed property
- Simplified button action logic
- When ride is active/paused, only opens sheet (no pause/resume calls)
- Button text clearly indicates "Resume" vs "Start"

**Visual Impact:**
- Clearer button labeling
- Better UX: tapping "Resume Ride Tracking" reopens the map view
- No accidental pausing when user just wants to see the ride

---

### 2. Weekly Goal – Increased Default Target

**File:** `Services/UserPreferenceManager.swift`

**Problem:**
- Default weekly goal was 25 miles
- Progress bar was moving too fast (reaching ~50% after ~1 hour of riding)
- Didn't feel like a true weekly challenge

**Solution:**
- Increased default weekly goal from 25.0 to 75.0 miles
- Existing users keep their current goal (only affects new users)
- Progress calculation unchanged (still caps at 100%)

**Implementation:**

**Before:**
```swift
// Phase 41: Weekly distance goal (default 25.0 miles)
self.weeklyDistanceGoalMiles = userDefaults.object(forKey: "weeklyDistanceGoalMiles") as? Double ?? 25.0
```

**After:**
```swift
// Phase 41: Weekly distance goal (default 25.0 miles)
// Phase 74: Increased default to 75.0 miles for more realistic weekly pacing
self.weeklyDistanceGoalMiles = userDefaults.object(forKey: "weeklyDistanceGoalMiles") as? Double ?? 75.0
```

**Key Changes:**
- Default value changed from `25.0` to `75.0`
- Only affects new users (existing users have their goal saved in UserDefaults)
- Progress bar now moves at 1/3 the previous speed
- More realistic weekly challenge

**Visual Impact:**
- Progress bar fills more slowly
- Weekly goal feels more achievable over a full week
- Better pacing for motivation

---

### 3. Ride HUD – Stat Alignment with Badges Above Columns

**File:** `Views/Ride/RideHostHUDView.swift`

**Problem:**
- Host badge was in the header row next to name
- Stats row had badges above Time and Avg Speed, but not Distance
- Layout didn't match the visual design mock

**Solution:**
- Removed Host badge from header row
- Moved Host badge above Distance column
- Kept Apple Music badge above Time column
- Kept Solo Ride badge above Avg Speed column
- Centered all stat columns with consistent spacing

**Implementation:**

**Before:**
```swift
// Header: Avatar + Name + Host badge
HStack {
    avatarView
    Text(hostName)
    Spacer()
    Text("Host")  // ❌ Host badge in header
        .background(theme.brandYellow)
}

// Stats: Distance (no badge), Time (Apple Music badge), Avg Speed (Solo Ride badge)
HStack {
    VStack { Distance stat }  // ❌ No badge above
    VStack { Apple Music badge; Time stat }
    VStack { Solo Ride badge; Avg Speed stat }
}
```

**After:**
```swift
// Header: Avatar + Name only (no Host badge)
HStack {
    avatarView
    Text(hostName)
    Spacer()
}

// Stats: All columns have badges above
HStack(alignment: .center, spacing: 0) {
    VStack(spacing: 6) {
        Text("Host")  // ✅ Host badge above Distance
            .background(theme.brandYellow)
        HostStatItem(icon: "location.fill", value: distance, label: "Distance", unit: "mi")
    }
    
    Spacer(minLength: 32)
    
    VStack(spacing: 6) {
        AppleMusicBadge()  // ✅ Apple Music badge above Time
        HostStatItem(icon: "clock.fill", value: duration, label: "Time", unit: nil)
    }
    
    Spacer(minLength: 32)
    
    VStack(spacing: 6) {
        SoloRideBadge()  // ✅ Solo Ride badge above Avg Speed
        HostStatItem(icon: "speedometer", value: speed, label: "Avg Speed", unit: "mph")
    }
}
```

**Key Changes:**

1. **Header Row:**
   - Removed Host badge from header
   - Now shows: Avatar + Name only

2. **Stats Row:**
   - Host badge moved above Distance column
   - Apple Music badge remains above Time column
   - Solo Ride badge remains above Avg Speed column
   - All columns use `VStack(alignment: .center, spacing: 6)`
   - Consistent `Spacer(minLength: 32)` between columns

3. **HostStatItem Alignment:**
   - Changed from `.leading` to `.center` alignment
   - All stat items now centered within their columns
   - Consistent visual baseline across all three columns

**Visual Impact:**
- Cleaner header (no Host badge clutter)
- All three stat columns have badges above them
- Perfectly aligned stats row
- Matches visual design mock

---

## Files Modified

1. **Views/Home/HomeView.swift**
   - Added `primaryRideActionTitle` computed property
   - Simplified primary ride button action logic
   - Button now shows "Resume Ride Tracking" when ride is active/paused

2. **Services/UserPreferenceManager.swift**
   - Increased default `weeklyDistanceGoalMiles` from 25.0 to 75.0
   - Added Phase 74 comment explaining the change

3. **Views/Ride/RideHostHUDView.swift**
   - Removed Host badge from header row
   - Moved Host badge above Distance column
   - Updated `HostStatItem` alignment to center
   - Refactored stats row layout with consistent spacing

---

## Technical Details

### Resume Ride Button Logic

**State Detection:**
```swift
let hasActiveRide = rideSession.rideState == .active || rideSession.rideState == .paused
```

**Button Behavior:**
- **Idle/Ended:** Start new ride + open sheet
- **Active/Paused:** Only open sheet (no state change)

### Weekly Goal Default

**UserDefaults Behavior:**
- Existing users: Keep their saved goal (not affected)
- New users: Get 75.0 miles as default
- Users can still adjust goal in Settings (5-200 miles range)

### HUD Stat Alignment

**Column Structure:**
```
VStack(spacing: 6) {
    Badge (Host / Apple Music / Solo Ride)
    HostStatItem (Distance / Time / Avg Speed)
}
.frame(maxWidth: .infinity)  // Equal width columns
```

**Spacing:**
- `spacing: 6` between badge and stat within each column
- `Spacer(minLength: 32)` between columns for visual balance

---

## Constraints & Safety

✅ **No Changes To:**
- Ride tracking logic or state management
- Music controls or transport functionality
- Audio session configuration
- Voice chat or connection logic
- Map rendering or route visualization
- SOS / Safety flows

✅ **Layout & Defaults Only:**
- All changes are purely visual/UX improvements
- No business logic modifications
- Default value change only affects new users

---

## Testing Checklist

1. **Resume Ride Button:**
   - ✅ Button shows "Start Ride Tracking" when no active ride
   - ✅ Button shows "Resume Ride Tracking" when ride is active
   - ✅ Button shows "Resume Ride Tracking" when ride is paused
   - ✅ Tapping "Resume Ride Tracking" opens sheet without pausing
   - ✅ Tapping "Start Ride Tracking" starts new ride

2. **Weekly Goal:**
   - ✅ New users get 75.0 miles as default
   - ✅ Existing users keep their saved goal
   - ✅ Progress bar fills at correct pace
   - ✅ Goal can still be adjusted in Settings

3. **HUD Stat Alignment:**
   - ✅ Header shows Avatar + Name only (no Host badge)
   - ✅ Host badge appears above Distance column
   - ✅ Apple Music badge appears above Time column
   - ✅ Solo Ride badge appears above Avg Speed column
   - ✅ All stat columns are centered and aligned
   - ✅ Spacing is consistent between columns

---

## Visual Summary

**Before:**
- Button: "Pause Ride" when active (confusing)
- Weekly Goal: 25 miles default (too fast)
- HUD: Host badge in header, Distance has no badge above

**After:**
- Button: "Resume Ride Tracking" when active (clear)
- Weekly Goal: 75 miles default (realistic pacing)
- HUD: Host badge above Distance, all columns have badges above

---

## Known Limitations

- Weekly goal default change only affects new users
- Existing users must manually adjust goal in Settings if desired
- Resume button behavior assumes sheet can be reopened (relies on existing sheet state management)

---

## Commit

```
Phase 74 – Resume Ride button, Weekly Goal pacing, HUD stat alignment
```

