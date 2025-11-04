//
//  HomeView.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//  Redesigned for Phase 18.1 - Professional UI Polish
//

import SwiftUI

struct HomeView: View {
    
    // MARK: - State Objects
    @StateObject private var peerService = PeerConnectionService()
    @StateObject private var voiceService = VoiceChatService()
    @StateObject private var locationService = LocationTrackingService()
    @ObservedObject private var theme = ThemeManager.shared
    
    // MARK: - State Variables
    @State private var showingGroupRide = false
    @State private var showingVoiceSettings = false
    @State private var showingSafetySettings = false
    @State private var showingDJControls = false
    @State private var showDJSheet = false
    @State private var isMusicMuted: Bool = false
    @State private var isVoiceMuted: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                // MARK: - Logo Header
                VStack(spacing: 8) {
                    Text("branchr")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryText)
                    
                    Image(systemName: "bicycle.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(theme.accentColor)
                        .padding(.top, 6)
                }
                .padding(.top, 40)
                
                // MARK: - Connection Status
        VStack(spacing: 12) {
            Text("Connect with your group")
                    .font(.headline)
                        .foregroundColor(theme.primaryText.opacity(0.8))
                    
                    Label {
                        Text(connectionStatusText)
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText)
                    } icon: {
                    Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 10, height: 10)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                }
                .padding(.bottom, 10)
                
                // MARK: - Audio Controls
                HStack(spacing: 20) {
                    // Voice Mute Toggle
                    ControlButton(
                        icon: isVoiceMuted ? "mic.slash.fill" : "mic.fill",
                        title: isVoiceMuted ? "Muted" : "Unmuted",
                        action: {
                            isVoiceMuted.toggle()
                            AudioManager.shared.toggleVoiceChat(active: !isVoiceMuted)
                            print(isVoiceMuted ? "Voice muted" : "Voice unmuted")
                        }
                    )
                    
                    // Music Mute Toggle
                    ControlButton(
                        icon: isMusicMuted ? "speaker.slash.fill" : "music.note",
                        title: isMusicMuted ? "Music Off" : "Music On",
                        action: {
                            isMusicMuted.toggle()
                            if isMusicMuted {
                                AudioManager.shared.stopMusic()
                            }
                            print(isMusicMuted ? "Music muted" : "Music unmuted")
                        }
                    )
                    
                    // DJ Controls
                    ControlButton(
                        icon: "music.quarternote.3",
                        title: "DJ Controls",
                        action: {
                            showDJSheet.toggle()
                            print("DJ Controls tapped - opening sheet")
                        }
                    )
                }
                .padding(.vertical, 10)
                
                // MARK: - Main Actions
                VStack(spacing: 14) {
                    // Enhanced Ride Tracking Button (Phase 19.1)
                    RideTrackingButton {
                        startRideTracking()
                    }
                    
                    BranchrButton(title: "Start Group Ride", icon: "person.3.fill") {
                        showingGroupRide = true
                    }
                    
                    BranchrButton(title: peerService.connectionStatus == .disconnected ? "Start Connection" : "Stop Connection", 
                                icon: "antenna.radiowaves.left.and.right") {
                if peerService.connectionStatus == .disconnected {
                    peerService.startConnection()
                } else {
                    peerService.stopConnection()
                }
                    }
                    
                    BranchrButton(title: voiceService.isVoiceChatActive ? "Stop Voice Chat" : "Start Voice Chat", 
                                icon: "mic.circle.fill") {
                    if voiceService.isVoiceChatActive {
                        voiceService.stopVoiceChat()
                    } else {
                        voiceService.startVoiceChat()
                    }
                    }
                    
                    BranchrButton(title: "Safety & SOS", icon: "exclamationmark.triangle.fill") {
                        showingSafetySettings = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { theme.toggleTheme() }) {
                        Image(systemName: theme.isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(theme.accentColor)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingGroupRide) {
            GroupRideView()
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
        .sheet(isPresented: $showingSafetySettings) {
            SafetyControlView()
        }
        .sheet(isPresented: $showingDJControls) {
            NavigationView {
                Text("DJ Controls")
                    .font(.largeTitle)
                    .navigationTitle("DJ Mode")
            }
        }
        .sheet(isPresented: $showDJSheet) {
            DJControlSheetView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionStatusText: String {
        switch peerService.connectionStatus {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var connectionStatusColor: Color {
        switch peerService.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        @unknown default:
            return .gray
        }
    }
    
    // MARK: - Ride Tracking
    
    /**
     * 🚴‍♂️ Start Ride Tracking
     *
     * Initiates ride tracking functionality.
     * Phase 19.1: Stub function - will be enhanced in Phase 20 with GPS + Bluetooth integration.
     */
    private func startRideTracking() {
        print("🚴‍♂️ Ride tracking started…")
        
        // TODO: Phase 20 - Add actual GPS tracking
        // TODO: Phase 20 - Add Bluetooth connection
        // TODO: Phase 20 - Add live stats (time, distance, speed)
        
        if !locationService.isTracking {
            locationService.startTracking()
        }
    }
}

// MARK: - Control Button Component

struct ControlButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(theme.accentColor)
                    .frame(width: 50, height: 50)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                Text(title)
                    .font(.caption)
                    .foregroundColor(theme.primaryText)
            }
        }
    }
}

#Preview {
    HomeView()
}

