# Branchr – Social Cycling Community  + Symotainuous Chat + Music Sharing+ Live Voice Chat + Live DJ Audio (iOS)

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-18.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Modern-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![MusicKit](https://img.shields.io/badge/MusicKit-Apple%20Music-purple.svg)](https://developer.apple.com/musickit/)
[![AVFoundation](https://img.shields.io/badge/AVFoundation-Audio-yellow.svg)](https://developer.apple.com/av-foundation/)
[![Multipeer](https://img.shields.io/badge/MultipeerConnectivity-Nearby%20Groups-pink.svg)](https://developer.apple.com/documentation/multipeerconnectivity)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey.svg)](#license)

Branchr is a SwiftUI iOS app that powers group rides with live voice chat, DJ‑style Apple Music playback, and privacy‑first collaboration. Built with AVFoundation, MusicKit, MultipeerConnectivity, and a unified theme system.

---

## Highlights
- Real‑time voice chat + adaptive music ducking
- Apple Music playback (MusicKit developer JWT + user auth)
- SwiftUI architecture with unified theme and modular views
- Nearby groups via MultipeerConnectivity
- Privacy‑first: microphone, speech, location, Bluetooth, motion

---

## Project Structure
```
branchr/
├── App/
├── Services/
│   ├── AudioManager.swift
│   ├── MusicKitService.swift
│   ├── VoiceChatService.swift
│   └── …
├── Views/
│   ├── Home/
│   ├── Ride/
│   └── DJ/
├── Resources/
│   └── AuthKey_S8S2CSHCZ7.p8   (NOT COMMITTED – local only)
├── branchr/branchr.entitlements
├── branchrApp.swift
└── branchr.xcodeproj
```

---

## Requirements
- Xcode 16+
- iOS 18 SDK (device builds on iOS 17+)
- Apple Developer account (Team ID: 69Y49KN8KD)

---

## Apple Music (MusicKit) Setup
1) Enable MusicKit on the App ID `com.joedormond.branchr2025` (MusicKit, App Groups, Sign in with Apple, Push, iCloud/CloudKit)
2) Create/confirm key: Key ID `S8S2CSHCZ7`; download `AuthKey_S8S2CSHCZ7.p8`
3) Place key at `branchr/Resources/AuthKey_S8S2CSHCZ7.p8` and add to the `branchr` target (do NOT commit)
4) Service config (`Services/MusicKitService.swift`):
```
keyID = "S8S2CSHCZ7"
teamID = "69Y49KN8KD"
mediaIdentifier = "69Y49KN8KD.media.com.joedormond.branchr2025"
privateKeyFile = "AuthKey_S8S2CSHCZ7.p8"
```

---

## Entitlements
- `com.apple.developer.music-user-token` = true
- `com.apple.developer.music.subscription-service` = true
- `com.apple.security.application-groups` = [ `group.com.joedormond.branchr2025` ]
- `aps-environment` = development
- `com.apple.developer.applesignin` = Default
- `com.apple.developer.icloud-services` = CloudKit

---

## Signing & Profiles
- Bundle ID: `com.joedormond.branchr2025`
- Team ID: `69Y49KN8KD`
- Provisioning Profile: `Branchr Dev Profile 2025 (Final)`
- Certificate: `Apple Development: Joseph Dormond`

If device build fails with entitlement errors:
- Re-enable MusicKit + App Groups on the App ID
- Recreate the provisioning profile (iOS App Development)
- Select the development certificate + device
- Download the profile, or Xcode → Settings → Accounts → Download Manual Profiles

---

## Build & Run
1) Clean (optional): `rm -rf ~/Library/Developer/Xcode/DerivedData`
2) Simulator: `xcodebuild -project branchr.xcodeproj -scheme branchr -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
3) Device: Connect iPhone → select device → Cmd+R

---

## Security
- Never commit `.p8`, `.p12`, or `.mobileprovision`
- Keep repository private until launch

---

## GitHub
Use the same GitHub account as StryVr, but a separate private repository (e.g., `branchr-ios`). You can later move to an organization if needed.

---

## License
Proprietary. All rights reserved. (Update if you choose OSS.)
