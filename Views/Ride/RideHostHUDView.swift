//
//  RideHostHUDView.swift
//  branchr
//
//  Created for Phase 5 - Ride Host HUD + Live Stats
//

import SwiftUI

/// Ride Host HUD overlay showing host info, live stats, and connection status
/// Phase 70: Enhanced with music controls and now playing info
struct RideHostHUDView: View {
    let hostName: String
    let hostImage: UIImage?
    
    let distanceMiles: Double
    let speedMph: Double
    let durationText: String
    
    let isConnected: Bool
    let isMusicOn: Bool
    
    // Phase 53: Music source mode indicator
    let musicSourceMode: MusicSourceMode?
    
    // Phase 70: Music controls integration
    let nowPlaying: MusicServiceNowPlaying?
    let isPlaying: Bool
    let onPrevious: (() -> Void)?
    let onTogglePlayPause: (() -> Void)?
    let onNext: (() -> Void)?
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        // Phase 74: Enhanced HUD with Host badge above Distance, badges above each stat column
        VStack(alignment: .leading, spacing: 12) {
            // Top section: Host info (Phase 74: removed Host badge from header)
            HStack(alignment: .center, spacing: 12) {
                // Left: Avatar
                avatarView
                
                // Center-left: Host name only
                Text(hostName)
                    .font(.subheadline.bold())
                    .foregroundColor(Color.white)
                
                Spacer()
            }
            
            // Phase 74: Centered stats row with Host badge above Distance, Apple Music above Time, Solo Ride above Avg Speed
            HStack(alignment: .center, spacing: 0) {
                // Distance column (left) with Host badge above
                VStack(alignment: .center, spacing: 6) {
                    // Phase 74: Host badge above Distance
                    Text("Host")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.brandYellow)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                    
                    HostStatItem(
                        icon: "location.fill",
                        value: String(format: "%.2f", distanceMiles),
                        label: "Distance",
                        unit: "mi"
                    )
                }
                .frame(maxWidth: .infinity)
                
                Spacer(minLength: 32)
                
                // Time column (middle) with Apple Music badge above
                VStack(alignment: .center, spacing: 6) {
                    // Phase 74: Apple Music badge above Time
                    if let mode = musicSourceMode, mode == .appleMusicSynced {
                        brandedLogo(for: mode)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .frame(minWidth: 80, minHeight: 28, maxHeight: 28)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Capsule())
                    } else {
                        // Spacer to maintain alignment when badge is hidden
                        Spacer()
                            .frame(height: 28)
                    }
                    
                    HostStatItem(
                        icon: "clock.fill",
                        value: durationText,
                        label: "Time",
                        unit: nil
                    )
                }
                .frame(maxWidth: .infinity)
                
                Spacer(minLength: 32)
                
                // Avg Speed column (right) with Solo Ride badge above
                VStack(alignment: .center, spacing: 6) {
                    // Phase 74: Solo Ride badge above Avg Speed with green dot
                    if !isConnected {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green) // Phase 73: Green dot for active solo ride
                                .frame(width: 8, height: 8)
                            
                            Text("Solo Ride")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.9))
                                .clipShape(Capsule())
                        }
                    } else {
                        // Spacer to maintain alignment when badge is hidden
                        Spacer()
                            .frame(height: 28)
                    }
                    
                    HostStatItem(
                        icon: "speedometer",
                        value: String(format: "%.1f", speedMph),
                        label: "Avg Speed",
                        unit: "mph"
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
            // Phase 70: Music Now Playing + Transport Controls
            if musicSourceMode == .appleMusicSynced, let nowPlaying = nowPlaying {
                HStack(spacing: 12) {
                    // Phase 70: Crisp artwork (no heavy blur)
                    if let artwork = nowPlaying.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        Image(systemName: "music.note")
                            .font(.title3)
                            .frame(width: 52, height: 52)
                            .foregroundColor(.white.opacity(0.85))
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nowPlaying.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(nowPlaying.artist)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Phase 70: Transport controls
                    HStack(spacing: 18) {
                        Button(action: { onPrevious?() }) {
                            Image(systemName: "backward.fill")
                                .font(.subheadline)
                                .foregroundColor(theme.brandYellow)
                        }
                        
                        Button(action: { onTogglePlayPause?() }) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.black)
                                .frame(width: 34, height: 34)
                                .background(theme.brandYellow)
                                .clipShape(Circle())
                        }
                        
                        Button(action: { onNext?() }) {
                            Image(systemName: "forward.fill")
                                .font(.subheadline)
                                .foregroundColor(theme.brandYellow)
                        }
                    }
                }
                .padding(.top, 10)
            } else if musicSourceMode == .externalPlayer {
                Text("Using another music app – control playback there while Branchr keeps your ride and voice chat in sync.")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 20) // Phase 57: Wider padding for full-width feel
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity) // Phase 57: Full width within safe margins
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.surfaceBackground)
                .shadow(
                    color: theme.isDarkMode ? .clear : Color.black.opacity(0.25),
                    radius: theme.isDarkMode ? 0 : 18,
                    x: 0,
                    y: theme.isDarkMode ? 0 : 8
                )
        )
    }
    
    // Phase 43: Avatar view with host ring
    private var avatarView: some View {
        ZStack {
            if let uiImage = hostImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(theme.brandYellow)
                Text(String(hostName.prefix(1)).uppercased())
                    .font(.headline.bold())
                    .foregroundColor(.black)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(connectionStatusColor, lineWidth: 2.5) // Phase 43: Use connection color for ring
        )
    }
    
    // Phase 43: Metric label helper (kept for backward compatibility)
    private func metricLabel(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(theme.brandYellow)
            Text(text)
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.85))
        }
    }
    
    // MARK: - Phase 67-69: Host Stat Item Component
    
    /// Compact stat item for host HUD stats row
    /// Phase 74: Updated alignment to center for consistent column layout
    private struct HostStatItem: View {
        let icon: String
        let value: String
        let label: String
        let unit: String?
        
        @ObservedObject private var theme = ThemeManager.shared
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.brandYellow)
                    
                    Text(value)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // Phase 43: Ride mode pill
    private var rideModePill: some View {
        RideModeBadgeView(
            label: connectionStatusLabel,
            color: connectionStatusColor
        )
    }
    
    // Phase 43: Music badge
    private var musicBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "music.note.list")
                .font(.caption2)
            Text("DJ")
                .font(.caption.bold())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.brandYellow)
        .foregroundColor(.black)
        .clipShape(Capsule())
    }
    
    // Phase 35B: Solo ride detection - show "Solo Ride" instead of "Disconnected" when ride is active
    // Note: This view doesn't have direct access to rideService, so we rely on the isConnected prop
    // For solo rides, the parent should pass isConnected=false, and we'll show "Solo Ride" based on context
    // However, since we need ride state, we'll use a computed property that checks if we're in a solo context
    private var connectionStatusLabel: String {
        // If not connected, assume it's a solo ride (parent should handle the logic)
        // For now, we'll show "Solo Ride" when disconnected, but this could be enhanced
        // with an additional parameter if needed
        if !isConnected {
            return "Solo Ride"
        } else {
            return "Connected"
        }
    }
    
    private var connectionStatusColor: Color {
        if !isConnected {
            return Color.branchrAccent
        } else {
            return Color.green
        }
    }
    
    // MARK: - Phase 60: Safe Branded Logo Helper (Full-Color Assets)
    
    /// Returns branded logo image if available, falls back to SF Symbol
    private func brandedLogo(for mode: MusicSourceMode) -> Image {
        if UIImage(named: mode.assetName) != nil {
            // Use original rendering for full-color badge assets
            return Image(mode.assetName)
                .renderingMode(.original)
        } else {
            // Failsafe – fall back to SF Symbol in template mode so it tints correctly
            return Image(systemName: mode.systemIconName)
                .renderingMode(.template)
        }
    }
}

// MARK: - Phase 43C: Reusable Ride Mode Badge

/// Reusable ride mode badge component for displaying ride status on map
struct RideModeBadgeView: View {
    let label: String
    let color: Color // dot color
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption.bold())
                .foregroundColor(Color.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
        )
    }
}

