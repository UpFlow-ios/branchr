# Phase 03 – Music & Voice Chat

## Goal

Integrate Apple Music playback control, music source selection (Apple Music vs external apps), real-time voice chat during rides, voice feedback announcements, and speech command recognition. This phase enables the social music-sharing and communication features that make Branchr unique.

## Key Features in This Phase

- Music service (`Services/MusicService.swift`)
- Music sync service (`Services/MusicSyncService.swift`)
- MusicKit integration (`Services/MusicKitService.swift`)
- Audio session management (`Services/AudioSessionManager.swift`)
- Voice chat service (`Services/VoiceChatService.swift`)
- Voice feedback service (`Services/VoiceFeedbackService.swift`)
- Voice coach service (`Services/VoiceCoachService.swift`)
- Speech commands (`Services/SpeechCommandService.swift`)
- DJ controls UI (`Views/Music/DJControlsSheetView.swift`)
- Music source selector (`Views/Home/RideControlPanelView.swift`)

## Checklist

### ✅ Completed

- [x] Apple Music integration – MusicKit authorization and playback in `Services/MusicService.swift`
- [x] System music player control – `MPMusicPlayerController.systemMusicPlayer` for transport controls
- [x] Music source selection – Apple Music (Synced) vs Other Music App in `Models/MusicSourceMode.swift`
- [x] Music source persistence – User preference stored in `Services/UserPreferenceManager.swift`
- [x] Now playing display – Track info shown in `Views/Music/DJControlsSheetView.swift` and `Views/Ride/RideHostHUDView.swift`
- [x] DJ controls sheet – Playback controls (previous/play-pause/next) in `Views/Music/DJControlsSheetView.swift`
- [x] Audio session configuration – High-fidelity music + voice chat in `Services/AudioSessionManager.swift`
- [x] Voice chat service – Real-time audio streaming in `Services/VoiceChatService.swift`
- [x] Voice feedback – Text-to-speech announcements in `Services/VoiceFeedbackService.swift`
- [x] Voice coach – Periodic ride updates in `Services/VoiceCoachService.swift`
- [x] Speech commands – Voice control for pause/resume/stop in `Services/SpeechCommandService.swift`
- [x] Music authorization UI – Permission status shown in `Views/Music/DJControlsSheetView.swift`
- [x] Music badges – Branded Apple Music and Branchr logos in `Views/Home/RideControlPanelView.swift`

### ⬜ Planned / TODO

- [ ] Voice announcements toggle – Setting exists in `Views/Settings/SettingsView.swift` but not wired to `Services/VoiceFeedbackService.swift`
- [ ] DJ mode toggle – Setting exists but not wired to `Services/MusicSyncService.swift` for song requests
- [ ] Voice chat while riding toggle – Setting exists but not wired to `Services/VoiceChatService.swift` to prevent starting during active rides
- [ ] Music queue management – Add ability to queue songs in Apple Music mode
- [ ] Song requests – Implement peer-to-peer song request system for group rides
- [ ] Voice chat quality settings – Add bitrate/quality options in `Views/Settings/VoiceSettingsView.swift`
- [ ] Audio ducking – Improve music ducking when voice announcements play
- [ ] Background music playback – Ensure music continues when app is backgrounded

## Notes / Links

- **Audio session warnings:** Deprecation warnings for iOS 17.0+ APIs in `Services/AudioMixerService.swift` and `Services/VoiceChatService.swift` – intentionally deferred
- **MusicKit authorization:** Properly handled with status UI in `Views/Music/DJControlsSheetView.swift`
- **Audio quality:** High-fidelity configuration in `Services/AudioSessionManager.swift` preserves full-range music during voice chat
- **IPC warnings:** Audio engine start moved to background queue in `Services/VoiceChatService.swift` to prevent main thread blocking

