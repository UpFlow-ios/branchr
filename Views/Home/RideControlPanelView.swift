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
            // Main content
            VStack(spacing: 16) {
                
                // TOP: Connection Status pill (glass)
                HStack {
                    Spacer()
                    connectionStatusPill
                    Spacer()
                }
                .padding(.top, 4)
                
                // MIDDLE: Album artwork + playback controls + track info
                if preferredMusicSource == .appleMusicSynced,
                   let nowPlaying = musicService.nowPlaying,
                   let artwork = nowPlaying.artwork {
                    
                    ZStack(alignment: .bottom) {
                        // 🔳 Big, clean square artwork – shows the full album without cropping weirdly
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(20)
                        
                        // Gradient at the bottom for readability
                        LinearGradient(
                            colors: [Color.black.opacity(0.0),
                                     Color.black.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .cornerRadius(20)
                        .allowsHitTesting(false)
                        
                        VStack(spacing: 10) {
                            // Glass playback controls like Control Center
                            HStack(spacing: 22) {
                                // Previous
                                Button(action: {
                                    HapticsService.shared.lightTap()
                                    musicService.skipToPreviousTrack()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                                }
                                
                                // Play / Pause
                                Button(action: {
                                    HapticsService.shared.mediumTap()
                                    musicService.togglePlayPause()
                                }) {
                                    Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 54, height: 54)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.55), radius: 10, x: 0, y: 6)
                                }
                                
                                // Next
                                Button(action: {
                                    HapticsService.shared.lightTap()
                                    musicService.skipToNextTrack()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Track title and artist over the artwork
                            VStack(spacing: 4) {
                                Text(nowPlaying.title)
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 3)
                                
                                Text(nowPlaying.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                                    .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 3)
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    
                } else if preferredMusicSource == .appleMusicSynced {
                    // Placeholder when Apple Music selected but no track
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.black.opacity(0.65))
                        
                        VStack(spacing: 10) {
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(theme.brandYellow.opacity(0.9))
                            
                            Text("Apple Music Ready")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Start playing a song in Apple Music")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                } else {
                    // Placeholder for "Other Music App" mode
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.black.opacity(0.65))
                        
                        VStack(spacing: 10) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            
                            Text("External Music")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Control playback from your other music app")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                }
                
                // BOTTOM: Weekly Goal – glass like the status pill
                WeeklyGoalCardView(
                    totalThisWeekMiles: totalThisWeekMiles,
                    goalMiles: goalMiles,
                    currentStreakDays: currentStreakDays,
                    bestStreakDays: bestStreakDays
                )
                
                // Voice/Audio Controls Row – glass buttons
                HStack(spacing: 16) {
                    // Voice Mute Toggle
                    AudioControlButton(
                        icon: isVoiceMuted ? "mic.slash.fill" : "mic.fill",
                        title: isVoiceMuted ? "Muted" : "Unmuted",
                        isActive: !isVoiceMuted
                    ) {
                        onToggleMute()
                    }
                    
                    // DJ Controls
                    AudioControlButton(
                        icon: "music.quarternote.3",
                        title: "DJ Controls",
                        isActive: false // DJ Controls is not a toggle
                    ) {
                        onDJControlsTap()
                    }
                    
                    // Music Toggle
                    AudioControlButton(
                        icon: isMusicMuted ? "speaker.slash.fill" : "music.note",
                        title: isMusicMuted ? "Music Off" : "Music On",
                        isActive: !isMusicMuted
                    ) {
                        onToggleMusic()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        // Outer card glass + subtle stroke + shadow
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(theme.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
                )
                .shadow(
                    color: Color.black.opacity(theme.isDarkMode ? 0.55 : 0.35),
                    radius: 22,
                    x: 0,
                    y: 14
                )
        )
        .onAppear {
            // Refresh now playing when view appears
            if preferredMusicSource == .appleMusicSynced {
                musicService.refreshNowPlayingFromNowPlayingInfoCenter()
            }
        }
    }
    
    // MARK: - Connection Status Pill
    
    private var connectionStatusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 12, height: 12)
                .shadow(
                    color: connectionStatusColor.opacity(0.6),
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
        .background(.ultraThinMaterial) // glassy like System UI
        .clipShape(Capsule())
    }
}

// MARK: - Audio Control Button (glass style)

private struct AudioControlButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    Color.white.opacity(isActive ? 0.40 : 0.18),
                                    lineWidth: isActive ? 1.2 : 0.8
                                )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isActive ? theme.brandYellow : .white)
                }
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
}
