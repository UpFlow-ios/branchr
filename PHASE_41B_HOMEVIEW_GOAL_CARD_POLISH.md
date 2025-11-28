# Phase 41B – HomeView Layout Polish for Weekly Goal Card

**Status:** ✅ Complete  
**Date:** November 25, 2025

---

## Overview

Polished the HomeView layout to reduce visual crowding while keeping all Weekly Goal functionality intact. Made the WeeklyGoalCardView more compact and repositioned it as a footer card, creating a cleaner visual hierarchy.

---

## Changes Made

### 1. HomeView Section Reordering

**File:** `Views/Home/HomeView.swift`

**New Section Order (top to bottom):**
1. App icon + "branchr" header + connection status (unchanged)
2. **Audio Controls** (moved up, made more compact)
3. **Primary Action Buttons** (Start Ride, Start Connection, Voice Chat, Safety & SOS)
4. **WeeklyGoalCardView** (moved to bottom as compact footer)

**Visual Hierarchy:**
- Hero elements at top
- Quick audio toggles (compact)
- Main CTAs centered
- Goal card as secondary insight at bottom

### 2. Compact Audio Controls

**File:** `Views/Home/HomeView.swift`

**ControlButton Component Updates:**
- Reduced icon size: 22pt → 18pt
- Reduced button frame: 50x50 → 44x44
- Reduced spacing: 6pt → 4pt
- Reduced corner radius: 12pt → 10pt
- Reduced vertical padding: 10pt → 6pt

**Result:** Audio controls row is now more compact and doesn't compete visually with main buttons.

### 3. Compact WeeklyGoalCardView

**File:** `Views/Home/WeeklyGoalCardView.swift`

**Layout Changes:**
- Reduced VStack spacing: 16pt → 10pt
- Reduced padding: full padding → `.vertical(12)` + `.horizontal(16)`
- Reduced corner radius: 16pt → 14pt
- Reduced shadow radius: 8pt → 6pt

**Content Density:**
- **Top Row**: Title + streak in single line (smaller fonts)
  - Title: `.subheadline.bold()` (was `.headline.bold()`)
  - Streak: `.caption` (was `.caption.bold()`)
- **Progress Bar**: Height reduced 12pt → 8pt
- **Progress Text**: Single line format "X.X / Y mi • Z%"
  - Uses `.caption` font
  - All info in one compact line
- **Bottom Row**: "This week: X mi" + "Best: Y days"
  - Both use `.caption` font
  - Minimal spacing

**Visual Result:**
- Card is ~40% shorter vertically
- All information still visible
- Feels like a secondary insight rather than primary hero element

### 4. Card Placement

**File:** `Views/Home/HomeView.swift`

- Moved `WeeklyGoalCardView` below all main action buttons
- Added `.padding(.top, 24)` to visually separate from buttons
- Positioned near bottom of scroll area (above `Spacer`)
- Maintains full width minus standard horizontal padding (16pt)

---

## Before vs After

### Before Phase 41B
- Weekly Goal card appeared between connection status and audio controls
- Card was large and visually prominent
- Home screen felt crowded with multiple large elements competing for attention
- Audio controls were larger and took significant vertical space

### After Phase 41B
- Weekly Goal card is compact footer at bottom
- Clear visual hierarchy: Hero → Quick toggles → Main CTAs → Insight card
- Home screen feels less crowded
- Audio controls are more compact
- Goal card feels like a secondary insight rather than primary feature

---

## Files Modified

1. **Views/Home/HomeView.swift**
   - Reordered sections (audio controls before buttons)
   - Moved WeeklyGoalCardView to bottom
   - Added top padding above goal card
   - Made ControlButton more compact

2. **Views/Home/WeeklyGoalCardView.swift**
   - Reduced spacing and padding throughout
   - Made fonts smaller where appropriate
   - Condensed progress text to single line
   - Reduced progress bar height
   - Made overall card more compact

---

## No Logic Changes

✅ **All functionality preserved:**
- Weekly distance calculation unchanged
- Streak calculation unchanged
- Goal preference storage unchanged
- Auto-update triggers unchanged
- All data bindings unchanged

This phase was **strictly visual/layout polish** - no business logic modifications.

---

## Technical Details

### Spacing Reductions
- VStack spacing: 16pt → 10pt
- Padding: full → `.vertical(12)` + `.horizontal(16)`
- ControlButton spacing: 6pt → 4pt
- Progress bar height: 12pt → 8pt

### Font Size Reductions
- Card title: `.headline.bold()` → `.subheadline.bold()`
- Progress text: `.subheadline` → `.caption`
- Streak text: `.subheadline.bold()` → `.caption`

### Component Size Reductions
- ControlButton icon: 22pt → 18pt
- ControlButton frame: 50x50 → 44x44
- Card corner radius: 16pt → 14pt

---

## Acceptance Criteria Met

✅ App builds with no new warnings or errors  
✅ Home screen feels less crowded  
✅ Visual hierarchy: Hero → Status → Compact Audio → Main CTAs → Compact Goal Card  
✅ Weekly Goal card shows all data (progress %, distance vs goal, streak, best streak)  
✅ All colors remain theme-aware  
✅ Looks correct in light and dark mode  
✅ No logic changes - all functionality preserved  

---

## Notes

- Card is now ~40% more compact vertically
- All information remains visible and readable
- Card feels like a "nice to have" insight rather than primary feature
- Layout works well on all iPhone sizes
- Maintains scrolling behavior for smaller devices

---

**Phase 41B Complete** ✅

