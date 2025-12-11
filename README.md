# Branchr

<div align="center">

**Ride. Connect. Sync.**

*Next-generation social cycling with live voice chat, synchronized music, and real-time ride tracking*

[![Swift](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-18.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Modern-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![MusicKit](https://img.shields.io/badge/MusicKit-Apple%20Music-purple.svg)](https://developer.apple.com/musickit/)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey.svg)](#license)

</div>

---

## 🌟 Overview

**Branchr** is a revolutionary iOS app that transforms group cycling into a connected, social experience. Combining Apple MusicKit, CoreBluetooth, and MapKit, Branchr enables riders to communicate, sync playlists, and track rides together in real-time.

Built with SwiftUI and modern iOS frameworks, Branchr delivers seamless peer-to-peer communication, intelligent audio mixing, and precise location tracking—all while respecting user privacy.

### Core Philosophy

> **"Ride. Connect. Sync."** — Branchr brings cyclists together through technology, creating memorable group experiences powered by Apple's best-in-class frameworks.

---

## ✨ Core Features

| Feature | Description |
|---------|-------------|
| 🎙️ **Live Voice Chat** | Real-time voice communication with nearby riders using MultipeerConnectivity |
| 🎵 **DJ Mode** | Synchronized Apple Music playback with smart audio ducking for clear voice chat |
| 🚴 **Ride Tracking** | GPS-based route recording with live statistics (distance, speed, elevation) |
| 📍 **Real-Time Location** | Share your location with group members during active rides |
| 👥 **Group Management** | Create private rides, invite friends, and manage group settings |
| 🎯 **Voice Commands** | Hands-free control with natural language processing (pause, resume, stop, status) |
| 📊 **Ride Analytics** | Detailed performance metrics and ride history with calendar view |
| 🔊 **Voice Announcements** | Real-time distance, speed, and progress updates (customizable) |
| 📳 **Haptic Feedback** | Tactile feedback for ride milestones and events |
| 💾 **Auto-Save Rides** | Automatic ride saving with Firebase sync |
| 🌈 **Rainbow Glow Effects** | Interactive buttons with animated rainbow halos on press |
| 💎 **Liquid Glass UI** | Modern iOS 18+ design with frosted glass effects and premium materials |
| 🎨 **Weekly Goal Tracking** | Beautiful progress cards with streak tracking and rainbow gradients |
| 🌙 **Dark Mode** | Beautiful dark theme optimized for all lighting conditions |
| 🔒 **Privacy First** | Granular permissions with local-first data processing |

---

## 🛠️ Tech Stack

### iOS Frameworks
- **SwiftUI** — Modern declarative UI framework
- **MusicKit** — Apple Music integration and catalog access
- **CoreBluetooth** — Nearby device discovery and communication
- **MultipeerConnectivity** — Peer-to-peer data transfer
- **MapKit** — Location services and route visualization
- **AVFoundation** — Audio recording, playback, and mixing
- **CoreLocation** — GPS tracking and location services
- **Speech** — Voice command recognition
- **Combine** — Reactive programming and state management

### Backend & Infrastructure
- **Node.js** — JWT token generation server
- **Firebase** — Authentication and real-time database (optional)
- **Foundation AI** — On-device intelligent features

### Development Tools
- **Xcode 16+** — Primary IDE
- **Swift 6.1** — Latest language features
- **iOS 18 SDK** — Modern API capabilities

---

## 📁 Project Structure

```
branchr/
├── App/
│   └── branchrApp.swift          # Main app entry point
├── Services/
│   ├── AudioManager.swift        # Audio mixing and playback
│   ├── MusicKitService.swift    # Apple Music integration (JWT + auth)
│   ├── MusicService.swift        # Playback and catalog search
│   ├── VoiceChatService.swift   # Real-time voice communication
│   ├── LocationTrackingService  # GPS tracking and route recording
│   ├── RideTrackingService.swift # Ride state management & tracking
│   ├── RideDataManager.swift    # Ride persistence & calendar data
│   ├── SpeechCommandService.swift # Voice command recognition
│   ├── VoiceFeedbackService.swift # Text-to-speech announcements
│   ├── UserPreferenceManager.swift # User settings & preferences
│   ├── PeerConnectionService     # Bluetooth/Multipeer discovery
│   └── ThemeManager.swift       # Unified design system
├── Views/
│   ├── Home/                     # Main dashboard
│   │   ├── HomeView.swift        # Main home screen with liquid glass UI
│   │   ├── RideControlPanelView.swift # Music & ride control card
│   │   └── WeeklyGoalCardView.swift   # Weekly goals with progress tracking
│   ├── Ride/                     # Ride tracking interface
│   │   ├── RideSheetView.swift   # Main ride tracking sheet
│   │   └── RideMapViewRepresentable.swift # Custom map with black polyline
│   ├── Calendar/                 # Ride history calendar view
│   │   └── RideCalendarView.swift # Calendar with ride history
│   ├── DJ/                       # Music controls and DJ mode
│   │   └── DJControlsView.swift  # DJ control panel
│   ├── Settings/                 # App configuration
│   ├── Profile/                  # User profile views
│   └── Components/               # Reusable UI components
│       └── RainbowPulseView.swift # Rainbow animation effects
├── Models/
│   ├── RideModel.swift           # Ride data structures
│   └── UserModel.swift           # User profile data
├── Utils/
│   ├── RainbowGlowModifier.swift # Rainbow glow animation effects
│   └── HapticsService.swift     # Haptic feedback management
├── Resources/
│   └── AuthKey_S8S2CSHCZ7.p8     # MusicKit private key (NOT COMMITTED)
├── backend/
│   ├── generate_musickit_jwt.js  # Node.js JWT generator
│   ├── server.js                 # Express.js token endpoint
│   └── package.json              # Node dependencies
├── branchr.entitlements          # App capabilities
├── branchr.xcodeproj             # Xcode project file
└── README.md                     # This file
```

---

## 🚀 Installation & Setup

### Prerequisites

- **Xcode 16.0+** with iOS 18 SDK
- **Apple Developer Account** (Team ID: `69Y49KN8KD`)
- **iOS 18.0+** device or simulator
- **Apple Music Subscription** (for DJ mode features)
- **Node.js 16+** (for backend JWT generation)

### Step 1: Clone Repository

```bash
git clone https://github.com/upflow-ios/branchr-ios.git
cd branchr-ios
```

### Step 2: Open in Xcode

```bash
open branchr.xcodeproj
```

### Step 3: Configure Signing

1. Select your development team in Xcode project settings
2. Ensure Bundle ID is set to: `com.joedormond.branchr2025`
3. Verify provisioning profile includes required capabilities

### Step 4: Enable Capabilities

In Xcode → Signing & Capabilities, enable:
- ✅ MusicKit
- ✅ Bluetooth
- ✅ Location Services
- ✅ Push Notifications (optional)
- ✅ iCloud / CloudKit (optional)

### Step 5: Build & Run

```bash
# Via Xcode
Cmd + R

# Via command line
xcodebuild -project branchr.xcodeproj \
  -scheme branchr \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

---

## 🎵 Apple MusicKit Integration

Branchr uses Apple's MusicKit API for seamless music integration. This requires a Developer Token (JWT) for catalog access.

### Setup MusicKit

1. **Apple Developer Portal**
   - Go to [developer.apple.com](https://developer.apple.com)
   - Navigate to **Certificates, Identifiers & Profiles** → **Keys**
   - Create a new MusicKit Key (Key ID: `S8S2CSHCZ7`)
   - Download the `.p8` private key file

2. **App ID Configuration**
   - Select App ID: `com.joedormond.branchr2025`
   - Enable **MusicKit** capability
   - Enable **App Groups** if using widgets/extensions

3. **Add Private Key to Project**
   - Place `AuthKey_S8S2CSHCZ7.p8` in `Resources/` folder
   - Add to Xcode project (uncheck "Copy items if needed")
   - ⚠️ **Never commit private keys to Git**

### Generate Developer Token (JWT)

#### Option 1: Local Generation (Development)

The `MusicKitService.swift` can generate tokens locally using the embedded `.p8` key:

```swift
await MusicKitService.shared.configureMusicKit(useBackend: false)
```

#### Option 2: Backend Server (Production)

For production, use the Node.js backend to generate tokens securely:

```bash
# Install dependencies
cd backend
npm install

# Generate JWT token
npm run generate-jwt
```

This outputs a JWT valid for 180 days. The backend server (`server.js`) provides an HTTPS endpoint to fetch tokens:

```swift
// In MusicKitService.swift
private let backendTokenURL = "https://api.branchr.app/musickit/token"

await MusicKitService.shared.configureMusicKit(useBackend: true)
```

### Request User Authorization

```swift
// Request Apple Music access
try await MusicKitService.shared.requestUserToken()

// Search catalog
let response = try await MusicKitService.shared.searchCatalog(term: "Calvin Harris")
```

For detailed MusicKit setup, see: `MUSICKIT_JWT_INTEGRATION_GUIDE.md`

---

## 🔐 Security Standards

### Code Security
- ✅ Private keys never committed to repository
- ✅ Sensitive data stored in Keychain
- ✅ All network requests use HTTPS
- ✅ Encrypted peer-to-peer communication

### Privacy
- ✅ Granular permission requests (microphone, location, Bluetooth)
- ✅ Local-first data processing
- ✅ No tracking or analytics without consent
- ✅ User data remains on device by default

### Firebase (Optional)
If using Firebase, configure security rules:
```javascript
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rides/{rideId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Backend API Security
- API key authentication for token endpoints
- Rate limiting to prevent abuse
- Token rotation (180-day expiration)
- Secure key storage (AWS Secrets Manager, etc.)

---

## 🎨 Design System

### Liquid Glass Visual Language

Branchr features a premium **Liquid Glass** design system inspired by iOS 18+ and modern Apple design:

- **`.ultraThinMaterial` backgrounds** — Frosted glass effects throughout the app
- **20pt corner radius** — Consistent rounded aesthetic on all UI elements
- **Rainbow glow effects** — Animated multi-color halos on interactive buttons
- **White active states** — Clean, premium look for active controls
- **Blurred album backgrounds** — Dynamic backgrounds from currently playing music
- **Premium shadows** — Multi-layer depth effects for cards and buttons
- **Haptic feedback** — Tactile responses for all interactions

### Color Palette

- **Brand Yellow** (#FFD60A) — Primary accent color
- **Black** — Base color for dark mode
- **White** — Text and UI elements
- **Rainbow Gradient** — Progress bars and special effects (red → orange → yellow → green → blue → purple → pink)
- **Glass Tints** — Translucent overlays with 0.12-0.20 opacity

### Typography

- **System Font** (San Francisco) — Apple's native typeface
- **Bold weights** for headings and emphasis
- **Medium weights** for buttons and controls
- **Regular/Light weights** for body text
- **Rounded variant** for playful elements

---

## 🗺️ Development Roadmap

| Phase | Focus | Status |
|-------|-------|--------|
| **Phase 1** | Core ride tracking & GPS mapping | ✅ Complete |
| **Phase 2** | Voice chat & Bluetooth connectivity | ✅ Complete |
| **Phase 3** | Apple Music integration & DJ mode | ✅ Complete |
| **Phase 4** | Group management & social features | ✅ Complete |
| **Phase 30** | Tab bar cleanup & calendar view | ✅ Complete |
| **Phase 31** | Firebase profile sync & editable profile UI | ✅ Complete |
| **Phase 32** | Firebase ride sync & cloud storage | ✅ Complete |
| **Phase 33** | UI polish & theme unification | ✅ Complete |
| **Phase 34** | Ride tracking flow fixes & enhancements | ✅ Complete |
| **Phase 61-70** | MusicKit integration, DJ controls, live music UI | ✅ Complete |
| **Phase 71-75** | Layout polish, weekly goals, profile stats | ✅ Complete |
| **Phase 76+** | Liquid Glass UI redesign & visual enhancements | ✅ Complete |
| **Phase 6** | Analytics dashboard & advanced features | 📋 Planned |

### Recent Updates (Phase 76+ - Liquid Glass Design)
- ✅ **Liquid Glass UI** — Modern frosted glass effects with premium materials
- ✅ **Rainbow Glow Buttons** — Animated multi-color halos on button press
- ✅ **Enhanced Weekly Goals** — Large numbers, rainbow progress bars, streak tracking
- ✅ **Full-Width Audio Controls** — Redesigned music/voice buttons with white active states
- ✅ **Consistent 20pt Corners** — Unified rounded aesthetic throughout app
- ✅ **Live Music Backgrounds** — Blurred album artwork behind HomeView
- ✅ **Liquid Glass Tab Bar** — Translucent tab bar with blur effects
- ✅ **Premium Interactions** — Haptic feedback and smooth animations
- ✅ **Ride Persistence** — Rides automatically save and sync to Calendar
- ✅ **Voice Commands** — "Pause tracking", "Resume ride", "Stop ride", "Status update"

### Future Enhancements
- 📱 Apple Watch companion app
- 🗺️ Offline map support
- 🏆 Achievement system and badges
- 📊 Advanced ride analytics
- 🌍 Global ride sharing
- 🤖 AI-powered ride recommendations

---

## 💡 Vision

Branchr envisions a world where technology enhances, rather than distracts from, the joy of cycling. By bringing riders together through seamless communication and shared experiences, Branchr strengthens communities and makes every ride memorable.

### Key Principles
- **Simplicity** — Intuitive interface that gets out of the way
- **Privacy** — User data belongs to users
- **Performance** — Smooth 60fps animations, low battery impact
- **Reliability** — Works offline when possible, graceful degradation
- **Design Excellence** — Premium liquid glass UI that rivals Apple's best apps

---

## 🤝 Contributing

Branchr is currently a private project. Contributions are not accepted at this time.

For questions or feedback, please contact the project maintainer.

---

## 📚 Documentation

### Setup Guides
- `MUSICKIT_JWT_INTEGRATION_GUIDE.md` — Complete MusicKit setup guide
- `APPLE_MUSIC_DEVELOPER_TOKEN_SETUP.md` — JWT token generation
- `backend/README.md` — Backend server documentation

### Phase Documentation
- `Docs/PHASE_75_PROFILE_STATS_AND_PRO_UI.md` — Profile enhancements & stats
- `Docs/PHASE_74_RESUME_RIDE_WEEKLY_GOAL_AND_HUD_ALIGNMENT.md` — Weekly goals & ride resume
- `Docs/PHASE_70_RIDE_VOICE_CHAT_AND_HUD_MUSIC_INTEGRATION.md` — Voice chat & music integration
- `Docs/PHASE_61_LIVE_DJ_CONTROLS_MUSICKIT.md` — DJ controls & MusicKit implementation
- `PHASE_34_RIDE_TRACKING_FIXES.md` — Ride tracking enhancements
  - ✅ Ride persistence & calendar integration
  - ✅ Clean black map polyline rendering
  - ✅ Voice announcements (distance, speed, progress)
  - ✅ Voice commands (pause, resume, stop, status)
  - ✅ Haptic feedback for milestones
  - ✅ Dismissible ride tracking sheet
  - ✅ Auto-save ride feature
- `Docs/RAINBOW_BUTTON_IMPLEMENTATION.md` — Rainbow glow effect implementation
- `Docs/THEME_SYSTEM_BRAND_YELLOW.md` — Theme system & color palette

---

## 📄 License

Proprietary. All rights reserved.

This project contains proprietary code and is not licensed for public use.

---

## 👤 Credits

**Founder & Lead Developer:** Joseph Dormond

**Technologies:**
- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Powered by [Apple MusicKit](https://developer.apple.com/musickit/)
- Audio processing via [AVFoundation](https://developer.apple.com/av-foundation/)
- Location services with [CoreLocation](https://developer.apple.com/documentation/corelocation)

---

## 🙏 Acknowledgments

- Apple for world-class frameworks and developer tools
- The cycling community for inspiration and feedback
- Open source contributors whose work made this possible

---

<div align="center">

**Made with ❤️ for cyclists everywhere**

*Ride. Connect. Sync.*

</div>
