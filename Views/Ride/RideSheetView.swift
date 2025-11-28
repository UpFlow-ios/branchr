//
//  RideSheetView.swift
//  branchr
//
//  Created for Smart Group Ride System - Universal Ride Interface
//

import SwiftUI

/**
 * 🚴‍♂️ Ride Sheet View
 *
 * Thin wrapper around RideTrackingView to provide a single source of truth
 * for the ride UI. All ride UI (map, HUD, ride button, overlays) lives in RideTrackingView.
 */
struct RideSheetView: View {
    // Phase 35.5: Log state changes to track auto-stops
    init() {
        print("🎯 RideSheetView initialized")
    }
    
    var body: some View {
        RideTrackingView()
    }
}

// MARK: - Ride Stat Card (Ride Sheet)

struct RideSheetStatCard: View {
    let icon: String
    let value: String
    let label: String
    let unit: String?
    
    init(icon: String, value: String, label: String, unit: String? = nil) {
        self.icon = icon
        self.value = value
        self.label = label
        self.unit = unit
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .opacity(0.7)
                }
            }
            
            Text(label)
                .font(.caption)
                .opacity(0.7)
        }
        .frame(width: 100)
    }
}

// MARK: - Host Controls Section (Ride Sheet) - Phase 35.2 Enhanced

struct RideSheetHostControls: View {
    @ObservedObject private var groupManager = GroupSessionManager.shared
    @ObservedObject private var rideManager = RideSessionManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with emoji
            HStack {
                Text("👑")
                    .font(.title3)
                Text("Host Controls")
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
            }
            
            // Audio Controls Row
            HStack(spacing: 12) {
                // 🎵 Music Toggle
                MusicToggleButton(
                    isMuted: groupManager.isMutingMusic,
                    action: {
                        groupManager.toggleMuteMusic()
                        VoiceFeedbackService.shared.speak(groupManager.isMutingMusic ? "Music paused for group" : "Music resumed for group")
                    }
                )
                
                // 🎙 Voice Toggle
                VoiceToggleButton(
                    isMuted: groupManager.isMutingVoices,
                    action: {
                        groupManager.toggleMuteVoices()
                        VoiceFeedbackService.shared.speak(groupManager.isMutingVoices ? "Voices muted for group" : "Voices unmuted for group")
                    }
                )
            }
            
            // 🏁 End Group Ride Button
            Button(action: {
                // Phase 35.3: Instant stop
                rideManager.endRide()
                Task { @MainActor in
                    await VoiceFeedbackService.shared.speak("Ride stopped, saved to calendar")
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }) {
                HStack {
                    Text("🏁")
                        .font(.title3)
                    Text("End Group Ride")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
        )
        .rainbowGlow(active: rideManager.rideState == .active)
    }
}

