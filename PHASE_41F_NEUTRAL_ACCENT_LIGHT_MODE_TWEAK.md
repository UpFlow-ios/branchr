# Phase 41F – Neutral Accent Light Mode Tweak & Weekly Goal Card Surface

**Status:** ✅ Complete  
**Date:** November 25, 2025

---

## Overview

Refined light mode appearance so Weekly Goal card and Audio Controls footer sit on a clear off-white/grey surface that floats above the yellow background. Cards now look crisp and card-like in light mode while preserving the dark mode appearance.

---

## Problem

After Phase 41E, the Weekly Goal card and Audio Controls footer used `neutralAccent` backgrounds that blended into the yellow background in light mode, making them look muddy and hard to distinguish.

---

## Solution

### 1. Added Surface Background

**File:** `Services/ThemeManager.swift`

Added `surfaceBackground` color property:
- **Light mode**: Off-white/very light grey (RGB: 0.97, 0.97, 0.98) - clearly contrasts with brand yellow
- **Dark mode**: Slightly lighter than primaryBackground (RGB: 0.12, 0.12, 0.12) - for card separation

This provides a proper "surface" that cards can sit on, creating clear visual hierarchy.

### 2. Adjusted Neutral Accent

**File:** `Services/ThemeManager.swift`

Updated `neutralAccent` for light mode:
- **Before**: Warm gray (RGB: 0.93, 0.93, 0.93)
- **After**: Cooler light grey (RGB: 0.86, 0.86, 0.90)

This cooler grey is better suited for tracks, borders, and subtle UI elements rather than full card backgrounds.

### 3. Weekly Goal Card Surface Treatment

**File:** `Views/Home/WeeklyGoalCardView.swift`

**Card Background:**
- Changed from `neutralAccent.opacity(0.6)` to `surfaceBackground`
- Uses `RoundedRectangle(cornerRadius: 16, style: .continuous)` for smoother corners

**Shadow:**
- Light mode: Subtle shadow (black.opacity(0.06), radius: 10, y: 4) for depth
- Dark mode: No shadow (clear) to maintain glassy appearance

**Progress Bar Track:**
- Uses `neutralAccent` with mode-aware opacity:
  - Dark mode: `opacity(0.7)`
  - Light mode: `opacity(0.18)` (lighter for better contrast on surface)

### 4. Audio Footer Card Surface Treatment

**File:** `Views/Home/HomeView.swift`

**Card Background:**
- Changed from `neutralAccent.opacity(0.6)` to `surfaceBackground`
- Uses same `RoundedRectangle(cornerRadius: 16, style: .continuous)` style

**Shadow:**
- Same shadow treatment as Weekly Goal card
- Light mode: Subtle shadow for depth
- Dark mode: No shadow

---

## Before vs After

### Before Phase 41F (Light Mode)
- Cards used `neutralAccent.opacity(0.6)` which blended into yellow background
- Cards looked muddy and hard to distinguish
- No clear visual separation from primary background
- Progress bar track opacity was fixed

### After Phase 41F (Light Mode)
- Cards use `surfaceBackground` (off-white) that clearly floats above yellow
- Cards look crisp and card-like with proper depth
- Clear visual hierarchy with shadow for separation
- Progress bar track uses mode-aware opacity for better contrast

### Dark Mode
- Appearance preserved or slightly improved
- Cards still use dark glassy appearance
- No shadows in dark mode
- Progress bar track uses appropriate opacity

---

## Files Modified

1. **Services/ThemeManager.swift**
   - Added `surfaceBackground` property (light/dark mode aware)
   - Updated `neutralAccent` light mode value to cooler grey

2. **Views/Home/WeeklyGoalCardView.swift**
   - Card background: `neutralAccent.opacity(0.6)` → `surfaceBackground`
   - Added mode-aware shadow (light mode only)
   - Progress bar track: mode-aware opacity (0.7 dark, 0.18 light)

3. **Views/Home/HomeView.swift**
   - Audio footer background: `neutralAccent.opacity(0.6)` → `surfaceBackground`
   - Added mode-aware shadow (light mode only)

---

## No Behavior Changes

✅ **All functionality preserved:**
- Weekly distance calculation unchanged
- Streak calculation unchanged
- Goal preference storage unchanged
- Auto-update triggers unchanged
- All data bindings unchanged
- Progress calculation logic unchanged
- Audio control logic unchanged
- Rainbow gradient progress bar unchanged

This phase was **strictly visual polish** - no business logic modifications.

---

## Technical Details

### Surface Background
- Light mode: RGB(0.97, 0.97, 0.98) - off-white/very light grey
- Dark mode: RGB(0.12, 0.12, 0.12) - slightly lighter than black
- Provides clear surface for cards to sit on

### Neutral Accent (Updated)
- Light mode: RGB(0.86, 0.86, 0.90) - cooler light grey
- Dark mode: RGB(0.18, 0.18, 0.18) - unchanged
- Used for tracks, borders, subtle UI elements

### Shadow Treatment
- Light mode: `Color.black.opacity(0.06)`, radius: 10, y: 4
- Dark mode: `.clear` (no shadow)
- Creates depth and separation in light mode

### Progress Bar Track Opacity
- Dark mode: `neutralAccent.opacity(0.7)`
- Light mode: `neutralAccent.opacity(0.18)`
- Mode-aware for optimal contrast

---

## Acceptance Criteria Met

✅ Weekly Goal card looks crisp on yellow in light mode  
✅ Audio footer looks crisp on yellow in light mode  
✅ Cards clearly float above background with proper depth  
✅ Dark mode appearance preserved  
✅ Rainbow gradient progress bar unchanged  
✅ All functionality preserved  
✅ App builds successfully with no new warnings or errors  

---

## Notes

- Surface background provides clear visual hierarchy in light mode
- Shadow adds depth without being heavy
- Mode-aware opacity ensures optimal contrast in both themes
- Cards now feel properly "card-like" rather than blending into background
- Dark mode maintains glassy, modern appearance

---

**Phase 41F Complete** ✅

