# Phase 02 – Ride Tracking & Maps

## Goal

Implement core ride tracking functionality with GPS location services, real-time map display, route visualization, ride statistics (distance, time, speed), and session recovery. This phase enables users to track their cycling rides with accurate metrics and visual feedback.

## Key Features in This Phase

- Ride tracking service (`Services/RideTrackingService.swift`)
- Ride session manager (`Services/RideSessionManager.swift`)
- Map view with route overlay (`Views/Ride/RideMapViewRepresentable.swift`, `Views/Ride/RideMapView.swift`)
- Ride tracking UI (`Views/Ride/RideTrackingView.swift`)
- Ride HUD overlay (`Views/Ride/RideHostHUDView.swift`)
- Ride data persistence (`Services/RideDataManager.swift`)
- Session recovery service (`Services/RideSessionRecoveryService.swift`)
- Calendar integration (`Views/Calendar/RideCalendarView.swift`)

## Checklist

### ✅ Completed

- [x] GPS location tracking – `CLLocationManager` integration in `Services/RideTrackingService.swift` and `Services/RideSessionManager.swift`
- [x] Real-time map display – `MKMapView` with route overlay in `Views/Ride/RideMapViewRepresentable.swift`
- [x] Route visualization – Polyline rendering of ride path in `Views/Ride/RideMapView.swift`
- [x] Ride statistics – Distance, time, average speed calculated in `Services/RideSessionManager.swift`
- [x] Ride HUD card – Glassmorphism card with stats, avatar, music controls in `Views/Ride/RideHostHUDView.swift`
- [x] Ride state management – Active, paused, ended states in `Services/RideSessionManager.swift`
- [x] Ride data persistence – Local storage via `Services/RideDataManager.swift`
- [x] Calendar auto-save – Rides ≥ 5 minutes saved to EventKit in `Services/RideSessionManager.swift`
- [x] Session recovery – `Services/RideSessionRecoveryService.swift` saves/restores ride state
- [x] Ride summary view – `Views/Rides/EnhancedRideSummaryView.swift` shows ride completion stats
- [x] Ride history – `Views/Calendar/RideCalendarView.swift` displays past rides
- [x] Location permissions – Proper authorization flow in `Services/RideTrackingService.swift`

### ⬜ Planned / TODO

- [ ] Auto-pause when stopped – Setting exists in `Views/Settings/SettingsView.swift` but not wired to `Services/RideSessionManager.swift` (needs speed threshold timer)
- [ ] Background location support – Currently disabled in `Info.plist`, needs `UIBackgroundModes` entry and testing (see `Services/RideSessionManager.hasBackgroundLocationCapability()`)
- [ ] Route optimization – Reduce route point density for long rides to save memory in `Services/RideSessionManager.swift`
- [ ] Map region auto-update – Improve map centering during active rides in `Views/Ride/RideTrackingView.swift`
- [ ] Ride export – Add GPX/KML export functionality for ride data
- [ ] Ride sharing – Share ride summary with friends via Messages/Email
- [ ] Offline ride tracking – Cache ride data when network unavailable
- [ ] Battery optimization – Reduce location update frequency when screen is off

## Notes / Links

- **Location warnings:** Main actor isolation warnings in `Services/RideSessionManager.swift` and `Services/RideTrackingService.swift` – Swift 6 compatibility, non-blocking
- **Background location:** Intentionally disabled – see `branchr/Info.plist` with TODO comment explaining decision
- **HUD card size:** Recently optimized to be more compact and transparent – see `Views/Ride/RideHostHUDView.swift`
- **Session recovery:** Auto-restore disabled in `branchrApp.swift` to prevent accidental ride starts on launch

