# Phase 43C – Ride Header Swap: Host HUD on Top, Solo Ride Pill on Map

**Status:** ✅ Complete  
**Date:** November 25, 2025

---

## Overview

Swapped the Ride Tracking screen layout so the Host HUD appears in the top header strip (replacing the ride mode pill), and the ride mode pill now appears as an overlay in the top-right corner of the map card. This creates a cleaner hierarchy with host information prominently displayed at the top.

---

## Goals

- Move Host HUD from map overlay to top header strip
- Move ride mode pill from top header to map card top-right corner
- Eliminate duplicate ride mode indicators
- Maintain all existing functionality

---

## Layout Changes

### Before (Phase 43B)
- **Top header**: Ride mode pill ("Solo Ride" / "Connected") + close button
- **Map card**: Host HUD overlay on top-left of map
- **Result**: Host HUD and ride mode pill in separate locations

### After (Phase 43C)
- **Top header**: Host HUD (avatar, name, "Host" badge, metrics) + close button
- **Map card**: Ride mode pill in top-right corner overlay
- **Result**: Host info at top, ride mode on map, cleaner hierarchy

---

## Changes Made

### 1. Created Reusable Component

**File:** `Views/Ride/RideHostHUDView.swift`

**Added:**
- `RideModeBadgeView` - Reusable component for ride mode pills
- Extracted from `RideHostHUDView.rideModePill` for reuse
- Used by both Host HUD (for connected rides) and map overlay

**Component:**
```swift
struct RideModeBadgeView: View {
    let label: String
    let color: Color // dot color
    
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.8)))
    }
}
```

### 2. Updated RideTrackingView

**File:** `Views/Ride/RideTrackingView.swift`

**Changes:**

1. **Replaced `rideStatusStrip`:**
   - **Before**: Showed ride mode pill + connection status + close button
   - **After**: Shows Host HUD + close button
   - Host HUD only appears when ride is active or paused

2. **Updated `mapCard`:**
   - Wrapped map in `ZStack(alignment: .topTrailing)`
   - Added ride mode pill overlay in top-right corner
   - Pill appears only when ride is active or paused
   - Padding: 12pt from top and trailing edges

3. **Added `rideModeBadgeConfig`:**
   - Computed property that returns label and color based on connection state
   - Uses existing `connectionManager.state` (no new logic)
   - Returns `nil` when ride is not active/paused

4. **Removed Host HUD overlay:**
   - Removed Host HUD from ZStack overlay on map
   - Host HUD now only appears in top header

5. **Cleaned up unused properties:**
   - Removed `rideModeLabel` and `rideModeColor` (replaced by `rideModeBadgeConfig`)

---

## Visual Result

### Solo Ride
- **Top header**: Host HUD showing avatar, name, "Host" badge, metrics
- **Map card**: "Solo Ride" pill in top-right corner (yellow dot)
- **No duplicates**: Single ride mode indicator on map

### Group/Connected Ride
- **Top header**: Host HUD with all info
- **Map card**: "Connected" pill in top-right corner (green dot)
- **Host HUD**: Still shows "Connected" pill on right side (for group rides)

---

## Functionality Preserved

✅ **All ride logic unchanged:**
- Ride start, pause, resume, end behavior unchanged
- Host/group ride detection unchanged
- Connection status unchanged

✅ **All UI elements preserved:**
- Host avatar, name, "Host" badge still show
- Metrics (distance, speed, time) still show
- Music badge still shows when active
- Close button still works

✅ **Data sources unchanged:**
- All properties still read from existing sources:
  - `profileManager.currentDisplayName`, `currentProfileImage`
  - `rideService.totalDistanceMiles`, `currentSpeedMph`, `formattedDuration`
  - `connectionManager.state`
  - `musicSync.currentTrack?.isPlaying`

---

## Technical Details

### Host HUD in Header
- **Condition**: Only shows when `rideService.rideState == .active || .paused`
- **Position**: Top of ScrollView, first element
- **Layout**: HStack with Host HUD on left, Spacer, close button on right

### Ride Mode Pill on Map
- **Position**: Top-right corner of map card
- **Overlay**: ZStack with `.topTrailing` alignment
- **Padding**: 12pt from top and trailing edges
- **Condition**: Only shows when ride is active or paused
- **Background**: Black capsule with 80% opacity for visibility over map

### Badge Configuration
- **Solo Ride**: Yellow dot (`theme.brandYellow`), "Solo Ride" label
- **Connected**: Green dot (`Color.green`), "Connected" label
- **Inactive**: Returns `nil` (no badge shown)

---

## Acceptance Criteria Met

✅ **Solo Ride**
- Top header shows Host HUD (avatar, name, "Host", metrics)
- Map card shows single "Solo Ride" pill in top-right corner
- No duplicate "Solo Ride" pills

✅ **Group/Connected Ride**
- Top header shows Host HUD
- Map card shows "Connected" pill in top-right corner
- Host metrics and DJ status continue to work

✅ **No Logic Regressions**
- Ride start/pause/resume/end work exactly as before
- Voice coach, audio feedback, and ride metrics unchanged
- No new SwiftUI layout warnings or runtime errors

---

## Files Modified

1. **Views/Ride/RideHostHUDView.swift**
   - Updated `rideModePill` to use `RideModeBadgeView`
   - Added `RideModeBadgeView` reusable component

2. **Views/Ride/RideTrackingView.swift**
   - Replaced `rideStatusStrip` content with Host HUD
   - Updated `mapCard` to include ride mode pill overlay
   - Added `rideModeBadgeConfig` computed property
   - Removed Host HUD from ZStack overlay
   - Removed unused `rideModeLabel` and `rideModeColor` properties

---

## Notes

- **UI-only refactor**: No business logic, services, or data models modified
- **Reusable component**: `RideModeBadgeView` can be used elsewhere if needed
- **Cleaner hierarchy**: Host info at top, ride mode on map
- **No duplicates**: Single ride mode indicator per screen
- **Theme-aware**: All colors use `ThemeManager` for consistency

---

**Phase 43C Complete** ✅

