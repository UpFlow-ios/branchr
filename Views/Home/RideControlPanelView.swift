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
            // Base card background (dark glass)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(theme.surfaceBackground)
                .shadow(color: Color.black.opacity(0.35), radius: 22, x: 0, y: 14)
            
            // Optional blurred artwork wash behind everything
            if preferredMusicSource == .appleMusicSynced,
               let nowPlaying = musicService.nowPlaying,
               let artwork = nowPlaying.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.55)
                    .blur(radius: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            
            // Subtle top-to-bottom gradient for depth
            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.25),
                    Color.black.opacity(0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            // Content overlay
            VStack(spacing: 16) {
                // TOP: Connection Status pill
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 10, height: 10)
                            .shadow(
                                color: connectionStatusColor.opacity(0.6),
                                radius: 8,
                                x: 0,
                                y: 0
                            )
                            .scaleEffect(connectionManager.isConnected ? 1.08 : 1.0)
                            .animation(
                                connectionManager.isConnected
                                ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                                : .default,
                                value: connectionManager.isConnected
                            )
                        
                        Text(connectionStatusLabel)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .animation(.easeInOut, value: connectionManager.isConnected)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 0.75)
                            )
                    )
                    
                    Spacer()
                }
                .padding(.top, 6)
                
                // MIDDLE: Big square artwork with controls over it
                if preferredMusicSource == .appleMusicSynced,
                   let nowPlaying = musicService.nowPlaying,
                   let artwork = nowPlaying.artwork {
                    
                    ZStack {
                        // Large square artwork
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 10)
                        
                        // Playback controls floating over artwork
                        VStack {
                            Spacer()
                            
                            HStack(spacing: 32) {
                                // Previous
                                Button(action: {
                                    HapticsService.shared.lightTap()
                                    musicService.skipToPreviousTrack()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.25), lineWidth: 0.75)
                                        )
                                }
                                
                                // Play / Pause (slightly bigger)
                                Button(action: {
                                    HapticsService.shared.mediumTap()
                                    musicService.togglePlayPause()
                                }) {
                                    Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 22, weight: .heavy))
                                        .foregroundColor(.black)
                                        .frame(width: 56, height: 56)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .shadow(color: Color.black.opacity(0.45), radius: 10, x: 0, y: 5)
                                        )
                                }
                                
                                // Next
                                Button(action: {
                                    HapticsService.shared.lightTap()
                                    musicService.skipToNextTrack()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.25), lineWidth: 0.75)
                                        )
                                }
                            }
                            .padding(.bottom, 18)
                        }
                        .padding(.horizontal, 18)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260) // this is what makes the artwork "big"
                    
                    // Track title + artist under the square
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
                    
                } else if preferredMusicSource == .appleMusicSynced {
                    // Placeholder when Apple Music selected but no track
                    VStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(theme.brandYellow.opacity(0.9))
                        
                        Text("Apple Music Ready")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                }
                
                // BOTTOM: Weekly Goal + Audio Controls
                VStack(spacing: 14) {
                    // Weekly Goal – now glassy, no extra dark box
                    WeeklyGoalCardView(
                        totalThisWeekMiles: totalThisWeekMiles,
                        goalMiles: goalMiles,
                        currentStreakDays: currentStreakDays,
                        bestStreakDays: bestStreakDays
                    )
                    
                    // Voice / Audio Controls Row – also glassy
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
                }
                
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .onAppear {
            // Refresh now playing when view appears
            if preferredMusicSource == .appleMusicSynced {
                musicService.refreshNowPlayingFromNowPlayingInfoCenter()
            }
        }
    }
}

// MARK: - Audio Control Button (glass version)

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
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(isActive ? 0.35 : 0.18),
                                            lineWidth: isActive ? 1.2 : 0.8)
                            )
                    )
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.95))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(isActive ? 0.30 : 0.18), lineWidth: 0.9)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
}
