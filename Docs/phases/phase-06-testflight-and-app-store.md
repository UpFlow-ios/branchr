# Phase 06 – TestFlight & App Store

## Goal

Prepare Branchr for TestFlight beta testing and eventual App Store submission. This phase includes build verification, TestFlight readiness audit, legal review coordination, App Store asset preparation, and final polish items.

## Key Features in This Phase

- TestFlight readiness audit (`Docs/TESTFLIGHT_AUDIT_REPORT.md`)
- Build verification
- App Store metadata preparation
- Legal review coordination
- Background location decision
- Account deletion implementation (required before public release)

## Checklist

### ✅ Completed

- [x] TestFlight audit completed – Comprehensive readiness report in `Docs/TESTFLIGHT_AUDIT_REPORT.md`
- [x] Build succeeds – Clean build with no errors (warnings are non-blocking)
- [x] Firebase configured – Proper initialization in `branchrApp.swift`
- [x] Auth flow working – Anonymous sign-in with error handling
- [x] Navigation structure clean – 4-tab structure verified
- [x] Legal content complete – Terms, Privacy, EULA, Safety Disclaimer in `Views/Settings/SettingsView.swift`
- [x] Presence system fixed – No more "Cannot set online status" warnings
- [x] Settings screen functional – All sections implemented with clear TODOs
- [x] Background location documented – Decision to disable documented in `branchr/Info.plist` with TODO comment

### ⬜ Planned / TODO

- [ ] Account deletion implementation – **CRITICAL** – Must be implemented before App Store release in `Services/AuthService.swift` and `Services/FirebaseService.swift`
- [ ] Legal review – Have lawyer review all legal text in `Views/Settings/SettingsView.swift` before submission
- [ ] App Store screenshots – Create screenshots for all required device sizes
- [ ] App Store description – Write compelling description highlighting unique features
- [ ] App Store keywords – Research and optimize keywords for discoverability
- [ ] Privacy policy URL – Host privacy policy externally if required by App Store
- [ ] TestFlight beta testing – Recruit beta testers and collect feedback
- [ ] Background location decision – Finalize whether to enable background location (currently disabled)
- [ ] Settings toggles wiring – Complete wiring of notification and audio toggles before public release
- [ ] Performance optimization – Final pass on launch time, memory usage, battery impact
- [ ] Crash reporting – Set up Firebase Crashlytics for production monitoring
- [ ] Analytics events – Add key event tracking for user behavior analysis

## Notes / Links

- **TestFlight readiness:** App is functionally ready – see `Docs/TESTFLIGHT_AUDIT_REPORT.md` for full details
- **Background location:** Intentionally disabled in `Info.plist` – decision documented with TODO for future consideration
- **Account deletion:** Non-blocking for TestFlight but **required** before App Store public release
- **Legal content:** Professional and complete but needs lawyer review before submission
- **Build warnings:** All warnings are non-blocking (Swift 6 compatibility, deprecations) – can be addressed post-launch

