//
//  RideControlPanelView.swift
//  branchr
//
//  Created for Phase 52 - HomeView Layout Cleanup
//

import SwiftUI

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
    
    @ObservedObject private var musicService = MusicService.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    private let cardHeight: CGFloat = 260
    
    // MARK: - Computed
    
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
            // Artwork / background
            if preferredMusicSource == .appleMusicSynced,
               let nowPlaying = musicService.nowPlaying,
               let artwork = nowPlaying.artwork {
                
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        theme.surfaceBackground,
                        theme.surfaceBackground.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            
            // Glassy tint overlay
            LinearGradient(
                colors: [Color.black.opacity(0.45), Color.black.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
            
            VStack(spacing: 16) {
                // TOP: Connection status pill
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 10, height: 10)
                            .shadow(
                                color: connectionStatusColor.opacity(0.6),
                                radius: 6,
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
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 7)
                    .branchrGlassPill()
                    
                    Spacer()
                }
                .padding(.top, 12)
                
                Spacer(minLength: 0)
                
                // MIDDLE: Playback controls + track info
                if preferredMusicSource == .appleMusicSynced,
                   let nowPlaying = musicService.nowPlaying {
                    VStack(spacing: 14) {
                        HStack(spacing: 0) {
                            Spacer()
                            
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
                            
                            Spacer()
                            
                            Button(action: {
                                HapticsService.shared.mediumTap()
                                musicService.togglePlayPause()
                            }) {
                                Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title.bold())
                                    .foregroundColor(.black)
                                    .frame(width: 58, height: 58)
                                    .background(theme.brandYellow)
                                    .clipShape(Circle())
                                    .shadow(color: theme.brandYellow.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                            
                            Spacer()
                            
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
                            
                            Spacer()
                        }
                        
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
                        .padding(.horizontal, 12)
                    }
                } else if preferredMusicSource == .appleMusicSynced {
                    VStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .font(.system(size: 42))
                            .foregroundColor(theme.brandYellow.opacity(0.85))
                        
                        Text("Apple Music Ready")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
                
                Spacer(minLength: 0)
                
                WeeklyGoalCardView(
                    totalThisWeekMiles: totalThisWeekMiles,
                    goalMiles: goalMiles,
                    currentStreakDays: currentStreakDays,
                    bestStreakDays: bestStreakDays
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .branchrGlassCard(cornerRadius: 24)
        .onAppear {
            if preferredMusicSource == .appleMusicSynced {
                musicService.refreshNowPlayingFromNowPlayingInfoCenter()
            }
        }
    }
}
