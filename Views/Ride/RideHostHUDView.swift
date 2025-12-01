//
//  RideHostHUDView.swift
//  branchr
//
//  Created for Phase 5 - Ride Host HUD + Live Stats
//

import SwiftUI

/// Ride Host HUD overlay showing host info, live stats, and connection status
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
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        // Phase 43: Compact horizontal pill matching Ride + Home design
        HStack(alignment: .center, spacing: 12) {
            // Left: Avatar
            avatarView
            
            // Center-left: Host name + metrics
            VStack(alignment: .leading, spacing: 4) {
                // Host name + role badge
                HStack(spacing: 8) {
                    Text(hostName)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.white)
                    
                    // Host badge pill
                    Text("Host")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.brandYellow)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
                
                // Phase 60.3: Image-only full-size music badge pill (no text)
                if let mode = musicSourceMode {
                    brandedLogo(for: mode)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .frame(minWidth: 80, minHeight: 28, maxHeight: 28)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                }
                
                // Metrics row
                HStack(spacing: 12) {
                    metricLabel(icon: "location.north.line", text: String(format: "%.2f mi", distanceMiles))
                    metricLabel(icon: "speedometer", text: String(format: "%.0f mph", speedMph))
                    metricLabel(icon: "clock", text: durationText)
                }
            }
            
            Spacer()
            
            // Right: Ride mode + status indicators
            // Phase 43B: Only show ride mode pill for group/connected rides (not solo)
            HStack(spacing: 8) {
                // Ride mode pill - only show for connected/group rides
                if isConnected {
                    rideModePill
                }
                
                // Music badge (if active)
                if isMusicOn {
                    musicBadge
                }
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
    
    // Phase 43: Metric label helper
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

