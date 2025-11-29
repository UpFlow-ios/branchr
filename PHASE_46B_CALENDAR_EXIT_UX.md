# Phase 46B – Calendar Exit UX

**Status:** ✅ Complete  
**Date:** November 25, 2025

---

## Overview

Added clear exit controls to the Calendar tab to improve UX:
1. **Day tap toggle** – tap the same day again to deselect and hide the ride card
2. **RideInsightsView exit control** – clear "Done" button in the leading position with haptic feedback

---

## Changes Made

### 1. Day Tap Toggle Behavior

**File:** `Views/Calendar/RideCalendarView.swift`

**Enhancement:**
- Added toggle logic to day selection
- First tap on a day with rides: selects it and shows the ride card (existing behavior)
- Second tap on the **same day**: deselects it and hides the ride card
- Tapping a **different day**: updates selection and shows that day's rides (existing behavior)

**Implementation:**
```swift
// Check if this is the same day already selected
if let currentSelected = selectedDay, calendar.isDate(day, inSameDayAs: currentSelected) {
    // Deselect: hide the card
    selectedDay = nil
    selectedSummary = nil
} else {
    // Select: show the card
    selectedDay = day
    selectedSummary = summary
}
```

**Haptics:**
- Light tap haptic on both select and deselect (same as before)

---

### 2. RideInsightsView Exit Control

**File:** `Views/Calendar/RideInsightsView.swift`

**Enhancements:**
- Moved "Done" button from trailing to **leading** position (`.topBarLeading`)
- Added explicit navigation title: "Ride Insights"
- Styled button with `theme.brandYellow` for visibility
- Added medium haptic feedback when tapping "Done"
- Button uses `.headline` font for prominence

**Before:**
- "Done" button in trailing position (less obvious)
- No haptic feedback

**After:**
- "Done" button in leading position (top-left, more obvious)
- Yellow color matching Branchr design system
- Medium haptic on tap
- Clear navigation title

**Implementation:**
```swift
.navigationTitle("Ride Insights")
.navigationBarTitleDisplayMode(.inline)
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button("Done") {
            HapticsService.shared.mediumTap()
            dismiss()
        }
        .foregroundColor(theme.brandYellow)
        .font(.headline)
    }
}
```

---

## User Experience Flow

### Calendar Day Selection
1. User taps a day with rides → ride card appears below calendar
2. User taps the same day again → ride card disappears, calendar returns to clean state
3. User taps a different day → ride card updates to show that day's rides

### Ride Insights Exit
1. User taps trend icon in calendar toolbar → RideInsightsView opens as sheet
2. User sees "Done" button in top-left (yellow, prominent)
3. User taps "Done" → medium haptic + sheet dismisses, returns to calendar

---

## Technical Details

### State Management
- `selectedDay: Date?` – toggles between `nil` (deselected) and a date (selected)
- `selectedSummary: DayRideSummary?` – cleared when deselecting
- No changes to ride data or calculations

### Presentation
- RideInsightsView presented via `.sheet(isPresented:)` from RideCalendarView
- Uses `@Environment(\.dismiss)` for sheet dismissal
- NavigationView wrapper ensures toolbar appears correctly

---

## Acceptance Criteria Check

✅ Calendar day tap toggle works:
- First tap selects day and shows card
- Second tap on same day deselects and hides card
- Tapping different day updates selection

✅ RideInsightsView has clear exit:
- "Done" button visible in top-left
- Yellow color matches design system
- Medium haptic on tap
- Sheet dismisses cleanly

✅ No regressions:
- Ride data calculations unchanged
- Calendar grid behavior unchanged
- Ride detail view still works
- No new SwiftUI warnings

---

## Files Modified

1. `Views/Calendar/RideCalendarView.swift`
   - Updated day tap handler to toggle selection
   - Added logic to check if same day is tapped again

2. `Views/Calendar/RideInsightsView.swift`
   - Moved "Done" button to leading position
   - Added navigation title
   - Added haptic feedback
   - Styled button with brand yellow

---

**Phase 46B Complete** ✅

