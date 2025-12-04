# Branchr TestFlight Readiness – v2 Roadmap

**Date:** December 3, 2025  
**Status:** ✅ **READY FOR TESTFLIGHT** (with known limitations documented)

---

## Executive Summary

Branchr is **functionally ready** for TestFlight submission with the following status:
- ✅ **Core functionality:** All primary features working
- ✅ **Firebase & Auth:** Properly configured and wired
- ✅ **Navigation:** Clean 4-tab structure (Home, Calendar, Profile, Settings)
- ✅ **Legal content:** Complete Terms, Privacy, EULA, Safety Disclaimer
- ⚠️ **Settings wiring:** Some toggles marked TODO for future implementation
- ⚠️ **Background location:** Intentionally disabled (documented in Info.plist)

---

## 1. Entry Points & Navigation ✅

### Status: **CORRECT**

**Root App Structure:**
- `branchrApp.swift` is the `@main` entry point
- `BranchrAppRoot` is the root view with 4-tab `TabView`:
  1. **Home** (tab 0) - `HomeView`
  2. **Calendar** (tab 1) - `RideCalendarView`
  3. **Profile** (tab 2) - `ProfileView`
  4. **Settings** (tab 3) - `SettingsView`

**No duplicate or unused root views found.**

---

## 2. Firebase & Auth Wiring ✅

### Status: **CORRECT**

**Firebase Configuration:**
- ✅ `FirebaseApp.configure()` called in `branchrApp.init()`
- ✅ Guarded with `if FirebaseApp.app() == nil` to prevent double-configuration
- ✅ Anonymous sign-in with retry logic in `signInAnonymouslyWithGuard()`

**Auth Error Handling:**
- ✅ Errors logged with `localizedDescription` in `branchrApp.swift`
- ✅ Presence updates only occur when `Auth.auth().currentUser != nil` (fixed in this audit)

**Issues Fixed:**
- ✅ `PresenceManager.setOnline()` now checks for signed-in user before updating
- ✅ `FirebaseService.setUserOnlineStatus()` already had guard (no changes needed)

---

## 3. Presence / Online Status ✅

### Status: **FIXED**

**Before Audit:**
- `PresenceManager.setOnline()` was calling `FirebaseService.setUserOnlineStatus()` without checking for user
- This caused console warnings: "Cannot set online status - no user signed in"

**After Fix:**
- ✅ `PresenceManager.setOnline()` now checks `Auth.auth().currentUser != nil` before updating
- ✅ All presence updates are guarded in:
  - `branchrApp.swift` (`.onAppear`, `.onDisappear`, `.onChange(of: scenePhase)`)
  - `PresenceManager.setOnline()`
  - `FirebaseService.setUserOnlineStatus()`

**UI Integration:**
- ✅ `ProfileView` shows online status (green ring around avatar)
- ✅ `RideHostHUDView` shows online status
- ✅ `ProfileTabIconView` shows online status in tab bar

---

## 4. SettingsView Wiring ⚠️

### Status: **PARTIALLY WIRED** (with clear TODOs)

#### ✅ **Fully Wired:**

1. **Account & Profile:**
   - ✅ Profile → `EditProfileView` (wired)
   - ✅ Sign Out → `AuthService.signOut()` (wired)
   - ⚠️ Delete Account → Shows alert, marked TODO (not yet implemented)

2. **Ride & Safety:**
   - ✅ Safety & SOS Settings → `SOSView` (wired)
   - ✅ Voice safety alerts → **WIRED** to `VoiceFeedbackService.speak(isSafetyAlert: true)`

3. **Appearance:**
   - ✅ Appearance mode → **WIRED** to `ThemeManager.setTheme()` (fixed in this audit)

4. **Data & Privacy:**
   - ✅ Clear local cache → `RideDataManager.clearLocalCache()` (wired)
   - ✅ Reset preferences → `UserPreferenceManager.resetToDefaults()` (wired)

5. **Support:**
   - ✅ Help & FAQ → `HelpFAQView` (wired)
   - ✅ Contact Support → `mailto:` links (wired)

6. **About & Legal:**
   - ✅ All legal text buttons → `LegalTextView` sheets (wired)

#### ⚠️ **Marked TODO (Future Implementation):**

1. **Ride & Safety:**
   - ⚠️ `autoPauseWhenStopped` - TODO comment added in `RideSessionManager.locationManager(_:didUpdateLocations:)`
   - **Status:** Stored in `@AppStorage`, but not yet read by ride tracking logic
   - **Future:** Implement timer-based auto-pause when speed < 0.5 m/s for 10+ seconds

2. **Notifications:**
   - ⚠️ `rideReminders` - TODO comment added
   - ⚠️ `weeklySummary` - TODO comment added
   - ⚠️ `friendActivity` - TODO comment added
   - **Status:** Stored in `@AppStorage`, but no notification scheduler yet
   - **Future:** Implement local notification scheduling based on these flags

3. **Audio & Voice:**
   - ⚠️ `voiceAnnouncements` - TODO comment added
   - ⚠️ `djModeEnabled` - TODO comment added
   - ⚠️ `allowVoiceChatWhileRiding` - TODO comment added
   - **Status:** Stored in `@AppStorage`, but not yet read by services
   - **Future:** Wire to `VoiceFeedbackService`, `MusicSyncService`, `VoiceChatService`

**All unwired toggles have clear TODO comments explaining what they will control.**

---

## 5. Legal Text ✅

### Status: **COMPLETE**

**All legal content is production-ready:**

1. **Terms of Use** - 13 sections covering:
   - Eligibility, safe riding guidelines, account responsibility
   - License terms, prohibited uses, ride data & analytics
   - Third-party services, medical advice disclaimer
   - Termination, warranties, liability limitations

2. **Privacy Policy** - 11 sections covering:
   - Information collection (account, ride, device, usage, diagnostics)
   - How information is used
   - Legal bases, data sharing (no selling of data)
   - Data retention, user choices, security

3. **End User License Agreement (EULA)** - 9 sections covering:
   - License grant, ownership, restrictions
   - Third-party terms, updates
   - Disclaimer and limitation of liability
   - Termination, governing law

4. **Safety Disclaimer** - 6 sections covering:
   - No guarantee of safety
   - Road focus guidelines
   - Audio/music/voice chat safety
   - Emergency procedures
   - Health & fitness disclaimers
   - User responsibility

**All content uses dynamic constants:**
- `appName` = "Branchr"
- `companyName` = "Branchr Labs"
- `legalEmail` = "support@branchr.app"
- `legalLastUpdated` = "December 3, 2025"

**Note:** Content is professional and comprehensive, but should be reviewed by a lawyer before App Store release.

---

## 6. Background Location Behavior ✅

### Status: **INTENTIONALLY DISABLED** (documented)

**Info.plist Configuration:**
- ✅ `UIBackgroundModes` includes: `audio`, `remote-notification`, `fetch`, `bluetooth-peripheral`
- ⚠️ `location` is **commented out** with clear TODO instructions

**Code Behavior:**
- ✅ `RideSessionManager.hasBackgroundLocationCapability()` checks for `location` in `UIBackgroundModes`
- ✅ `RideSessionManager.configureBackgroundLocationUpdates()` only enables background location if:
  1. `location` is in `UIBackgroundModes` (currently false)
  2. Authorization status is `.authorizedAlways` (requires user permission)
- ✅ Log message: "UIBackgroundModes does not contain 'location'; background updates disabled" is **intentional**

**To Enable Background Location (Future):**
1. Uncomment `<string>location</string>` in `Info.plist`
2. Update `NSLocationAlwaysAndWhenInUseUsageDescription` if needed
3. Test background location behavior thoroughly
4. Ensure battery impact is acceptable

**Current State:** App works correctly with foreground-only location tracking. Background location is a future enhancement.

---

## 7. Dead Code & Unused Views ✅

### Status: **CLEANED UP**

**Legacy Views (Still Used):**
- ✅ `LegacyRideSummaryView.swift` - **USED** by `RideHistoryView` and `RideMapView` for saved rides
  - Added comment clarifying it's not unused

**Potentially Unused Views:**
- ⚠️ `RideHUDView.swift` - Referenced in `GroupRideView.swift` (line 128)
  - **Status:** Still used, but may be redundant with `RideHostHUDView`
  - **Recommendation:** Review if `GroupRideView` should use `RideHostHUDView` instead

**No duplicate Home/Settings/Profile views found.**

---

## 8. Known Limitations & TODOs

### Critical (Must Fix Before App Store):
- ⚠️ **Account Deletion:** Not yet implemented (shows alert only)
  - **Action Required:** Implement account deletion in `AuthService` and `FirebaseService`

### Non-Critical (Can Ship in TestFlight):
- ⚠️ **Auto-pause when stopped:** Setting exists but not wired
- ⚠️ **Notification toggles:** Settings exist but no scheduler yet
- ⚠️ **Audio/Voice toggles:** Settings exist but not all wired
- ⚠️ **Background location:** Intentionally disabled

### Future Enhancements:
- Background location tracking
- Notification scheduling system
- Full audio/voice preference wiring

---

## 9. Build Status ✅

**Last Build:** ✅ **SUCCEEDED**

**Files Modified in This Audit:**
1. `Services/PresenceManager.swift` - Added user check before setting online
2. `Services/RideSessionManager.swift` - Added TODO for auto-pause wiring
3. `Services/VoiceFeedbackService.swift` - Added `isSafetyAlert` parameter
4. `Views/Settings/SettingsView.swift` - Added TODO comments, fixed appearance mode wiring
5. `branchr/Info.plist` - Added background location TODO comment
6. `Views/Ride/LegacyRideSummaryView.swift` - Added usage clarification comment

**No build errors introduced.**

---

## 10. TestFlight Readiness Checklist

### ✅ Ready:
- [x] Firebase configured correctly
- [x] Auth flow working (anonymous sign-in)
- [x] Presence/online status working (no errors)
- [x] Navigation structure clean (4 tabs)
- [x] Legal content complete
- [x] Settings screen functional (with clear TODOs)
- [x] No critical crashes or errors
- [x] Build succeeds

### ⚠️ Known Issues (Non-Blocking):
- [ ] Account deletion not implemented (shows alert only)
- [ ] Some settings toggles not wired (marked TODO)
- [ ] Background location disabled (intentional)

### 📋 Pre-App Store Checklist:
- [ ] Lawyer review of legal content
- [ ] Implement account deletion
- [ ] Test all Settings toggles that are wired
- [ ] Consider enabling background location (if needed)
- [ ] App Store metadata (screenshots, descriptions, keywords)
- [ ] Privacy policy URL (if hosting externally)

---

## Conclusion

**Branchr is READY for TestFlight submission.**

The app is functionally complete with:
- ✅ All core features working
- ✅ Firebase & Auth properly configured
- ✅ Clean navigation structure
- ✅ Complete legal content
- ✅ Settings screen with clear TODOs for future features

**Recommendation:** Submit to TestFlight now, then address account deletion and optional feature wiring before App Store release.

---

## Phase Mapping

This audit report maps to the Branchr v2 Roadmap phases as follows:

- **Phase 01 – Foundation & Firebase:** Entry points, navigation, Firebase configuration, anonymous auth, presence basics (Sections 1, 2, 3)
- **Phase 02 – Ride Tracking & Maps:** Ride tracking, maps, location services, background location decision (Section 6)
- **Phase 03 – Music & Voice Chat:** Music integration, voice chat, audio session management (not detailed in this audit, but covered in Phase 03 docs)
- **Phase 04 – Social / Profile / Presence:** Profile system, online indicators, presence sync (Section 3)
- **Phase 05 – Safety, Settings & Legal:** Settings wiring, legal content, safety features (Sections 4, 5)
- **Phase 06 – TestFlight & App Store:** Build status, readiness checklist, account deletion requirement (Sections 8, 9, 10)

**Key TODOs from this audit:**
- Account deletion (Phase 01/06) – Critical before App Store
- Auto-pause when stopped (Phase 02) – Non-critical
- Notification toggles wiring (Phase 05) – Non-critical
- Audio/Voice toggles wiring (Phase 03/05) – Non-critical
- Background location decision (Phase 02/06) – Intentionally deferred

---

**Audit Completed:** December 3, 2025  
**Next Steps:** TestFlight submission → User testing → Address TODOs → App Store submission

