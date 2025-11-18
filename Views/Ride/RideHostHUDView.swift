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
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 12) {
                // Avatar
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
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.green, lineWidth: 3) // host ring
                )
                
                // Host name + badge + stats
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(hostName)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Host")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.brandYellow)
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 10) {
                        Label("\(String(format: "%.2f", distanceMiles)) mi", systemImage: "location.north.line")
                        Label("\(String(format: "%.0f", speedMph)) mph", systemImage: "speedometer")
                        Label(durationText, systemImage: "clock")
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Connection pill + music badge
                HStack(spacing: 8) {
                    // Connection pill - Phase 35B: Show "Solo Ride" when disconnected but ride is active
                    HStack(spacing: 6) {
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 8, height: 8)
                        Text(connectionStatusLabel)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    
                    // Optional music badge
                    if isMusicOn {
                        HStack(spacing: 4) {
                            Image(systemName: "music.note.list")
                            Text("DJ On")
                                .font(.caption2.bold())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.brandYellow)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(12)
        }
        .background(Color.black.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        // Phase 35B: Removed shadow for flatter appearance
        .padding(.horizontal, 16)
        .padding(.top, 8)
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
}

