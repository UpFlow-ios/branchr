# Phase 41H – Home Card Grey Tune

**Status:** ✅ Complete  
**Date:** November 25, 2025

---

## Overview

Darkened the light-mode `surfaceBackground` color to make Weekly Goal and Audio footer cards appear as clearly grey panels (not white) against the yellow background. Verified connection status pill positioning and ensured cards use full opacity for maximum visibility.

---

## Problem

After Phase 41G, the cards still looked too light/white in light mode. The `surfaceBackground` value (RGB: 0.88, 0.88, 0.92) was too close to white, making cards blend with the yellow background rather than standing out as distinct grey panels.

---

## Solution

### 1. Darkened Surface Background for Light Mode

**File:** `Services/ThemeManager.swift`

**Updated `surfaceBackground` light mode value:**
- **Before**: RGB(0.88, 0.88, 0.92) - too light, looked white
- **After**: RGB(0.75, 0.75, 0.78) - darker neutral grey, clearly grey not white

**Dark mode:**
- Unchanged (RGB: 0.12, 0.12, 0.12)

**Result:**
- Cards now appear as clearly grey panels in light mode
- Better contrast against yellow background
- Cards no longer look washed out or white

### 2. Verified Card Backgrounds Use Full Opacity

**Files:** `Views/Home/WeeklyGoalCardView.swift`, `Views/Home/HomeView.swift`

**Verified:**
- Weekly Goal card uses `theme.surfaceBackground` directly (no opacity)
- Audio footer card uses `theme.surfaceBackground` directly (no opacity)
- Both cards use `RoundedRectangle(cornerRadius: 16, style: .continuous)`
- Shadow logic is mode-aware (light mode only)

**No changes needed** - cards were already using full opacity.

### 3. Verified Connection Status Position

**File:** `Views/Home/HomeView.swift`

**Verified:**
- Connection status pill is correctly positioned between Safety & SOS and Weekly Goal card
- Status pill has `.padding(.top, 12)` for spacing
- Weekly Goal card has `.padding(.top, 24)` for comfortable spacing

**No changes needed** - position was already correct from Phase 41G.

---

## Before vs After

### Before Phase 41H (Light Mode)
- Cards used RGB(0.88, 0.88, 0.92) - too light, looked white
- Cards blended with yellow background
- Less clear visual separation

### After Phase 41H (Light Mode)
- Cards use RGB(0.75, 0.75, 0.78) - clearly grey panels
- Cards stand out distinctly from yellow background
- Better visual hierarchy and separation

### Dark Mode
- Appearance unchanged
- Cards still use dark glassy appearance
- No visual regression

---

## Files Modified

1. **Services/ThemeManager.swift**
   - Updated `surfaceBackground` light mode value from RGB(0.88, 0.88, 0.92) to RGB(0.75, 0.75, 0.78)
   - Dark mode value unchanged
   - Cards automatically inherit the darker grey color

2. **Views/Home/WeeklyGoalCardView.swift**
   - Verified: Already uses `theme.surfaceBackground` directly without opacity
   - No changes needed

3. **Views/Home/HomeView.swift**
   - Verified: Audio footer already uses `theme.surfaceBackground` directly without opacity
   - Verified: Connection status position is correct
   - No changes needed

---

## No Behavior Changes

✅ **All functionality preserved:**
- Connection status logic unchanged
- Status pill still updates correctly (Disconnected / Connected)
- All button actions unchanged
- All bindings and services unchanged
- Weekly Goal calculations unchanged
- Audio control logic unchanged
- Rainbow gradient progress bar unchanged

This phase was **strictly visual polish** - no business logic modifications.

---

## Technical Details

### Surface Background Color
- Light mode: RGB(0.75, 0.75, 0.78) - darker neutral grey panel
- Dark mode: RGB(0.12, 0.12, 0.12) - unchanged
- Provides clear contrast with yellow background in light mode
- Cards appear as distinct grey panels, not white

### Card Backgrounds
- Both cards use `theme.surfaceBackground` directly (full opacity)
- No additional opacity applied
- Shadow logic mode-aware (light mode only)

### Layout Order (Verified)
1. Header
2. Start Ride Tracking
3. Start Connection
4. Start Voice Chat
5. Safety & SOS
6. Connection Status pill
7. Weekly Goal card
8. Audio controls footer

---

## Acceptance Criteria Met

✅ Connection status pill positioned correctly (between Safety & SOS and Weekly Goal)  
✅ Light mode cards use darker neutral grey (RGB: 0.75, 0.75, 0.78)  
✅ Cards clearly appear as grey panels, not white  
✅ Cards use full opacity (no washing out)  
✅ Better contrast against yellow background  
✅ Dark mode appearance unchanged  
✅ All functionality preserved  
✅ App builds successfully with no new warnings or errors  

---

## Notes

- Darker grey provides better visual separation from yellow background
- Cards now clearly read as distinct panels rather than blending in
- Full opacity ensures maximum visibility of grey color
- Dark mode maintains consistent appearance
- Layout works well on all device sizes

---

**Phase 41H Complete** ✅

