//
//  RideControlPanelView.swift
//  branchr
//
//  Created for Phase 52 - HomeView Layout Cleanup
//

import SwiftUI

/**
 * 🎛️ Ride Control & Audio Panel
 *
 * Groups music source selector, connection status, weekly goal, and audio controls
 * into a single organized card for better visual hierarchy.
 */
struct RideControlPanelView: View {
    // MARK: - Bindings & State
    @Binding var preferredMusicSource: MusicSourceMode
    @ObservedObject var connectionManager: ConnectionManager
    @ObservedObject var rideService: RideTrackingService
    @ObservedObject var userPreferences: UserPreferenceManager
    
    // Weekly Goal Data
    let totalThisWeekMiles: Double
    let goalMiles: Double
    let currentStreakDays: Int
    let bestStreakDays: Int
    
    // Audio Control State
    @Binding var isVoiceMuted: Bool
    @Binding var isMusicMuted: Bool
    
    // Audio Control Handlers
    let onToggleMute: () -> Void
    let onToggleMusic: () -> Void
    let onDJControlsTap: () -> Void
    
    // Music Service for Now Playing
    @ObservedObject private var musicService = MusicService.shared
    
    @ObservedObject private var theme = ThemeManager.shared
    
    // Auto-refresh timer for now playing / artwork
    @State private var nowPlayingTimer = Timer
        .publish(every: 3, on: .main, in: .common)
        .autoconnect()
    
    // MARK: - Computed Properties
    
    private var isSoloRide: Bool {
        rideService.rideState == .active || rideService.rideState == .paused
    }
    
    private var connectionStatusLabel: String {
        if isSoloRide && !connectionManager.isConnected {
            return "Solo Ride"
        } else if connectionManager.isConnected {
            return "Connected"
        } else {
            return "Disconnected"
        }
    }
    
    private var connectionStatusColor: Color {
        if isSoloRide && !connectionManager.isConnected {
            return Color.branchrAccent
        } else if connectionManager.isConnected {
            return .green
        } else {
            return .red
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background: Large artwork that fills the card
            if preferredMusicSource == .appleMusicSynced,
               let nowPlaying = musicService.nowPlaying,
               let artwork = nowPlaying.artwork {
                
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                // Fallback: dark background when no artwork
                theme.surfaceBackground
            }
            
            // Gradient overlay for text readability - lighter for clearer artwork
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.black.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
            
            // Content overlaying the artwork
            VStack(spacing: 16) {
                // TOP: Connection Status
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 12, height: 12)
                            .shadow(
                                color: connectionStatusColor.opacity(0.5),
                                radius: 8,
                                x: 0,
                                y: 0
                            )
                            .scaleEffect(connectionManager.isConnected ? 1.05 : 1.0)
                            .animation(
                                connectionManager.isConnected
                                ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                                : .default,
                                value: connectionManager.isConnected
                            )
                        
                        Text(connectionStatusLabel)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(connectionStatusColor)
                            .animation(.easeInOut, value: connectionManager.isConnected)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.3))
                    .clipShape(Capsule())
                    
                    Spacer()
                }
                .padding(.top, 4)
                
                Spacer(minLength: 0)
                
                // MIDDLE: Centered playback controls + track info (only when Apple Music is active)
                if preferredMusicSource == .appleMusicSynced,
                   let nowPlaying = musicService.nowPlaying {
                    
                    VStack(spacing: 12) {
                        // Playback controls - centered with increased spacing for symmetry
                        HStack(spacing: 40) {
                            Button(action: {
                                HapticsService.shared.lightTap()
                                musicService.skipToPreviousTrack()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.title2)
                                    .foregroundColor(theme.brandYellow)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                HapticsService.shared.mediumTap()
                                musicService.togglePlayPause()
                            }) {
                                Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title.bold())
                                    .foregroundColor(.black)
                                    .frame(width: 56, height: 56)
                                    .background(theme.brandYellow)
                                    .clipShape(Circle())
                                    .shadow(color: theme.brandYellow.opacity(0.5), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: {
                                HapticsService.shared.lightTap()
                                musicService.skipToNextTrack()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.title2)
                                    .foregroundColor(theme.brandYellow)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Track title and artist
                        VStack(spacing: 4) {
                            Text(nowPlaying.title)
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            
                            Text(nowPlaying.artist)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 8)
                    }
                } else if preferredMusicSource == .appleMusicSynced {
                    // Placeholder when Apple Music selected but no track
                    VStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(theme.brandYellow.opacity(0.8))
                        
                        Text("Apple Music Ready")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
                
                Spacer(minLength: 0)
                
                // BOTTOM: Weekly Goal first, then audio controls
                WeeklyGoalCardView(
                    totalThisWeekMiles: totalThisWeekMiles,
                    goalMiles: goalMiles,
                    currentStreakDays: currentStreakDays,
                    bestStreakDays: bestStreakDays
                )
                .frame(maxWidth: .infinity)
                
                // Voice/Audio Controls Row aligned to Weekly Goal width
                HStack(spacing: 16) {
                    AudioControlButton(
                        icon: isVoiceMuted ? "mic.slash.fill" : "mic.fill",
                        title: isVoiceMuted ? "Muted" : "Unmuted",
                        isActive: !isVoiceMuted
                    ) {
                        onToggleMute()
                    }
                    
                    AudioControlButton(
                        icon: "music.quarternote.3",
                        title: "DJ Controls",
                        isActive: false
                    ) {
                        onDJControlsTap()
                    }
                    
                    AudioControlButton(
                        icon: isMusicMuted ? "speaker.slash.fill" : "music.note",
                        title: isMusicMuted ? "Music Off" : "Music On",
                        isActive: !isMusicMuted
                    ) {
                        onToggleMusic()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surfaceBackground) // Fallback background
                .shadow(
                    color: theme.isDarkMode ? .clear : Color.black.opacity(0.25),
                    radius: theme.isDarkMode ? 0 : 18,
                    x: 0,
                    y: theme.isDarkMode ? 0 : 8
                )
        )
        .onAppear {
            if preferredMusicSource == .appleMusicSynced {
                musicService.refreshNowPlayingFromNowPlayingInfoCenter()
            }
        }
        .onReceive(nowPlayingTimer) { _ in
            if preferredMusicSource == .appleMusicSynced {
                musicService.refreshNowPlayingFromNowPlayingInfoCenter()
            }
        }
    }
}

// MARK: - Audio Control Button

private struct AudioControlButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial) // glassy tile
                    )
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(
                        isActive ? .white : Color.white.opacity(0.85)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.35)) // subtle glass over artwork
            )
        }
        .buttonStyle(.plain)
    }
}
