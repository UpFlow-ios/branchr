# 🎧 Branchr Phase 10 – Group Music Sync & Universal DJ Mode
**Objective:**  
Add a shared music experience to Branchr:
- One rider = "Host DJ"
- Other riders see what song is playing (Apple Music, Pandora, YouTube Music)
- Other riders can request songs
- Music and live voice intercom work together, even with Branchr in the background
- Host can control what plays next

We will NOT attempt to illegally stream DRM audio from one device to others.  
Instead, we sync metadata + playback intent so followers can play the same song on their own device.

---

## 🧠 Core Features in Phase 10

1. **MusicSyncService**  
   - Detect what the host is currently playing.
   - Broadcast track info (title, artist, album art if available, playback position, source app).
   - Send control events ("play", "pause", "next", etc.) over the Multipeer session.

2. **PandoraIntegrationService**  
   - Build deep links to open Pandora on the same track.
   - Handle fallback (if user doesn't have Pandora installed, just show metadata).

3. **HostDJController**  
   - Lets the host approve/deny song requests from riders.
   - Lets the host mark themselves as DJ.
   - Sends "Now Playing" to all peers.

4. **SongRequestManager**  
   - Riders can request a song (title/artist).
   - Host sees pending requests in a queue.

5. **MusicStatusBannerView**  
   - In-ride banner UI:  
     "🎵 Blinding Lights — The Weeknd • Apple Music"  
     With a button to "Open in App".

6. **DJControlView**  
   - Host-only panel:
     - Show current song
     - Skip / Pause / Resume
     - See incoming requests from riders

7. **Background audio session integration**  
   - Keep intercom voice and music notifications alive while Branchr is backgrounded.
   - Allow the host to switch to Apple Music / Pandora to pick a new song without killing Branchr voice chat.

---

## 📂 File Layout

Create/update the following files:

```text
~/Documents/branchr/
│
├── Services/
│   ├── MusicSyncService.swift
│   ├── PandoraIntegrationService.swift
│   ├── HostDJController.swift
│   ├── SongRequestManager.swift
│
└── Views/
    ├── MusicStatusBannerView.swift
    ├── DJControlView.swift
    └── GroupRideView.swift   // update to include banner + request button
```

## ⚙️ Cursor Prompt Instructions

You are extending Branchr (Swift 5.9+, SwiftUI, iOS 18.2 SDK, Xcode 16.2).
Implement Universal DJ Mode with Apple Music + Pandora support.
Use only Apple-approved public APIs.
DO NOT capture or rebroadcast device audio output.
This is 100% metadata sync and user intent sync.

### 1️⃣ MusicSyncService.swift

Responsibilities:
- Reads the host device's "now playing" info using MPNowPlayingInfoCenter.default().nowPlayingInfo.
- Determines source app if possible (Apple Music, Pandora, YouTube Music) by bundle activity if available.
- Packages data and broadcasts it to all connected peers via the existing MultipeerConnectivity session.

Data model suggestion:

```swift
struct NowPlayingInfo: Codable {
    var title: String
    var artist: String
    var album: String?
    var sourceApp: MusicSource    // .appleMusic, .pandora, .youtubeMusic, .unknown
    var playbackPosition: TimeInterval?
    var isPlaying: Bool
}

enum MusicSource: String, Codable {
    case appleMusic
    case pandora
    case youtubeMusic
    case unknown
}
```

Expose:

```swift
final class MusicSyncService: ObservableObject {
    @Published var currentTrack: NowPlayingInfo?
    @Published var isHostDJ: Bool = false

    func becomeHostDJ()
    func resignHostDJ()

    func updateNowPlayingFromSystem() // Called on host: pulls MPNowPlayingInfoCenter and updates currentTrack
    func broadcastNowPlaying()        // Send currentTrack to peers via MultipeerConnectivity
    func handleIncomingNowPlaying(_ info: NowPlayingInfo) // Called on riders to update UI banner
}
```

Implementation details:
- On host, poll MPNowPlayingInfoCenter every ~1s while DJ mode is active.
- Whenever data changes, call broadcastNowPlaying().
- On receiving side, GroupRideView / MusicStatusBannerView updates UI.

This gives riders near-live "Now Playing" sync.

---

### 2️⃣ PandoraIntegrationService.swift

Goal:
- Allow riders to jump into Pandora (or Apple Music) on the same song.

Implement:

```swift
final class PandoraIntegrationService {
    func buildPandoraURL(for track: NowPlayingInfo) -> URL? {
        // Use best-effort deep link:
        // pandora://www.pandora.com/search/<artist>%20<title>
        // If we have title and artist, format them for a Pandora search.
    }

    func openInPandora(_ track: NowPlayingInfo) {
        if let url = buildPandoraURL(for: track) {
            UIApplication.shared.open(url)
        }
    }

    func openInAppleMusic(_ track: NowPlayingInfo) {
        // Use MusicKit / Storefront search if sourceApp == .appleMusic
    }
}
```

Also:
- Add bundle queries so iOS will allow us to open 3rd party music apps.

Info.plist must include:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>pandora</string>
    <string>music</string>
    <string>youtube</string>
    <string>youtubemusic</string>
</array>
```

We are NOT forcing playback on rider devices.
We are giving them 1 tap to open Pandora / Apple Music / YouTube Music to the same track context.

---

### 3️⃣ SongRequestManager.swift

Goal:
- Riders can request songs to the host.
- Host sees queue of requests.

Data model:

```swift
struct SongRequest: Identifiable, Codable {
    var id: UUID
    var requestedBy: String
    var title: String
    var artist: String?
    var timestamp: Date
}
```

Manager:

```swift
final class SongRequestManager: ObservableObject {
    @Published var pendingRequests: [SongRequest] = []

    func sendRequest(title: String, artist: String?)
    func receiveRequest(_ req: SongRequest)
    func clearRequest(_ id: UUID)
}
```

Behavior:
- On a rider device:
- sendRequest() packages the request and sends it to the host via MultipeerConnectivity.
- On the host device:
- receiveRequest() appends to pendingRequests.
- DJControlView displays the list so host can act.

---

### 4️⃣ HostDJController.swift

Goal:
- This is the host-only logic + UI state for controlling the party.

Responsibilities:
- Mark current user as DJ (isHostDJ = true in MusicSyncService).
- Approve or ignore song requests.
- Optionally trigger skip/next/previous on the host side using system media controls.

Methods:

```swift
final class HostDJController: ObservableObject {
    @Published var isActiveHost: Bool = false

    let musicSync: MusicSyncService
    let songRequests: SongRequestManager

    func activateHost()
    func deactivateHost()

    func approveRequest(_ request: SongRequest)
    func rejectRequest(_ request: SongRequest)

    func skipTrack()      // host-side call to system media transport controls
    func pausePlayback()
    func resumePlayback()
}
```

For skip/pause/resume, use MPRemoteCommandCenter.shared() to send playback commands to the host's active player app.

---

### 5️⃣ MusicStatusBannerView.swift

Goal:
- Display "what's playing" during a group ride, for all riders.

Design:
- A compact, frosted-glass pill view that shows:
- Song title + artist
- Source app badge (Apple Music / Pandora / YouTube Music)
- A "▶ Open" button that deep-links into that app.

Structure:

```swift
struct MusicStatusBannerView: View {
    @ObservedObject var musicSync: MusicSyncService
    let pandoraService: PandoraIntegrationService

    var body: some View {
        if let track = musicSync.currentTrack {
            VStack(spacing: 4) {
                Text("🎵 \(track.title)")
                    .font(.headline)
                    .lineLimit(1)

                Text("\(track.artist) • \(prettySource(track.sourceApp))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Button("Open in App") {
                    if track.sourceApp == .pandora {
                        pandoraService.openInPandora(track)
                    } else if track.sourceApp == .appleMusic {
                        pandoraService.openInAppleMusic(track)
                    } else {
                        // fallback: maybe open YouTube Music or show alert
                    }
                }
                .font(.footnote.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
        }
    }
}
```

This banner should appear in GroupRideView for everyone in the session.

---

### 6️⃣ DJControlView.swift

Goal:
- Host-only panel for controlling the vibe.

UI requirements:
- Show current NowPlayingInfo (song, artist, service).
- Show playback state (Playing / Paused).
- Buttons:
- Pause / Resume
- Skip Track
- Section: "Song Requests"
- List of pending requests from riders
- Approve / Dismiss buttons

Structure:

```swift
struct DJControlView: View {
    @ObservedObject var dj: HostDJController
    @ObservedObject var musicSync: MusicSyncService
    @ObservedObject var songRequests: SongRequestManager

    var body: some View {
        VStack(spacing: 20) {
            // Now Playing card
            // Transport controls (Pause / Resume / Skip)
            // Requests list
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 20)
    }
}
```

Behavior:
- If you are NOT the host, and you open this view, it should show a message like:
"Currently controlled by [Host Rider Name]"

---

### 7️⃣ GroupRideView.swift (Update)

Add:
- At the top (or bottom), show MusicStatusBannerView so everyone sees the current track.
- Add a "Request Song" button for riders:
- Opens a small sheet where they type song title / artist.
- Calls SongRequestManager.sendRequest(...).
- Add a "DJ Controls" button only visible if you're the host → presents DJControlView.

Also:
- GroupRideView should subscribe to:
- MusicSyncService updates for now playing.
- SongRequestManager updates for song requests.
- MultipeerConnectivity delegates for passing both.

---

## 🔊 Background Audio Requirements

### Audio Session

Ensure the app's audio session category remains:

```swift
try AVAudioSession.sharedInstance().setCategory(
    .playAndRecord,
    mode: .voiceChat,
    options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker]
)
```

- .mixWithOthers = Branchr voice chat + Apple Music/Pandora playback at same time.
- .allowBluetooth = handle Bluetooth headsets/helmet comms.
- .defaultToSpeaker = riders hear group audio clearly.

### Background Mode

In Xcode:
- Under Signing & Capabilities > Background Modes
- Enable:
- Audio, AirPlay, and Picture in Picture
- Voice over IP (if needed for reliability of the live voice channel)
- Bluetooth LE accessories (if you're using Multipeer + nearby radios)
- Location updates (if ride tracking is running)

This keeps:
- voice connection alive
- music sync info flowing
- requests still working
even when Branchr is backgrounded and the host opens Pandora / Apple Music / YouTube Music to pick a song.

---

## 🔐 Info.plist (Add / Confirm)

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Branchr uses Bluetooth / nearby connectivity to link you with other riders.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Branchr uses the microphone for live rider-to-rider voice chat.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Branchr uses location for ride tracking and safety features.</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>pandora</string>
    <string>music</string>
    <string>youtubemusic</string>
    <string>youtube</string>
</array>
```

We include app query schemes so that UIApplication.shared.open() can deep link.

---

## 🧪 Test Checklist
1. Install Branchr on 3 iPhones.
2. Phone A (Host) taps "Become DJ."
   - MusicSyncService.isHostDJ = true
   - DJControlView unlocks for Host
   - Others see Host's now playing banner
3. Host opens Apple Music and plays a song.
   - MusicSyncService polls MPNowPlayingInfoCenter
   - Branchr broadcasts {title, artist, sourceApp: .appleMusic}
   - Riders see "🎵 [song name] – [artist] • Apple Music"
4. Rider hits "Request Song"
   - Sends request to host
   - Host sees a queue in DJControlView
5. Host pauses music in Apple Music
   - MusicSyncService sees isPlaying = false
   - Riders' banners update to "Paused"
6. While Pandora is active instead of Apple Music:
   - MusicSyncService sees sourceApp = .pandora
   - Riders tap "Open in App" and Branchr deep-links them into Pandora for that track/artist search
7. Verify voice chat still works, even when:
   - Host leaves Branchr and sits inside Pandora
   - Host comes back to Branchr
   - Volumes are still mixed
8. Confirm no crashes, no audio session interruptions, no broken background mode.

---

## ✅ Success Criteria
- DJ mode works with 1 host and multiple riders.
- Riders always know what's playing.
- Requests flow rider → host.
- Host can act on requests.
- Voice chat + music coexist.
- Continues working with Branchr backgrounded.
- 0 warnings, 0 build errors.

---

Save this file as:
~/Documents/branchr/phase10_branchr_universal_dj_mode.md

Then in Cursor, say:

"Generate all code for Phase 10 – Group Music Sync & Universal DJ Mode (Apple Music + Pandora)."

This should output full Swift implementations for:
- MusicSyncService.swift
- PandoraIntegrationService.swift
- SongRequestManager.swift
- HostDJController.swift
- MusicStatusBannerView.swift
- DJControlView.swift
- Updated GroupRideView.swift

Make sure the code:
- Uses Combine / @Published for live state updates
- Uses MultipeerConnectivity to broadcast metadata and song requests
- Uses MPNowPlayingInfoCenter to read host's current track
- Uses MPRemoteCommandCenter for host-side playback control
- Uses UIApplication.shared.open() for deep linking to music apps
- Handles background audio session properly
- Is 100% App Store compliant (no audio capture/rebroadcast)
