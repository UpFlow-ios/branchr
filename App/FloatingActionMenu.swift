//
//  FloatingActionMenu.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//

import SwiftUI

struct FloatingActionMenu: View {
    @Binding var showMenu: Bool
    @Binding var showDJControls: Bool
    @ObservedObject var theme = ThemeManager.shared
    @StateObject private var locationService = LocationTrackingService()
    @StateObject private var voiceService = VoiceChatService()
    
    var body: some View {
        ZStack {
            // 1. Expanded action cluster
            if showMenu {
                VStack(alignment: .trailing, spacing: 14) {
                    
                    ActionRow(label: "Start Ride", icon: "location.circle.fill") {
                        // Start ride tracking
                        if !locationService.isTracking {
                            locationService.startTracking()
                        }
                        print("▶ Start Ride")
                        withAnimation {
                            showMenu = false
                        }
                    }
                    
                    ActionRow(label: voiceService.isMuted ? "Unmute Voice" : "Mute Voice", icon: voiceService.isMuted ? "mic.circle.fill" : "mic.slash.circle.fill") {
                        // Toggle voice mute
                        voiceService.toggleMute()
                        print("🔇 Toggle Voice Mute")
                        withAnimation {
                            showMenu = false
                        }
                    }
                    
                    ActionRow(label: "Safety SOS", icon: "exclamationmark.triangle.fill") {
                        // Emergency alert
                        print("🚨 SOS Triggered")
                        withAnimation {
                            showMenu = false
                        }
                    }
                    
                    ActionRow(label: "DJ Controls", icon: "music.note.list") {
                        // Open DJ mode
                        showDJControls = true
                        print("🎧 Open DJ Mode")
                        withAnimation {
                            showMenu = false
                        }
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            // 2. Main button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(theme.primaryButton)
                        .frame(width: 64, height: 64)
                        .shadow(radius: 10)

                    Image(systemName: showMenu ? "xmark" : "bolt.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.primaryButtonText)
                }
            }
        }
    }
}

// Small helper row component inside the FAB
private struct ActionRow: View {
    let label: String
    let icon: String
    let action: () -> Void
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.black.opacity(0.7))
            .cornerRadius(14)
            .shadow(radius: 6)
        }
    }
}

