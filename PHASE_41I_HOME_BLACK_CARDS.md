# Phase 41I – Home Black Cards

**Status:** ✅ Complete  
**Date:** November 25, 2025

---

## Overview

Updated light-mode card backgrounds to use near-black surfaces that visually match the primary action buttons, creating a more cohesive and premium appearance. Dark mode remains unchanged.

---

## Changes Made

### 1. Black Surface Background for Light Mode

**File:** `Services/ThemeManager.swift`

**Updated `surfaceBackground` light mode value:**
- **Before**: RGB(0.75, 0.75, 0.78) - grey panel
- **After**: RGB(0.04, 0.04, 0.04) - near-black (~#0A0A0A)

**Dark mode:**
- Unchanged (RGB: 0.12, 0.12, 0.12)

**Result:**
- Cards now match the visual style of primary action buttons
- More cohesive design language across the Home screen
- Premium black card appearance in light mode

### 2. Enhanced Shadow for Black Cards

**Files:** `Views/Home/WeeklyGoalCardView.swift`, `Views/Home/HomeView.swift`

**Updated shadow for light mode:**
- **Before**: `Color.black.opacity(0.06)`, radius: 10, y: 4
- **After**: `Color.black.opacity(0.25)`, radius: 18, y: 8

**Dark mode:**
- Shadow remains `.clear` (no shadow)

**Result:**
- Stronger shadow provides better depth for black cards
- Cards appear to float above the yellow background
- More pronounced visual separation

### 3. Card Backgrounds

**Files:** `Views/Home/WeeklyGoalCardView.swift`, `Views/Home/HomeView.swift`

**Verified:**
- Both cards use `theme.surfaceBackground` directly (no opacity)
- Weekly Goal card: Full black surface in light mode
- Audio footer card: Full black surface in light mode
- Rainbow gradient progress bar unchanged
- Text colors remain readable (white text on black)

---

## Before vs After

### Before Phase 41I (Light Mode)
- Cards used grey surface (RGB: 0.75, 0.75, 0.78)
- Cards looked like separate grey panels
- Less visual cohesion with action buttons
- Subtle shadow (opacity: 0.06, radius: 10)

### After Phase 41I (Light Mode)
- Cards use near-black surface (RGB: 0.04, 0.04, 0.04)
- Cards visually match primary action buttons
- More cohesive, premium design language
- Stronger shadow (opacity: 0.25, radius: 18) for better depth

### Dark Mode
- Appearance unchanged
- Cards still use dark glassy appearance
- No visual regression

---

## Files Modified

1. **Services/ThemeManager.swift**
   - Updated `surfaceBackground` light mode value from RGB(0.75, 0.75, 0.78) to RGB(0.04, 0.04, 0.04)
   - Dark mode value unchanged
   - Cards automatically inherit the black color

2. **Views/Home/WeeklyGoalCardView.swift**
   - Updated shadow: opacity 0.06 → 0.25, radius 10 → 18, y 4 → 8
   - Card already uses `theme.surfaceBackground` directly (no opacity)

3. **Views/Home/HomeView.swift**
   - Updated audio footer shadow: opacity 0.06 → 0.25, radius 10 → 18, y 4 → 8
   - Card already uses `theme.surfaceBackground` directly (no opacity)

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
- Text colors remain readable

This phase was **strictly visual polish** - no business logic modifications.

---

## Technical Details

### Surface Background Color
- Light mode: RGB(0.04, 0.04, 0.04) - near-black (~#0A0A0A)
- Dark mode: RGB(0.12, 0.12, 0.12) - unchanged
- Matches visual style of primary action buttons
- Provides cohesive design language

### Shadow Treatment
- Light mode: `Color.black.opacity(0.25)`, radius: 18, y: 8
- Dark mode: `.clear` (no shadow)
- Stronger shadow provides better depth for black cards
- Cards appear to float above yellow background

### Card Backgrounds
- Both cards use `theme.surfaceBackground` directly (full opacity)
- No additional opacity applied
- Black surface in light mode matches action buttons

---

## Acceptance Criteria Met

✅ Light mode cards use near-black surface (RGB: 0.04, 0.04, 0.04)  
✅ Cards visually match primary action buttons  
✅ Enhanced shadow for better depth (opacity: 0.25, radius: 18)  
✅ Cards use full opacity (no washing out)  
✅ Text remains readable on black surface  
✅ Dark mode appearance unchanged  
✅ All functionality preserved  
✅ App builds successfully with no new warnings or errors  

---

## Notes

- Black cards create more cohesive design language with action buttons
- Stronger shadow provides better visual depth and separation
- Premium appearance with consistent black surfaces
- Dark mode maintains consistent appearance
- Text colors (white) remain readable on black background

---

**Phase 41I Complete** ✅

