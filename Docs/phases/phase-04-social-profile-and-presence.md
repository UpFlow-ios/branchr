# Phase 04 – Social / Profile / Presence

## Goal

Build user profiles with photos, bios, and stats, implement real-time presence tracking (online/offline indicators), and create social features for connecting with other riders. This phase enables the community and social aspects of Branchr.

## Key Features in This Phase

- Profile view (`Views/Profile/ProfileView.swift`)
- Profile editor (`Views/Profile/EditProfileView.swift`)
- Profile manager (`Services/ProfileManager.swift`)
- Firebase profile service (`Services/FirebaseProfileService.swift`)
- Presence manager (`Services/PresenceManager.swift`)
- Profile tab icon (`Views/Profile/ProfileTabIconView.swift`)
- Profile stats (`Services/RideDataManager.swift`)

## Checklist

### ✅ Completed

- [x] Profile view – User avatar, name, bio, stats in `Views/Profile/ProfileView.swift`
- [x] Profile editor – Edit name, bio, photo in `Views/Profile/EditProfileView.swift`
- [x] Profile photo upload – Firebase Storage integration in `Services/FirebaseService.swift`
- [x] Profile data sync – Firestore integration in `Services/FirebaseProfileService.swift`
- [x] Online presence indicator – Green ring around avatar when online in `Views/Profile/ProfileView.swift`
- [x] Presence manager – Tracks online/offline status in `Services/PresenceManager.swift`
- [x] Profile tab icon – Shows user avatar in tab bar in `Views/Profile/ProfileTabIconView.swift`
- [x] Profile stats – Real ride data (count, distance, time) in `Views/Profile/ProfileView.swift` from `Services/RideDataManager.swift`
- [x] Profile photo caching – Local image caching in `Services/ProfileManager.swift`
- [x] Online ring on HUD – Green ring on ride HUD avatar in `Views/Ride/RideHostHUDView.swift`
- [x] Profile persistence – Local storage via `@AppStorage` and Firebase sync

### ⬜ Planned / TODO

- [ ] Friend activity notifications – Setting exists in `Views/Settings/SettingsView.swift` but no notification scheduler yet
- [ ] Profile photo compression – Optimize upload sizes in `Services/FirebaseService.uploadProfilePhoto()`
- [ ] Profile sharing – Share profile link with other users
- [ ] Friend connections – Add ability to follow/friend other riders
- [ ] Profile privacy settings – Control who can see profile/stats
- [ ] Profile verification – Add verified badge for trusted users
- [ ] Profile achievements – Display badges and achievements on profile
- [ ] Social feed – Show friend activity and achievements

## Notes / Links

- **Presence sync:** Fixed in audit – `PresenceManager.setOnline()` now checks for signed-in user before updating
- **Profile photo:** Supports both local cached images and Firebase URLs with fallback to SF Symbol
- **Online indicator:** Green ring matches design across ProfileView and RideHostHUDView (48x48 ring, 3pt stroke)
- **Stats calculation:** Real-time stats from `RideDataManager` including weekly totals and streaks

