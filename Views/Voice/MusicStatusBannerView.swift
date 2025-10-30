//
//  MusicStatusBannerView.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import SwiftUI

/// Banner view displaying current music information during group rides
/// Shows song title, artist, source app, and provides quick access to open in music app
struct MusicStatusBannerView: View {
    @ObservedObject var musicSync: MusicSyncService
    let pandoraService: PandoraIntegrationService
    
    @State private var isExpanded = false
    @State private var showingAppOptions = false
    
    var body: some View {
        if let track = musicSync.currentTrack {
            VStack(spacing: 0) {
                // Main banner content
                HStack(spacing: 12) {
                    // Music icon
                    Image(systemName: track.sourceApp.icon)
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 24, height: 24)
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Text(track.artist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Text("•")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(track.sourceApp.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Play/pause indicator
                    Image(systemName: track.isPlaying ? "play.circle.fill" : "pause.circle.fill")
                        .font(.title2)
                        .foregroundColor(track.isPlaying ? .green : .orange)
                    
                    // Expand button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Expanded content
                if isExpanded {
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal, 16)
                        
                        // Additional track info
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if let album = track.album {
                                    Text("Album: \(album)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let position = track.playbackPosition,
                                   let duration = track.trackDuration {
                                    Text("\(formatTime(position)) / \(formatTime(duration))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Playback status
                            Text(track.isPlaying ? "Now Playing" : "Paused")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(track.isPlaying ? .green : .orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    (track.isPlaying ? Color.green : Color.orange)
                                        .opacity(0.1),
                                    in: Capsule()
                                )
                        }
                        .padding(.horizontal, 16)
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            // Open in app button
                            Button(action: {
                                pandoraService.openInApp(track)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                    
                                    Text("Open in App")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue, in: Capsule())
                            }
                            
                            // Alternative apps button
                            Button(action: {
                                showingAppOptions = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.caption)
                                    
                                    Text("Other Apps")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            .sheet(isPresented: $showingAppOptions) {
                AppOptionsSheet(track: track, pandoraService: pandoraService)
            }
        }
    }
    
    /// Format time interval as MM:SS
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Sheet showing alternative music app options
struct AppOptionsSheet: View {
    let track: NowPlayingInfo
    let pandoraService: PandoraIntegrationService
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current track info
                VStack(spacing: 8) {
                    Text("🎵 \(track.title)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("by \(track.artist)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Available apps
                VStack(spacing: 12) {
                    Text("Open in:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(MusicSource.allCases.filter { $0 != .unknown }, id: \.self) { source in
                            AppOptionButton(
                                source: source,
                                track: track,
                                pandoraService: pandoraService,
                                onTap: { dismiss() }
                            )
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Music Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Individual app option button
struct AppOptionButton: View {
    let source: MusicSource
    let track: NowPlayingInfo
    let pandoraService: PandoraIntegrationService
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            openInApp()
            onTap()
        }) {
            VStack(spacing: 8) {
                Image(systemName: source.icon)
                    .font(.title)
                    .foregroundColor(.primary)
                
                Text(source.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!pandoraService.isAppInstalled(source))
        .opacity(pandoraService.isAppInstalled(source) ? 1.0 : 0.5)
    }
    
    private func openInApp() {
        switch source {
        case .appleMusic:
            pandoraService.openInAppleMusic(track)
        case .pandora:
            pandoraService.openInPandora(track)
        case .youtubeMusic:
            pandoraService.openInYouTubeMusic(track)
        case .spotify:
            pandoraService.openInSpotify(track)
        case .unknown:
            break
        }
    }
}

#Preview {
    VStack {
        Spacer()
        
        MusicStatusBannerView(
            musicSync: {
                let service = MusicSyncService()
                service.currentTrack = NowPlayingInfo(
                    title: "Blinding Lights",
                    artist: "The Weeknd",
                    album: "After Hours",
                    sourceApp: .appleMusic,
                    playbackPosition: 45.0,
                    isPlaying: true,
                    trackDuration: 200.0
                )
                return service
            }(),
            pandoraService: PandoraIntegrationService()
        )
        
        Spacer()
    }
    .background(Color.gray.opacity(0.1))
}
