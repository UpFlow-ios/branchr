# Phase 01 – Foundation & Firebase

## Goal

Establish the core app architecture, navigation structure, theme system, and Firebase integration for anonymous authentication, user profiles, and real-time presence tracking. This phase provides the foundation for all subsequent features in Branchr.

## Key Features in This Phase

- App entry point and lifecycle management (`branchrApp.swift`, `App/BranchrAppRoot.swift`)
- 4-tab navigation structure (Home, Calendar, Profile, Settings)
- Theme system with light/dark mode support (`Services/ThemeManager.swift`)
- Firebase initialization and configuration
- Anonymous Firebase authentication (`Services/AuthService.swift`)
- Firebase profile service (`Services/FirebaseProfileService.swift`)
- Presence management for online/offline status (`Services/PresenceManager.swift`)
- Launch animation (`Views/Splash/LaunchAnimationView.swift`)

## Checklist

### ✅ Completed

- [x] App entry point configured – `branchrApp.swift` with `@main` struct
- [x] Firebase configured at launch – `FirebaseApp.configure()` in `branchrApp.init()` with guard to prevent double-configuration
- [x] Anonymous sign-in implemented – `signInAnonymouslyWithGuard()` with retry logic in `branchrApp.swift`
- [x] TabView navigation structure – 4 tabs (Home, Calendar, Profile, Settings) in `App/BranchrAppRoot.swift`
- [x] Theme system implemented – `Services/ThemeManager.swift` with light/dark mode, brand colors (yellow/black)
- [x] Tab bar appearance configured – Dynamic colors based on theme in `BranchrAppRoot.updateTabBarAppearance()`
- [x] Firebase service initialized – `Services/FirebaseService.swift` for Firestore and Storage
- [x] Firebase profile service – `Services/FirebaseProfileService.swift` for profile CRUD operations
- [x] Presence manager – `Services/PresenceManager.swift` tracks online/offline status (fixed to check for user before updating)
- [x] Launch animation – `Views/Splash/LaunchAnimationView.swift` shows on app start
- [x] AppDelegate configured – FCM messaging delegate setup in `branchrApp.swift`
- [x] Error handling – Auth errors logged with `localizedDescription` in `branchrApp.swift`

### ⬜ Planned / TODO

- [ ] Account deletion implementation – Currently shows alert only, needs `AuthService.deleteAccount()` and `FirebaseService.deleteUserData()` in `Services/AuthService.swift`
- [ ] Firebase security rules review – Firestore and Storage rules need production hardening (currently test mode)
- [ ] Apple ID sign-in UI – `Services/AuthService.swift` has Apple ID sign-in method but UI not yet implemented
- [ ] Profile photo upload error recovery – Add retry logic for failed uploads in `Services/FirebaseService.swift`
- [ ] Presence sync optimization – Reduce Firebase writes for presence updates (currently updates on every state change)
- [ ] Launch animation performance – Optimize animation for slower devices in `Views/Splash/LaunchAnimationView.swift`
- [ ] Firebase Analytics integration – Add event tracking for key user actions
- [ ] Crashlytics setup – Add Firebase Crashlytics for crash reporting

## Notes / Links

- **Firebase warnings:** Some deprecation warnings for iOS 17.0+ APIs in `Services/AudioMixerService.swift` and `Services/VoiceChatService.swift` – intentionally deferred
- **Presence warnings:** Fixed in audit – `PresenceManager.setOnline()` now checks for signed-in user before updating Firebase
- **Background location:** Intentionally disabled in `Info.plist` – see Phase 06 for decision
- **FCM warnings:** Main actor isolation warnings in `Services/FCMService.swift` – Swift 6 compatibility, non-blocking

