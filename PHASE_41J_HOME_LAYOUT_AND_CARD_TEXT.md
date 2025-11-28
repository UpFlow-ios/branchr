# Phase 41J – Home Layout & Card Text Readability

**Status:** ✅ Complete  
**Date:** November 25, 2025

---

## Overview

Reordered the Home screen layout to improve visual flow and fixed text readability on black cards in light mode. Connection status pill moved between "Start Ride Tracking" and "Start Connection", Weekly Goal card moved between "Start Connection" and "Start Voice Chat", and Audio controls footer moved between "Start Voice Chat" and "Safety & SOS" to keep all audio-related controls together. Updated text colors for clear visibility on black backgrounds.

---

## Changes Made

### 1. Home Layout Reordering

**File:** `Views/Home/HomeView.swift`

**Previous Layout Order:**
1. Header
2. Start Ride Tracking
3. Start Connection
4. Start Voice Chat
5. Safety & SOS
6. Connection Status pill
7. Weekly Goal card
8. Audio controls footer

**New Layout Order:**
1. Header (branchr + theme toggle)
2. **Start Ride Tracking**
3. **Connection Status pill** (moved here)
4. **Start Connection**
5. **Weekly Goal card** (moved here)
6. **Start Voice Chat**
7. **Audio controls footer** (moved between Start Voice Chat and Safety & SOS)
8. **Safety & SOS**

**Note:** Audio controls footer moved between "Start Voice Chat" and "Safety & SOS" to keep all audio-related controls near the voice chat action.

**Result:**
- Connection status appears immediately after primary action
- Weekly Goal card integrated into main action flow
- Audio controls footer positioned near voice chat action for logical grouping
- Better visual hierarchy with status and goal information positioned strategically
- Safety & SOS button remains as final action

### 2. Weekly Goal Card Text Colors

**File:** `Views/Home/WeeklyGoalCardView.swift`

**Updated Text Colors for Black Background:**
- **Title**: `Color.white` (was `theme.primaryText`)
- **Percent pill text**: `Color.white.opacity(0.92)` (was `theme.primaryText`)
- **Percent pill background**: `Color.white.opacity(0.12)` (was `theme.cardBackground.opacity(0.9)`)
- **Bottom row labels**: `Color.white.opacity(0.78)` (was `theme.secondaryText`)

**Text Elements Updated:**
- "🎯 Weekly Goal" title - now white
- Percent pill (e.g., "45%") - white text on semi-transparent white background
- Distance vs goal (e.g., "0.0 / 25 mi") - white with 78% opacity
- "This week: X.X mi" - white with 78% opacity
- "🔥 Streak: X • Best: Y days" - white with 78% opacity

**Unchanged:**
- Rainbow gradient progress bar (exactly as before)
- Card background (`theme.surfaceBackground`)
- Shadow logic

### 3. Audio Footer Icons & Labels

**File:** `Views/Home/HomeView.swift`

**Updated ControlButton Component:**
- **Icons**: `theme.brandYellow` (was `theme.accentColor`)
- **Labels**: `Color.white.opacity(0.9)` (was `theme.primaryText`)

**Result:**
- Icons pop with brand yellow on black background
- Labels clearly readable in white
- High contrast for all three controls (Unmuted, Music On, DJ Controls)

---

## Before vs After

### Before Phase 41J (Light Mode)
- Connection status at bottom of button stack
- Weekly Goal card at bottom before audio footer
- Text on black cards used theme colors (not optimized for black)
- Icons used accent color (not brand yellow)
- Labels used theme.primaryText (not white)

### After Phase 41J (Light Mode)
- Connection status between Start Ride Tracking and Start Connection
- Weekly Goal card between Start Connection and Start Voice Chat
- All text on black cards uses white/light colors for readability
- Icons use brand yellow for high visibility
- Labels use white for clear readability

### Dark Mode
- Appearance unchanged
- Text colors remain readable
- Layout order matches light mode

---

## Files Modified

1. **Views/Home/HomeView.swift**
   - Moved connection status pill between Start Ride Tracking and Start Connection
   - Moved Weekly Goal card between Start Connection and Start Voice Chat
   - Updated ControlButton: icons to `theme.brandYellow`, labels to `Color.white.opacity(0.9)`

2. **Views/Home/WeeklyGoalCardView.swift**
   - Updated title color to `Color.white`
   - Updated percent pill text to `Color.white.opacity(0.92)`
   - Updated percent pill background to `Color.white.opacity(0.12)`
   - Updated all bottom row labels to `Color.white.opacity(0.78)`

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

This phase was **strictly layout and visual polish** - no business logic modifications.

---

## Technical Details

### Layout Order
1. Header
2. Start Ride Tracking
3. Connection Status pill
4. Start Connection
5. Weekly Goal card
6. Start Voice Chat
7. Audio controls footer
8. Safety & SOS

### Text Colors (Light Mode on Black)
- Title: `Color.white`
- Primary text: `Color.white.opacity(0.92)`
- Secondary text: `Color.white.opacity(0.78)`
- Percent pill background: `Color.white.opacity(0.12)`

### Icon & Label Colors (Audio Footer)
- Icons: `theme.brandYellow`
- Labels: `Color.white.opacity(0.9)`

---

## Acceptance Criteria Met

✅ Connection status pill between Start Ride Tracking and Start Connection  
✅ Weekly Goal card between Start Connection and Start Voice Chat  
✅ Audio controls footer between Start Voice Chat and Safety & SOS  
✅ Layout order matches specified sequence  
✅ Weekly Goal card text clearly visible (white) on black background  
✅ Audio footer icons use brand yellow for high visibility  
✅ Audio footer labels use white for readability  
✅ Dark mode appearance unchanged  
✅ All functionality preserved  
✅ App builds successfully with no new warnings or errors  

---

## Notes

- Layout reordering improves visual flow and information hierarchy
- White text on black cards provides excellent contrast and readability
- Brand yellow icons pop on black background
- Status and goal information now integrated into main action flow
- Dark mode maintains consistent appearance

---

**Phase 41J Complete** ✅

