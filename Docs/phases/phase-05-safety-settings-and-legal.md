# Phase 05 – Safety, Settings & Legal

## Goal

Implement comprehensive settings screen, safety features (SOS system), legal documentation (Terms, Privacy, EULA, Safety Disclaimer), and data/privacy controls. This phase ensures the app is production-ready with proper legal coverage and user controls.

## Key Features in This Phase

- Settings view (`Views/Settings/SettingsView.swift`)
- Safety controls (`Views/Settings/SafetyControlView.swift`)
- SOS system (`Views/Safety/SOSView.swift`, `Services/SOSManager.swift`)
- Voice settings (`Views/Voice/VoiceSettingsView.swift`)
- Calendar settings (`Views/Calendar/CalendarSettingsView.swift`)
- Legal text views (`Views/Settings/SettingsView.swift` with `LegalTextView`)
- Data management (`Services/RideDataManager.swift`)

## Checklist

### ✅ Completed

- [x] Settings screen structure – Organized sections in `Views/Settings/SettingsView.swift`
- [x] Account & Profile section – Profile edit, sign out, delete account (alert) in `Views/Settings/SettingsView.swift`
- [x] Ride & Safety section – Auto-pause toggle, voice safety alerts toggle, Safety & SOS settings in `Views/Settings/SettingsView.swift`
- [x] Notifications section – Ride reminders, weekly summary, friend activity toggles in `Views/Settings/SettingsView.swift`
- [x] Audio & Voice section – Voice announcements, DJ mode, voice chat toggles in `Views/Settings/SettingsView.swift`
- [x] Appearance section – Theme picker (Light/Dark/System) wired to `Services/ThemeManager.swift`
- [x] Data & Privacy section – Clear cache, reset preferences in `Views/Settings/SettingsView.swift`
- [x] Support section – Help & FAQ, contact support in `Views/Settings/SettingsView.swift`
- [x] About & Legal section – Terms, Privacy, EULA, Safety Disclaimer in `Views/Settings/SettingsView.swift`
- [x] Legal content – Complete Terms of Use, Privacy Policy, EULA, Safety Disclaimer in `Views/Settings/SettingsView.swift`
- [x] SOS system – Emergency contacts, location sharing, message composer in `Views/Safety/SOSView.swift`
- [x] Safety settings – SOS configuration in `Views/Settings/SafetyControlView.swift`
- [x] Voice safety alerts – Wired to `Services/VoiceFeedbackService.speak(isSafetyAlert: true)`

### ⬜ Planned / TODO

- [ ] Auto-pause when stopped – Setting exists but not wired to `Services/RideSessionManager.swift` (needs speed threshold timer)
- [ ] Ride reminders notification – Setting exists but no notification scheduler implemented
- [ ] Weekly summary notification – Setting exists but no notification scheduler implemented
- [ ] Friend activity notification – Setting exists but no notification scheduler implemented
- [ ] Voice announcements toggle – Setting exists but not wired to `Services/VoiceFeedbackService.swift` or `Services/VoiceCoachService.swift`
- [ ] DJ mode toggle – Setting exists but not wired to `Services/MusicSyncService.swift`
- [ ] Voice chat while riding toggle – Setting exists but not wired to `Services/VoiceChatService.swift`
- [ ] Account deletion – Currently shows alert only, needs implementation in `Services/AuthService.swift` and `Services/FirebaseService.swift`
- [ ] Legal review – All legal text should be reviewed by lawyer before App Store release

## Notes / Links

- **Settings wiring:** Many toggles have TODO comments explaining what they will control – see `Views/Settings/SettingsView.swift`
- **Legal content:** Complete and production-ready, but should be lawyer-reviewed before App Store submission
- **SOS system:** Fully implemented in Phase 27 – see `Views/Safety/SOSView.swift` and `Services/SOSManager.swift`
- **Theme system:** Appearance mode properly wired to `ThemeManager.setTheme()` in `Views/Settings/SettingsView.swift`

