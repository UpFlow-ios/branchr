# Phase 51 – Music Source Selector + Simultaneous Music & Voice

**Status**: ✅ Completed  
**Date**: 2025-11-29

---

## 🎯 Goals

Allow riders to choose how they want to listen to music during rides and ensure music and voice chat work simultaneously:

1. **Apple Music (Synced)** – In-app MusicKit playback controlled by Branchr
2. **Other Music App** – User plays Spotify / YouTube Music / Pandora etc. in the background while Branchr handles voice + tracking

---

## 📝 Changes Made

### 1. MusicSourceMode Model

**Created**: `Models/MusicSourceMode.swift`

**Features**:
- `enum MusicSourceMode` with two cases:
  - `.appleMusicSynced` – "Apple Music (Synced)" with `applemusic` icon
  - `.externalPlayer` – "Other Music App" with `apps.iphone` icon
- Conforms to `Codable`, `CaseIterable`, `Identifiable`
- Helper properties: `title`, `subtitle`, `systemImageName`

**Result**: Clean model for user's music source preference.

### 2. UserPreferenceManager – Music Source Persistence

**Modified**: `Services/UserPreferenceManager.swift`

**Added**:
- `@Published var preferredMusicSource: MusicSourceMode`
- Loads from UserDefaults on init (defaults to `.appleMusicSynced`)
- Saves to UserDefaults on change
- Debug logging: `"Branchr UserPreferenceManager: preferredMusicSource set to [title]"`

**Result**: Music source preference persists across app launches.

### 3. RideSessionManager – Music Source Integration

**Modified**: `Services/RideSessionManager.swift`

**Updated Methods**:
- `startSoloRide(musicSource:)` – Accepts optional music source, defaults to user preference
- `startGroupRide(musicSource:)` – Accepts optional music source, defaults to user preference
- `joinGroupRide(rideId:musicSource:)` – Accepts optional music source for joining riders

**Behavior**:
- Uses provided music source or falls back to `UserPreferenceManager.shared.preferredMusicSource`
- Configures `MusicSyncService` with selected source before starting ride
- Logs: `"Branchr: Starting ride with musicSource = [title]"`

**Result**: Music source is threaded through ride lifecycle.

### 4. MusicSyncService – Source-Aware Behavior

**Modified**: `Services/MusicSyncService.swift`

**Added**:
- `@Published var musicSourceMode: MusicSourceMode` (published for UI binding)
- `setMusicSourceMode(_:)` method to update source and configure behavior

**Behavior**:
- When `musicSourceMode == .appleMusicSynced`:
  - Enables polling of `MPNowPlayingInfoCenter`
  - Allows MusicKit integration (when implemented)
- When `musicSourceMode == .externalPlayer`:
  - Skips MusicKit setup
  - Stops polling if not host DJ
  - Logs: `"Branchr MusicSyncService: Skipping MusicKit setup (ExternalPlayer mode)"`

**Result**: Service respects user's music source choice.

### 5. VoiceChatService – Simultaneous Audio Configuration

**Modified**: `Services/VoiceChatService.swift`

**Updated**: `setupAudioSession()` method

**Changes**:
- Added `.mixWithOthers` option to audio session category
- Configuration: `.playAndRecord` mode `.voiceChat` with options:
  - `.allowBluetooth`
  - `.allowBluetoothA2DP`
  - `.defaultToSpeaker`
  - `.mixWithOthers` (NEW)

**Result**: Music apps can continue playing while voice chat is active.

### 6. HomeView – Music Source Selector UI

**Modified**: `Views/Home/HomeView.swift`

**Added**:
- `MusicSourceSelectorView` component (pill-style selector)
- Displays above "Start Ride Tracking" button (only when ride is idle)
- Two side-by-side buttons:
  - Left: "Apple Music (Synced)" with Apple Music icon
  - Right: "Other Music App" with apps icon
- Selected button has yellow background, unselected has dark background
- Binding: `$userPreferences.preferredMusicSource`

**Updated**:
- `startSoloRide()` call now passes `userPreferences.preferredMusicSource`

**Result**: Users can select music source before starting a ride.

### 7. RideTrackingView – Music Source Indicator

**Modified**: `Views/Ride/RideTrackingView.swift`

**Added**:
- Music source indicator pill in `rideStatusStrip`
- Shows icon + title (e.g., "Apple Music (Synced)" or "Other Music App")
- Positioned between Host HUD and close button
- Only visible when ride is active or paused
- Styled with `surfaceBackground` capsule

**Result**: Users can see their current music source during active rides.

---

## 🎨 Visual Design

### Music Source Selector
- **Layout**: Two side-by-side rounded rectangles
- **Selected State**: Yellow background (`brandYellow`), black text
- **Unselected State**: Dark background (`surfaceBackground`), white text
- **Icons**: System SF Symbols matching each mode
- **Card Style**: Matches existing Branchr card design (rounded corners, shadow)

### Music Source Indicator (Active Ride)
- **Style**: Compact pill with icon + text
- **Position**: Top-right of status strip
- **Colors**: White text on semi-transparent dark background
- **Visibility**: Only shown during active/paused rides

---

## 🔧 Technical Details

### Audio Session Configuration
```swift
try audioSession.setCategory(
    .playAndRecord,
    mode: .voiceChat,
    options: [
        .allowBluetooth,
        .allowBluetoothA2DP,
        .defaultToSpeaker,
        .mixWithOthers  // Phase 51: Allows simultaneous music + voice
    ]
)
```

### Music Source Flow
```
1. User selects music source in HomeView
2. Preference saved to UserDefaults
3. When ride starts:
   - RideSessionManager receives musicSource
   - MusicSyncService.setMusicSourceMode() called
   - Service configures behavior based on mode
4. During ride:
   - Apple Music Synced: Polling enabled, MusicKit ready
   - External Player: Polling disabled, user plays from any app
```

### MusicSyncService Behavior
```swift
func setMusicSourceMode(_ mode: MusicSourceMode) {
    musicSourceMode = mode
    if mode == .externalPlayer {
        // Skip MusicKit, stop polling
    } else {
        // Enable MusicKit (when implemented)
    }
}
```

---

## ✅ Acceptance Criteria

- [x] MusicSourceMode model created and persisted
- [x] Music source selector UI in ride start flow
- [x] Music source threaded through ride session configuration
- [x] MusicSyncService respects music source mode
- [x] Audio session configured for simultaneous music + voice
- [x] Music source indicator in active ride UI
- [x] App builds with zero errors
- [x] All existing behavior preserved

---

## 📁 Files Modified

1. **Models/MusicSourceMode.swift** (NEW)
   - Music source mode enum with UI helpers

2. **Services/UserPreferenceManager.swift**
   - Added `preferredMusicSource` property with persistence

3. **Services/RideSessionManager.swift**
   - Updated `startSoloRide()`, `startGroupRide()`, `joinGroupRide()` to accept music source

4. **Services/MusicSyncService.swift**
   - Added `musicSourceMode` property
   - Added `setMusicSourceMode()` method
   - Updated polling logic to respect source mode

5. **Services/VoiceChatService.swift**
   - Updated audio session configuration with `.mixWithOthers`

6. **Views/Home/HomeView.swift**
   - Added `MusicSourceSelectorView` component
   - Updated ride start to pass music source
   - Created `MusicSourceSelectorView` struct

7. **Views/Ride/RideTrackingView.swift**
   - Added music source indicator in status strip

---

## 🚀 User Experience

### Before Phase 51:
- No choice for music source
- Music and voice chat might conflict
- No indication of music source during ride

### After Phase 51:
- **Choice**: Users can select Apple Music (Synced) or Other Music App
- **Simultaneous Audio**: Music and voice chat work together
- **Visual Feedback**: Music source indicator during active rides
- **Persistence**: Preference saved and remembered

---

## 📝 Notes

### MusicKit Integration Status
- MusicKit integration is still TODO (marked in code comments)
- Current implementation uses `MPNowPlayingInfoCenter` for detection
- When MusicKit is implemented, it will only activate for `.appleMusicSynced` mode
- External player mode will continue using system now-playing detection

### Audio Session Management
- Only `VoiceChatService` sets the audio session category
- `MusicSyncService` assumes session is already configured
- `.mixWithOthers` ensures no conflicts between music and voice

### Future Enhancements
- Apple Music subscription detection and fallback
- MusicKit queue management for synced playback
- Enhanced external player detection

---

## 🧪 Manual Test Cases

### Case A: Apple Music (Synced)
1. Select "Apple Music (Synced)" in HomeView
2. Start ride
3. Confirm:
   - Music source indicator shows "Apple Music (Synced)"
   - Voice chat works
   - No audio session conflicts

### Case B: External Player
1. Select "Other Music App" in HomeView
2. Start ride
3. Background to Spotify/YouTube Music and start playback
4. Return to Branchr
5. Confirm:
   - Music keeps playing
   - Voice chat still works
   - Ride tracking continues
   - Music source indicator shows "Other Music App"

### Case C: Preference Persistence
1. Select a music source
2. Close and reopen app
3. Confirm: Preference is remembered

---

**Phase 51 Complete** ✅

