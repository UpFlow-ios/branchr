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
        VStack(alignment: .leading, spacing: 18) {
            // Phase 56: Connection Status centered at top
            HStack {
                Spacer()
                
                // Connection Status Pill
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
                .background(Color(.systemGray6).opacity(0.2))
                .clipShape(Capsule())
                
                Spacer()
            }
            
            // Music Source Selector (Phase 54: label removed, only show when ride is idle)
            if rideService.rideState == .idle || rideService.rideState == .ended {
                MusicSourceSelectorView(selectedSource: $preferredMusicSource)
            }
            
            // Weekly Goal Card
            WeeklyGoalCardView(
                totalThisWeekMiles: totalThisWeekMiles,
                goalMiles: goalMiles,
                currentStreakDays: currentStreakDays,
                bestStreakDays: bestStreakDays
            )
            
            // Voice/Audio Controls Row (Phase 59: swapped Music On and DJ Controls)
            HStack(spacing: 16) {
                // Voice Mute Toggle
                AudioControlButton(
                    icon: isVoiceMuted ? "mic.slash.fill" : "mic.fill",
                    title: isVoiceMuted ? "Muted" : "Unmuted",
                    isActive: !isVoiceMuted
                ) {
                    onToggleMute()
                }
                
                // DJ Controls (Phase 59: moved to middle position)
                AudioControlButton(
                    icon: "music.quarternote.3",
                    title: "DJ Controls",
                    isActive: false // DJ Controls is not a toggle, always inactive state
                ) {
                    onDJControlsTap()
                }
                
                // Music Toggle (Phase 59: moved to right position)
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
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surfaceBackground)
                .shadow(
                    color: theme.isDarkMode ? .clear : Color.black.opacity(0.25),
                    radius: theme.isDarkMode ? 0 : 18,
                    x: 0,
                    y: theme.isDarkMode ? 0 : 8
                )
        )
    }
}

// MARK: - Audio Control Button (reused from HomeView)

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
                            .fill(isActive ? theme.brandYellow : theme.surfaceBackground)
                    )
                    .foregroundColor(isActive ? .black : .white)
                
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
                    .fill(Color.black.opacity(isActive ? 0.9 : 0.7))
            )
        }
        .buttonStyle(.plain)
    }
}

