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
    @ObservedObject private var rideDataManager = RideDataManager.shared
    @ObservedObject private var userPreferences = UserPreferenceManager.shared
    
    // Phase 25B: Animation State removed (replaced by logo in Phase 29)
    
    // MARK: - Phase 28: SOS Alert State
    @State private var showSOSBanner = false
    
    // MARK: - Phase 41: Weekly Goal & Streak State
    @State private var totalThisWeekMiles: Double = 0
    @State private var currentStreakDays: Int = 0
    @State private var bestStreakDays: Int = 0
    
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
    
    // Phase 57: Music source mode state (syncs with userPreferences and musicSync)
    @State private var musicSourceMode: MusicSourceMode = UserPreferenceManager.shared.preferredMusicSource
    
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
                
                // Top breathing room - push all content down
                Spacer()
                    .frame(height: 12)
                
                // MARK: - Phase 57: Brand Header - Logo and Theme Toggle on One Line
                ZStack {
                    // Centered brand title
                    Text("branchr")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .kerning(0.5)
                        .foregroundColor(theme.primaryText)
                    
                    // Theme toggle aligned to trailing edge
                    HStack {
                        Spacer()
                        Button(action: { theme.toggleTheme() }) {
                            Image(systemName: theme.isDarkMode ? "sun.max.fill" : "moon.fill")
                                .font(.title3)
                                .foregroundColor(theme.accentColor)
                                .frame(width: 44, height: 44)
                                .background(theme.cardBackground)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16) // Spacing above main buttons
                
                // Phase 59: Extra spacer to push content lower
                Spacer()
                    .frame(height: 24)
                
                // MARK: - Main Actions (Phase 2: Unified Button System)
                // Phase 52: Primary action buttons only - status/controls moved to RideControlPanelView
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
                            RideSessionManager.shared.startSoloRide(musicSource: musicSourceMode)
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
                
                // MARK: - Phase 52: Ride Control & Audio Panel
                RideControlPanelView(
                    preferredMusicSource: $musicSourceMode,
                    connectionManager: connectionManager,
                    rideService: rideService,
                    userPreferences: userPreferences,
                    totalThisWeekMiles: totalThisWeekMiles,
                    goalMiles: userPreferences.weeklyDistanceGoalMiles,
                    currentStreakDays: currentStreakDays,
                    bestStreakDays: bestStreakDays,
                    isVoiceMuted: $isVoiceMuted,
                    isMusicMuted: $isMusicMuted,
                    onToggleMute: handleToggleMute,
                    onToggleMusic: handleToggleMusic,
                    onDJControlsTap: handleDJControlsTap
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .onChange(of: musicSourceMode) { newMode in
                    // Phase 57: Sync musicSourceMode with userPreferences and musicSync
                    userPreferences.preferredMusicSource = newMode
                    musicSync.setMusicSourceMode(newMode)
                }
                
                // Phase 59: Minimal bottom spacing - card should almost touch tab bar
                Spacer()
                    .frame(height: 10) // Small gap above tab bar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .onAppear {
                print("🏁 HomeView loaded - ready for Start Connection")
                // Phase 28: Start listening for SOS alerts
                fcmService.startListeningForSOSAlerts()
                // Phase 41: Update goal and streak data
                updateGoalAndStreakData()
                // Phase 57: Initialize musicSourceMode from userPreferences
                musicSourceMode = userPreferences.preferredMusicSource
                musicSync.setMusicSourceMode(musicSourceMode)
            }
            .onChange(of: rideDataManager.rides.count) { _ in
                // Phase 41: Update when rides change
                updateGoalAndStreakData()
            }
            .onChange(of: userPreferences.weeklyDistanceGoalMiles) { _ in
                // Phase 41: Update when goal changes
                updateGoalAndStreakData()
            }
            .onChange(of: fcmService.latestSOSAlert) { alert in
                // Show banner when new SOS alert arrives
                if alert != nil {
                    showSOSBanner = true
                }
            }
            // Phase 41C: Theme toggle moved to compact header, removed from toolbar
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
            DJControlsSheetView(
                musicService: MusicService.shared,
                musicSyncService: musicSync,
                musicSourceMode: $musicSourceMode
            )
            .presentationDetents([.medium, .large])
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
    
    // MARK: - Phase 28: SOS Alert Helpers
    
    /// Open Apple Maps with SOS location
    private func openMap(latitude: Double, longitude: Double) {
        if let url = URL(string: "https://maps.apple.com/?q=\(latitude),\(longitude)") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Phase 41: Weekly Goal & Streak Helpers
    
    /// Update goal and streak data from RideDataManager
    private func updateGoalAndStreakData() {
        totalThisWeekMiles = rideDataManager.totalDistanceThisWeek()
        currentStreakDays = rideDataManager.currentStreakDays()
        bestStreakDays = rideDataManager.bestStreakDays()
    }
    
    // MARK: - Phase 44: Audio Control Handlers (used by RideControlPanelView)
    
    /// Handle mute toggle with haptics
    private func handleToggleMute() {
        isVoiceMuted.toggle()
        AudioManager.shared.toggleVoiceChat(active: !isVoiceMuted)
        HapticsService.shared.lightTap()
        print(isVoiceMuted ? "Voice muted" : "Voice unmuted")
    }
    
    /// Handle music toggle with haptics
    private func handleToggleMusic() {
        isMusicMuted.toggle()
        if isMusicMuted {
            AudioManager.shared.stopMusic()
        }
        HapticsService.shared.lightTap()
        print(isMusicMuted ? "Music muted" : "Music unmuted")
    }
    
    /// Handle DJ controls tap with haptics
    private func handleDJControlsTap() {
        showDJSheet.toggle()
        HapticsService.shared.mediumTap()
        print("DJ Controls tapped - opening sheet")
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

// MARK: - Phase 44: Audio Control Button Component

// MARK: - Control Button Component (Legacy - kept for compatibility)

struct ControlButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            // Phase 41B: More compact layout
            // Phase 41J: Updated colors for black card background
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.brandYellow) // Brand yellow for icons on black
                    .frame(width: 44, height: 44)
                    .background(theme.cardBackground)
                    .cornerRadius(10)
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.9)) // White labels for readability on black
            }
        }
    }
}

// MARK: - Phase 51: Music Source Selector

struct MusicSourceSelectorView: View {
    @Binding var selectedSource: MusicSourceMode
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        // Phase 54: Removed "Music Source" label, keep only selector pills
        HStack(spacing: 12) {
            ForEach(MusicSourceMode.allCases) { source in
                Button {
                    selectedSource = source
                    HapticsService.shared.lightTap()
                    print("Branchr: Music source changed to \(source.title)")
                    // Phase 57: Changes are synced via onChange in HomeView
                } label: {
                    HStack(spacing: 8) {
                        brandedLogo(for: source)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(source.title)
                                .font(.caption.bold())
                            Text(source.subtitle)
                                .font(.caption2)
                                .opacity(0.7)
                        }
                    }
                    .foregroundColor(selectedSource == source ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selectedSource == source ? theme.brandYellow : theme.surfaceBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selectedSource == source ? theme.brandYellow : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Phase 59: Safe Branded Logo Helper
    
    /// Returns branded logo image if available, falls back to SF Symbol
    private func brandedLogo(for mode: MusicSourceMode) -> Image {
        if UIImage(named: mode.assetName) != nil {
            return Image(mode.assetName)
        } else {
            // Failsafe – fall back to SF Symbol to avoid log spam
            return Image(systemName: mode.systemIconName)
        }
    }
}

#Preview {
    HomeView()
}

