# Phase 65 – System Apple Music Transport

**Status**: ✅ Completed  
**Date**: 2025-12-01

---

## 🎯 Goals

Fix Apple Music transport controls to use the system music player (`MPMusicPlayerController.systemMusicPlayer`) instead of `ApplicationMusicPlayer`, which was causing `MPMusicPlayerControllerErrorDomain error 1` errors when the queue was empty.

---

## 📝 Changes Made

### 1. MusicService.swift – System Player Integration

**Added System Player:**
- `private let systemPlayer = MPMusicPlayerController.systemMusicPlayer`
- Used for all transport controls when `musicSourceMode == .appleMusicSynced`
- `ApplicationMusicPlayer` kept for future in-app playback features

**Updated Transport Methods:**

1. **`togglePlayPause()`** (Phase 65):
   - Uses `systemPlayer.playbackState` to determine current state
   - Calls `systemPlayer.play()` or `systemPlayer.pause()` accordingly
   - Updates `isPlaying` property
   - Refreshes now playing after state change

2. **`pause()`** (Phase 65):
   - Calls `systemPlayer.pause()` directly
   - No async/await needed (synchronous API)
   - Refreshes now playing after pause

3. **`resume()`** (Phase 65):
   - Calls `systemPlayer.play()` directly
   - Simplified from async MusicKit API
   - Refreshes now playing after resume

4. **`skipToNext()`** (Phase 65):
   - Calls `systemPlayer.skipToNextItem()` directly
   - Removed authorization checks (system player doesn't require MusicKit auth)
   - Refreshes now playing after skip

5. **`skipToPrevious()`** (Phase 65):
   - Calls `systemPlayer.skipToPreviousItem()` directly
   - Removed authorization checks
   - Refreshes now playing after skip

6. **New Alias Methods:**
   - `skipToNextTrack()` – Wraps `skipToNext()` in Task for sync calls
   - `skipToPreviousTrack()` – Wraps `skipToPrevious()` in Task for sync calls

**Improved Now Playing Refresh:**

- `refreshNowPlayingFromNowPlayingInfoCenter()` (Phase 65):
  1. First tries `MPNowPlayingInfoCenter.default().nowPlayingInfo` (existing)
  2. Falls back to `systemPlayer.nowPlayingItem` if center is nil
  3. Sets `nowPlaying = nil` only if both sources are empty
  4. Logs which source provided the data

**Updated Internal Method:**

- `updateNowPlaying()` (Phase 65):
  - Uses `systemPlayer.playbackState` instead of `player.state` for `isPlaying`
  - More reliable for system playback state

---

## 🔧 Technical Details

### Why System Player?

- **No Queue Required**: System player controls whatever is playing in Apple Music app
- **No Authorization Needed**: Works with system playback without MusicKit auth
- **Reliable**: No "prepareToPlay failed [no target descriptor]" errors
- **User-Friendly**: Controls actual Apple Music playback user is listening to

### Transport Control Flow

1. **User Taps Control in DJ Controls:**
   - Method checks `musicSourceMode == .appleMusicSynced`
   - Calls appropriate `systemPlayer` method
   - Updates `isPlaying` state
   - Refreshes now playing info

2. **Now Playing Updates:**
   - Primary: `MPNowPlayingInfoCenter` (works for all apps)
   - Fallback: `systemPlayer.nowPlayingItem` (Apple Music specific)
   - Both checked to ensure reliable track info

### Mode-Specific Behavior

**Apple Music Mode (`musicSourceMode == .appleMusicSynced`):**
- All transport controls use `systemPlayer`
- Now playing refresh checks both sources
- No MusicKit authorization required for transport

**External Player Mode (`musicSourceMode == .externalPlayer`):**
- All transport methods return early with log message
- No system player calls
- No MusicKit calls

---

## ✅ Testing Checklist

### Apple Music Transport

- [x] Open Apple Music, start playing a song
- [x] Switch to Branchr, ensure Apple Music (Synced) is selected
- [x] Open DJ Controls:
  - [x] Play/Pause toggles Apple Music playback
  - [x] Skip Next moves Apple Music queue
  - [x] Skip Previous moves Apple Music queue
  - [x] Now Playing shows current song
- [x] Start a ride:
  - [x] Ride Now Playing strip shows current track
  - [x] Controls affect actual Apple Music playback

### Error Handling

- [x] No more "prepareToPlay failed [no target descriptor]" errors
- [x] No more "MPMusicPlayerControllerErrorDomain error 1" errors
- [x] Transport works even without MusicKit authorization
- [x] External Player mode still no-ops correctly

### Existing Functionality

- [x] SOS system untouched
- [x] Ride tracking works normally
- [x] Voice chat unaffected
- [x] Badge pills unchanged
- [x] Permission UI unchanged
- [x] Now Playing UI layout unchanged

---

## 📊 Files Modified

1. `Services/MusicService.swift` – System player integration and transport control updates

---

## 🎉 Result

- ✅ Transport controls use system Apple Music player
- ✅ No more empty queue errors
- ✅ Controls actual Apple Music playback
- ✅ More reliable now playing info (dual source)
- ✅ No MusicKit authorization required for transport
- ✅ All existing functionality preserved
- ✅ Build succeeds with no errors

---

## 📝 Key Improvements

1. **Reliability**: System player doesn't require a queue, eliminating errors
2. **User Experience**: Controls what user is actually listening to
3. **Simplicity**: No async/await for most transport methods
4. **Robustness**: Dual-source now playing refresh (center + systemPlayer)
5. **Compatibility**: Works without MusicKit authorization

---

**Phase 65 Complete!** 🎵

