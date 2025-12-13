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
                
                // MIDDLE: Album artwork + playback controls + track info
                // Phase 76: Always show card when in Apple Music mode, use cached artwork
                if preferredMusicSource == .appleMusicSynced {
                    if let artwork = musicService.lastArtworkImage {
                        // Full card with artwork and track info
                        ZStack(alignment: .bottom) {
                            // 🔳 Large artwork - fills container (matches mockup)
                            Image(uiImage: artwork)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 380) // Large size like mockup
                                .clipped()
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
                            
                            // Gradient at the bottom for readability
                            LinearGradient(
                                colors: [Color.black.opacity(0.0),
                                         Color.black.opacity(0.70)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .cornerRadius(20)
                            .allowsHitTesting(false)
                            
                            VStack(spacing: 10) {
                                // Floating white playback controls - 60pt spacing (matches mockup)
                                HStack(spacing: 60) {
                                    // Previous
                                    Button(action: {
                                        HapticsService.shared.lightTap()
                                        musicService.skipToPreviousTrack()
                                    }) {
                                        Image(systemName: "backward.fill")
                                            .font(.system(size: 38, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 70, height: 70)
                                            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    // Play / Pause
                                    Button(action: {
                                        HapticsService.shared.mediumTap()
                                        musicService.togglePlayPause()
                                    }) {
                                        Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 44, weight: .heavy))
                                            .foregroundColor(.white)
                                            .frame(width: 80, height: 80)
                                            .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 5)
                                    }
                                    
                                    // Next
                                    Button(action: {
                                        HapticsService.shared.lightTap()
                                        musicService.skipToNextTrack()
                                    }) {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 38, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 70, height: 70)
                                            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Track title and artist over the artwork
                                if let nowPlaying = musicService.nowPlaying {
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
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    } else {
                        // Placeholder when Apple Music selected but no artwork cached yet
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.black.opacity(0.45))
                                )
                            
                            VStack(spacing: 12) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Apple Music Ready")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                
                                Text("Start playing a song in Apple Music")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                } else {
                    // Placeholder for "Other Music App" mode
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.black.opacity(0.45))
                            )
                        
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("External Music")
                                .font(.headline.bold())
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        // Outer card glass + subtle stroke + shadow
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(theme.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
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

// MARK: - Audio Control Button (small glass tile with rainbow glow)

struct AudioControlButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
            HapticsService.shared.lightTap()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
            )
        }
        .buttonStyle(.plain)
        .applePressable(isPressed) // Apple-style press animation
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}
