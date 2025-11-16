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
    @StateObject private var connectionManager = ConnectionManager.shared // Phase 25
    @StateObject private var fcmService = FCMService.shared // Phase 28
    @StateObject private var voiceService = VoiceChatService()
    @StateObject private var locationService = LocationTrackingService()
    @StateObject private var rideService = RideTrackingService()
    @StateObject private var groupManager = GroupSessionManager() // Phase 20
    @StateObject private var musicSync = MusicSyncService() // Phase 20
    @ObservedObject private var theme = ThemeManager.shared
    
    // Phase 25B: Animation State removed (replaced by logo in Phase 29)
    
    // MARK: - Phase 28: SOS Alert State
    @State private var showSOSBanner = false
    
    // MARK: - Phase 31: Ride Tracking State
    @State private var showRideTracking = false
    @State private var rideDetent: PresentationDetent = .large // Phase 34D: Fullscreen sheet
    @ObservedObject private var rideSession = RideSessionManager.shared
    @State private var showSmartRideSheet = false
    
    // MARK: - State Variables
    @State private var showingGroupRide = false
    @State private var showingConnectedRiders = false // Phase 20
    @State private var showingVoiceSettings = false
    @State private var showingSafetySettings = false
    @State private var showingDJControls = false
    @State private var showDJSheet = false
    @State private var isMusicMuted: Bool = false
    @State private var isVoiceMuted: Bool = false
    @State private var showRideOptions = false
    @State private var showRideSummary = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                // Phase 28: SOS Alert Banner
                if let alert = fcmService.latestSOSAlert, showSOSBanner {
                    Button(action: {
                        showSOSBanner = false
                        openMap(latitude: alert.latitude, longitude: alert.longitude)
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Calculate distance if location available
                            if let distance = alert.distance(from: locationService.locations.last) {
                                Text("\(alert.name) triggered SOS nearby (\(String(format: "%.1f", distance)) mi away)! Tap to open live location.")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            } else {
                                Text("\(alert.name) triggered SOS nearby! Tap to open live location.")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showSOSBanner = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(12)
                        .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSOSBanner)
                    .onAppear {
                        // Auto-dismiss after 10 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            withAnimation {
                                showSOSBanner = false
                            }
                        }
                    }
                }
                
                // MARK: - Logo Header (Phase 29: Branchr Logo with Dynamic Theme Swap)
                VStack(spacing: 12) {
                    // App Icon - Theme-aware (above "branchr" text, larger and centered)
                    Image(theme.isDarkMode ? "AppIconDark" : "AppIconLight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .cornerRadius(28)
                    
                    // "branchr" text centered below app icon
                    Text("branchr")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryText)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 40)
                
                // MARK: - Connection Status (Phase 29: Dynamic Indicator)
                VStack(spacing: 6) {
                    Text("Connect with your group")
                        .font(.subheadline)
                        .foregroundColor(theme.primaryText.opacity(0.7))
                    
                    // Phase 29: Dynamic connection indicator with pulse animation
                    HStack(spacing: 8) {
                        Circle()
                            .fill(connectionManager.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                            .shadow(
                                color: connectionManager.isConnected ? .green.opacity(0.5) : .red.opacity(0.5),
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
                        
                        Text(connectionManager.isConnected ? "Connected" : "Disconnected")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(connectionManager.isConnected ? .green : .red)
                            .animation(.easeInOut, value: connectionManager.isConnected)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.2))
                    .clipShape(Capsule())
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
                
                // MARK: - Main Actions (Phase 2: Unified Button System)
                VStack(spacing: 20) {
                    // Start Ride Tracking - Hero Button
                    PrimaryButton(
                        rideSession.rideState == .idle || rideSession.rideState == .ended
                            ? "Start Ride Tracking"
                            : rideSession.rideState == .active
                              ? "Pause Ride"
                              : "Resume Ride",
                        systemImage: nil,
                        isHero: true,
                        isNeonHalo: true  // Phase 34D: Thin neon halo on press
                    ) {
                        if rideSession.rideState == .idle || rideSession.rideState == .ended {
                            RideSessionManager.shared.startSoloRide()
                            withAnimation(.spring()) { showSmartRideSheet = true }
                        } else if rideSession.rideState == .active {
                            RideSessionManager.shared.pauseRide()
                        } else if rideSession.rideState == .paused {
                            RideSessionManager.shared.resumeRide()
                        }
                    }
                    .rainbowGlow(active: rideSession.rideState == .active)  // Phase 34D: Active-state glow
                    .sheet(isPresented: $showSmartRideSheet) {
                        RideSheetView()
                            .presentationDetents([.large])
                    }
                    .onChange(of: rideSession.rideState) { state in
                        // Keep sheet open for entire ride lifecycle
                        if state == .active || state == .paused {
                            withAnimation(.spring()) { showSmartRideSheet = true }
                        }
                    }
                    
                    // Start Connection Button
                    PrimaryButton(
                        connectionManager.state == .connected
                            ? "Stop Connection"
                            : connectionManager.state == .connecting
                              ? "Connecting..."
                              : "Start Connection",
                        systemImage: nil,
                        isHero: false,
                        isNeonHalo: true  // Phase 34D: Thin neon halo on press
                    ) {
                        connectionManager.toggleConnection()
                    }
                    .rainbowGlow(active: connectionManager.state == .connecting || connectionManager.state == .connected)  // Phase 34D: Active-state glow
                    
                    // Show connected peers if any
                    if !connectionManager.connectedPeers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Connected Riders:")
                                .font(.headline)
                                .foregroundColor(theme.primaryText)
                                .padding(.horizontal, 20)
                            
                            ForEach(connectionManager.connectedPeers, id: \.self) { peer in
                                HStack {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                    Text(peer.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(theme.primaryText)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Start Voice Chat Button
                    PrimaryButton(
                        voiceService.isVoiceChatActive ? "End Voice Chat" : "Start Voice Chat",
                        systemImage: voiceService.isVoiceChatActive ? "mic.slash.fill" : "mic.fill",
                        isHero: false,
                        isNeonHalo: true  // Phase 34D: Thin neon halo on press
                    ) {
                        if voiceService.isVoiceChatActive {
                            voiceService.stopVoiceChat()
                        } else {
                            voiceService.startVoiceChat()
                        }
                    }
                    .rainbowGlow(active: voiceService.isVoiceChatActive)  // Phase 34D: Active-state glow
                    
                    // Safety & SOS Button
                    SafetyButton(
                        "Safety & SOS",
                        systemImage: "exclamationmark.triangle.fill"
                    ) {
                        showingSafetySettings = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .onAppear {
                print("🏁 HomeView loaded - ready for Start Connection")
                // Phase 28: Start listening for SOS alerts
                fcmService.startListeningForSOSAlerts()
            }
            .onChange(of: fcmService.latestSOSAlert) { alert in
                // Show banner when new SOS alert arrives
                if alert != nil {
                    showSOSBanner = true
                }
            }
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
        .sheet(isPresented: $showingConnectedRiders) {
            ConnectedRidersSheet(
                groupManager: groupManager,
                voiceService: voiceService,
                musicSync: musicSync
            )
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
        .sheet(isPresented: $showingSafetySettings) {
            SOSView() // Phase 27: Updated to use new SOSView
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
        .sheet(isPresented: $showRideOptions) {
            RideOptionsSheet(rideService: rideService, showSummary: $showRideSummary, dismiss: $showRideOptions)
        }
        .fullScreenCover(isPresented: $showRideSummary) {
            Phase20RideSummaryView(rideService: rideService)
        }
        // Phase 31: Unified Ride Tracking Sheet
        .sheet(isPresented: $showRideTracking) {
            RideTrackingView()
                .ignoresSafeArea() // Phase 34D: Full-screen coverage for map
                .presentationDetents([.large, .fraction(0.3)], selection: $rideDetent)
                .presentationDragIndicator(.visible)
                .onAppear {
                    // Phase 34D: Start the sheet fully expanded
                    rideDetent = .large
                }
        }
    }
    
    // MARK: - Computed Properties
    // Phase 29: Connection status now handled inline with dynamic indicator
    
    // MARK: - Phase 28: SOS Alert Helpers
    
    /// Open Apple Maps with SOS location
    private func openMap(latitude: Double, longitude: Double) {
        if let url = URL(string: "https://maps.apple.com/?q=\(latitude),\(longitude)") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Ride Tracking
    
    /**
     * 🚴‍♂️ Handle Ride Button Press
     *
     * Handles button press based on current ride state.
     * Phase 20: Full implementation with state management.
     */
    private func handleRideButtonPress() {
        switch rideService.rideState {
        case .idle, .ended:
            // Start new ride
            rideService.startRide()
            // Also start location tracking service if needed
            if !locationService.isTracking {
                locationService.startTracking()
            }
            
        case .active:
            // Show options modal (Pause, End, SOS)
            showRideOptions = true
            
        case .paused:
            // Resume ride (should be handled by modal, but fallback)
            rideService.resumeRide()
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

