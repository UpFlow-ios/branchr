# Phase 71 – Ride Map Height & Home Reorder

**Status:** ✅ Complete  
**Date:** January 2025

---

## Overview

Increased map height in RideTrackingView for better route visibility and reordered HomeView layout to place the Weekly Goal card above the primary action buttons for improved visual hierarchy.

---

## Features Implemented

### 1. RideTrackingView – Taller Map with Full-Screen Layout

**File:** `Views/Ride/RideTrackingView.swift`

**Problem:**
- Map was too small (400pt fixed height)
- Limited route visibility during rides
- Layout used ScrollView which wasn't optimal for full-screen ride experience

**Solution:**
- Replaced ScrollView with GeometryReader for responsive sizing
- Map now uses ~62% of screen height (dynamically calculated)
- Full-screen layout with map at top, buttons at bottom
- Host HUD remains overlaid on map (from Phase 70)

**Implementation Details:**

```swift
GeometryReader { proxy in
    let mapHeight = proxy.size.height * 0.62 // ~62% of screen height
    
    VStack(spacing: 16) {
        // Grabber handle
        grabberHandle
        
        // Map + HUD overlay
        ZStack(alignment: .top) {
            RideMapViewRepresentable(...)
                .frame(height: mapHeight)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            // Host HUD overlay
            RideHostHUDView(...)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            // Ride mode pill (top-right)
            RideModeBadgeView(...)
        }
        
        Spacer(minLength: 8)
        
        // Bottom buttons
        rideControls
            .padding(.bottom, max(proxy.safeAreaInsets.bottom, 16))
    }
}
```

**Key Changes:**
- Removed ScrollView wrapper
- Added GeometryReader for responsive sizing
- Map height: `proxy.size.height * 0.62` (adjustable)
- Increased corner radius from 20pt to 24pt for map card
- Enhanced shadow for better depth perception
- Buttons positioned at bottom with safe area padding

**Visual Impact:**
- Map fills most of the screen (similar to user's red line reference)
- Better route visibility and spatial awareness
- Cleaner, more immersive ride experience
- Host HUD and music controls remain accessible on map overlay

---

### 2. HomeView – Card Above Buttons Reorder

**File:** `Views/Home/HomeView.swift`

**Problem:**
- Primary action buttons appeared before Weekly Goal card
- Visual hierarchy didn't prioritize status/context information
- Card felt disconnected from header

**Solution:**
- Swapped order: Weekly Goal card now appears directly under "branchr" header
- Primary action buttons moved below the card
- Maintained all existing styling and functionality

**Implementation:**

**Before:**
```swift
VStack(spacing: 24) {
    headerSection
    primaryActionsSection  // Buttons first
    weeklyGoalCardSection   // Card second
}
```

**After:**
```swift
VStack(spacing: 24) {
    headerSection
    weeklyGoalCardSection   // Card first (Phase 71)
    primaryActionsSection   // Buttons second
}
```

**Key Changes:**
- `RideControlPanelView` moved above primary action buttons
- Removed duplicate `RideControlPanelView` instance
- Maintained all spacing, padding, and styling
- All button actions and card functionality unchanged

**Visual Impact:**
- Weekly Goal card appears immediately under "branchr" header
- Better visual flow: Status → Actions
- More intuitive information hierarchy
- Card feels more connected to header section

---

## Files Modified

1. **Views/Ride/RideTrackingView.swift**
   - Replaced ScrollView with GeometryReader
   - Map height now responsive (~62% of screen height)
   - Increased map corner radius to 24pt
   - Enhanced map shadow for depth
   - Buttons positioned at bottom with safe area padding
   - Removed old `mapCard` computed property (replaced with inline ZStack)

2. **Views/Home/HomeView.swift**
   - Moved `RideControlPanelView` above primary action buttons
   - Removed duplicate `RideControlPanelView` instance
   - Maintained all existing spacing and styling

---

## Technical Details

### Map Height Calculation

**Formula:** `proxy.size.height * 0.62`  
**Rationale:** ~62% of screen height provides optimal balance between:
- Route visibility (more map = better spatial awareness)
- Button accessibility (buttons remain easily tappable)
- HUD overlay space (host card doesn't obstruct too much map)

**Adjustability:** The 0.62 multiplier can be tuned (0.60-0.65 range) based on device size or user feedback.

### Layout Structure

**RideTrackingView:**
```
GeometryReader
  └─ VStack
      ├─ Grabber Handle
      ├─ ZStack (Map + HUD Overlay)
      │   ├─ RideMapViewRepresentable (62% height)
      │   ├─ RideHostHUDView (overlay)
      │   └─ RideModeBadgeView (top-right)
      ├─ Spacer
      └─ rideControls (bottom buttons)
```

**HomeView:**
```
ScrollView
  └─ VStack
      ├─ Header ("branchr" + theme toggle)
      ├─ RideControlPanelView (Phase 71: moved up)
      └─ Primary Action Buttons (Phase 71: moved down)
```

---

## Constraints & Safety

✅ **No Changes To:**
- SOS / Safety flows
- Firebase or ride persistence logic
- Audio session configuration
- Music controls or transport functionality
- Button actions or tap handlers
- Card styling, colors, or shadows

✅ **Layout Only:**
- All changes are purely visual/structural
- No business logic modifications
- No new dependencies or services

---

## Testing Checklist

1. **RideTrackingView:**
   - ✅ Map fills most of screen (~62% height)
   - ✅ Host HUD overlays correctly on map
   - ✅ Music controls accessible in HUD
   - ✅ Pause/End buttons visible at bottom
   - ✅ Buttons remain tappable and functional
   - ✅ Map scrolls/zooms correctly
   - ✅ Route visualization clear and visible

2. **HomeView:**
   - ✅ Weekly Goal card appears under "branchr" header
   - ✅ Primary action buttons below card
   - ✅ All button actions work correctly
   - ✅ Card styling unchanged (rainbow progress bar, stats, etc.)
   - ✅ Connection status and music controls functional

---

## Visual Summary

**Before:**
- RideTrackingView: Map 400pt fixed height, ScrollView layout
- HomeView: Buttons first, card second

**After:**
- RideTrackingView: Map ~62% of screen height, full-screen layout
- HomeView: Card first (under header), buttons second

---

## Known Limitations

- Map height multiplier (0.62) may need device-specific tuning
- Very small devices may need different height calculation
- HomeView card order change is purely visual (no functional impact)

---

## Commit

```
Phase 71 – Ride Map Height & Home Reorder
```

