# Phase 40 – Calendar Settings & Apple Calendar Selection

**Status:** ✅ Complete  
**Date:** November 23, 2025

---

## Overview

Added a comprehensive Calendar Settings screen that allows users to manage calendar permissions and select which Apple Calendar Branchr writes ride events into. This provides a clean, user-facing way to control calendar integration without breaking existing ride saving functionality.

---

## Features Implemented

### 1. Calendar Permission Status Helpers

**File:** `Services/RideCalendarService.swift`

Added public API for checking and requesting calendar access:

- **`calendarAuthorizationStatus`** property
  - Returns current `EKAuthorizationStatus` for EventKit events
  - Wraps `EKEventStore.authorizationStatus(for: .event)`

- **`requestCalendarAccess(completion:)`** method
  - Requests calendar permission only when user explicitly taps a button
  - Handles all authorization states (notDetermined, authorized, denied, restricted)
  - Calls completion handler on main thread

### 2. Preferred Calendar Persistence

**File:** `Services/UserPreferenceManager.swift`

- **`preferredCalendarIdentifier`** property
  - Stores the selected calendar's identifier in UserDefaults
  - Published property for reactive UI updates
  - Included in `resetToDefaults()` method

### 3. Calendar Resolution Logic

**File:** `Services/RideCalendarService.swift`

- **`availableWritableCalendars()`** method
  - Returns only calendars where `allowsContentModifications == true`
  - Filters out read-only calendars
  - Returns empty array if not authorized

- **`resolveTargetCalendar()`** method
  - Uses preferred calendar if set and still available
  - Falls back to default calendar for new events
  - Last resort: first writable calendar
  - **Handles deleted calendars gracefully**: Clears invalid preference if stored calendar no longer exists

### 4. Calendar Settings UI

**File:** `Views/Calendar/CalendarSettingsView.swift` (NEW)

Complete settings screen with:

#### Status Section
- Shows current authorization status with icon:
  - ✅ Green checkmark for "Access: Allowed"
  - ❌ Red X for "Access: Denied"
  - ❓ Question mark for "Access: Not Determined"
- Theme-aware styling using `ThemeManager`

#### Permission Action Section
- **Not Determined**: Shows "Allow Calendar Access" button
  - Requests permission on tap
  - Shows loading state during request
  - Updates UI on completion

- **Denied**: Shows instructions and "Open Settings" button
  - Explains how to enable access in iOS Settings
  - Opens Settings app when tapped
  - Uses alert for confirmation

- **Authorized**: Shows confirmation message

#### Calendar Picker Section
- Only visible when authorization is `.authorized`
- Lists all writable calendars with:
  - Calendar color indicator (colored circle)
  - Calendar title
  - Source name (e.g., "iCloud", "Google")
  - Checkmark for selected calendar
- Tapping a calendar saves selection to `UserPreferenceManager`
- Handles empty state (no writable calendars)

#### Info Footer
- Explains what calendar export does
- Mentions future enhancements

### 5. Settings Integration

**File:** `Views/Settings/SettingsView.swift`

- Added "Calendar & Export" section card
- Navigation button opens `CalendarSettingsView` as a sheet
- Consistent styling with other settings sections

### 6. Ride Saving Integration

**File:** `Services/RideCalendarService.swift`

Updated `saveRideToCalendar()` method:

- **Phase 40 Changes**:
  - No longer automatically requests permission (only saves if already authorized)
  - Checks authorization status before proceeding
  - Uses `resolveTargetCalendar()` to get target calendar
  - Logs clear messages when skipping save:
    - `⚠️ Calendar: skipping save – no permission (status: X)`
    - `⚠️ Calendar: skipping save – no calendar selection`

- **Updated `createEvent()` method**:
  - Now accepts explicit `calendar` parameter
  - Removed fallback logic (handled by `resolveTargetCalendar()`)
  - Uses provided calendar directly

---

## Technical Details

### Calendar Selection Flow

1. User opens Calendar Settings from Settings screen
2. View checks current authorization status
3. If not authorized:
   - Shows permission request button (if notDetermined)
   - Shows Settings link (if denied)
4. If authorized:
   - Loads available writable calendars
   - Shows current selection (from preferences or first available)
   - User can select different calendar
   - Selection persists to `UserPreferenceManager`

### Ride Saving Flow

1. When ride ends, `saveRideToCalendar()` is called
2. Checks authorization status
3. If not authorized → logs and returns false (no alert)
4. If authorized → calls `resolveTargetCalendar()`
5. If no calendar resolved → logs and returns false
6. If calendar resolved → creates event with that calendar

### Deleted Calendar Handling

If user deletes a calendar that was previously selected:

1. `resolveTargetCalendar()` attempts to load calendar by identifier
2. If calendar not found → clears `preferredCalendarIdentifier`
3. Falls back to default calendar
4. User can re-select a calendar in Settings

---

## Files Modified

1. **Services/RideCalendarService.swift**
   - Added `calendarAuthorizationStatus` property
   - Added `requestCalendarAccess(completion:)` method
   - Added `availableWritableCalendars()` method
   - Added `resolveTargetCalendar()` method
   - Updated `saveRideToCalendar()` to use new resolution logic
   - Updated `createEvent()` to accept explicit calendar parameter

2. **Services/UserPreferenceManager.swift**
   - Added `preferredCalendarIdentifier` property
   - Added initialization from UserDefaults
   - Added to `resetToDefaults()` method

3. **Views/Calendar/CalendarSettingsView.swift** (NEW)
   - Complete calendar settings UI
   - Status display, permission actions, calendar picker
   - Theme-aware styling

4. **Views/Settings/SettingsView.swift**
   - Added "Calendar & Export" section
   - Added sheet presentation for CalendarSettingsView

---

## User Experience

### Before Phase 40
- Calendar permission was requested automatically when saving rides
- No way to see permission status
- No way to choose which calendar to use
- Used default calendar or first available

### After Phase 40
- Clear permission status display
- User controls when to request permission
- Can select specific calendar for ride events
- Settings screen provides dedicated calendar management
- Graceful handling of denied permissions

---

## Safety & Non-Regression

✅ **No breaking changes**:
- Existing ride saving logic preserved
- Internal Branchr calendar logic unchanged
- Ride metrics calculation unchanged
- Voice Coach logic unchanged
- Core Location safety patterns unchanged

✅ **Graceful degradation**:
- When permission denied → ride saves to internal history only
- When no calendar selected → uses system default
- When calendar deleted → falls back to default
- No alerts or blocking UI during ride saving

---

## Testing Checklist

- [x] Build succeeds for simulator and device
- [x] Calendar Settings screen appears in Settings
- [x] Permission status displays correctly for all states
- [x] "Allow Calendar Access" button requests permission
- [x] "Open Settings" button opens iOS Settings app
- [x] Calendar list shows when authorized
- [x] Calendar selection persists across app launches
- [x] Selected calendar is used when saving rides
- [x] Deleted calendar handling works correctly
- [x] All UI is theme-aware (light/dark mode)
- [x] No new warnings introduced

---

## Limitations & Future Enhancements

### Current Limitations
- Does not create a "Branchr Rides" calendar automatically (uses existing calendars)
- Calendar list does not refresh automatically if calendars change outside app
- No calendar event preview before saving

### Future Enhancements (Not in Phase 40)
- Auto-create "Branchr Rides" calendar if none exists
- Richer calendar event details (route preview, photos)
- Calendar sync status indicator
- Export ride history to calendar in bulk

---

## Acceptance Criteria Met

✅ Build succeeds for simulator and device  
✅ No new warnings beyond existing Swift 6 concurrency warnings  
✅ Calendar Settings screen shows status correctly  
✅ Can request access when `.notDetermined`  
✅ Shows instructions + "Open Settings" when `.denied`  
✅ Shows calendar list + selection UI when `.authorized`  
✅ Selecting calendar persists and is used for future rides  
✅ When access denied, ride saving works normally (skips calendar export)  
✅ All new UI is fully theme-aware  
✅ No regression in existing ride saving behavior  

---

## Notes

- Calendar permission is only requested when user explicitly taps the button in Settings
- The app does not automatically request permission during ride saving (Phase 40 change)
- All calendar operations are safe and handle edge cases (deleted calendars, no calendars, etc.)
- Settings UI follows existing Branchr design patterns (SectionCard, theme colors, etc.)

---

**Phase 40 Complete** ✅

