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
    @ObservedObject private var musicService = MusicService.shared
    
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
    
    // Phase 74: Primary ride action title
    private var primaryRideActionTitle: String {
        let hasActiveRide = rideSession.rideState == .active || rideSession.rideState == .paused
        return hasActiveRide ? "Resume Ride Tracking" : "Start Ride Tracking"
    }
    @State private var showRideOptions = false
    @State private var showRideSummary = false
    
    // Phase 57: Music source mode state (syncs with userPreferences and musicSync)
    @State private var musicSourceMode: MusicSourceMode = UserPreferenceManager.shared.preferredMusicSource
    @State private var isSOSArmed: Bool = false
    
    var body: some View {
        ZStack {
            // MARK: - Ambient Background (Phase 76: Live blurred artwork)
            AmbientBackground(artwork: musicService.lastArtworkImage)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // SOS Alert Banner (if active)
                    if let alert = fcmService.latestSOSAlert, showSOSBanner {
                        Button(action: {
                            showSOSBanner = false
                            openMap(latitude: alert.latitude, longitude: alert.longitude)
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
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
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.red)
                            )
                            .shadow(color: .red.opacity(0.6), radius: 15, x: 0, y: 8)
                        }
                        .padding(.horizontal, 24)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showSOSBanner)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                withAnimation {
                                    showSOSBanner = false
                                }
                            }
                        }
                    }
                    
                    // TOP MODE / STATUS BANNER
                    ModeStatusBannerView()
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                    
                    // MAIN MUSIC / RIDE CARD
                    RideControlPanelView(
                        preferredMusicSource: $musicSourceMode,
                        connectionManager: connectionManager,
                        rideService: rideService,
                        userPreferences: userPreferences,
                        totalThisWeekMiles: totalThisWeekMiles,
                        goalMiles: userPreferences.weeklyDistanceGoalMiles,
                        currentStreakDays: currentStreakDays,
                        bestStreakDays: bestStreakDays
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .background(Color.clear)
                    
                    // AUDIO CONTROL ROW
                    HStack(spacing: 16) {
                        AudioControlButton(
                            icon: isVoiceMuted ? "mic.slash.fill" : "mic.fill",
                            title: isVoiceMuted ? "Muted" : "Unmuted",
                            isActive: !isVoiceMuted
                        ) {
                            handleToggleMute()
                        }
                        
                        AudioControlButton(
                            icon: "music.quarternote.3",
                            title: "DJ Controls",
                            isActive: false
                        ) {
                            handleDJControlsTap()
                        }
                        
                        AudioControlButton(
                            icon: isMusicMuted ? "speaker.slash.fill" : "music.note",
                            title: isMusicMuted ? "Music Off" : "Music On",
                            isActive: !isMusicMuted
                        ) {
                            handleToggleMusic()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    
                    // MAIN ACTIONS – hero + grid
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2),
                        spacing: 14
                    ) {
                        // 🍍 HERO: Start / Resume Ride – full width
                        GlassGridButton(
                            title: primaryRideActionTitle,
                            systemImage: nil,
                            tint: Color.white.opacity(0.14),
                            textColor: .white,
                            isActive: rideSession.rideState == .active || rideSession.rideState == .paused
                        ) {
                            handlePrimaryRideTapped()
                        }
                        .gridCellColumns(2)   // ⬅️ full-width hero button
                        
                        // 🔌 Connection
                        GlassGridButton(
                            title: connectionManager.state == .connected
                            ? "Stop Connection"
                            : connectionManager.state == .connecting
                              ? "Connecting..."
                              : "Start Connection",
                            systemImage: nil,
                            tint: Color.white.opacity(0.14),
                            textColor: .white,
                            isActive: connectionManager.state == .connected
                        ) {
                            handleConnectionTapped()
                        }
                        
                        // 🎙 Voice Chat
                        GlassGridButton(
                            title: voiceService.isVoiceChatActive ? "End Voice Chat" : "Start Voice Chat",
                            systemImage: voiceService.isVoiceChatActive ? "mic.slash.fill" : "mic.fill",
                            tint: Color.white.opacity(0.14),
                            textColor: .white,
                            isActive: voiceService.isVoiceChatActive
                        ) {
                            handleVoiceChatTapped()
                        }
                        
                        // 🚨 SOS – full width at the bottom, red accent
                        GlassGridButton(
                            title: "SOS",
                            systemImage: "exclamationmark.triangle.fill",
                            tint: Color.red.opacity(0.28),
                            textColor: .white,
                            isActive: isSOSArmed
                        ) {
                            handleSOSTapped()
                        }
                        .gridCellColumns(2)   // ⬅️ full-width safety strip
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    Spacer(minLength: 32)
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            handleOnAppear()
        }
        .onChange(of: rideDataManager.rides.count) { _ in
            updateGoalAndStreakData()
        }
        .onChange(of: userPreferences.weeklyDistanceGoalMiles) { _ in
            updateGoalAndStreakData()
        }
        .onChange(of: fcmService.latestSOSAlert) { alert in
            if alert != nil {
                showSOSBanner = true
            }
        }
        .onChange(of: rideSession.rideState) { state in
            if state == .active || state == .paused {
                withAnimation(.spring()) { showSmartRideSheet = true }
            }
        }
        .onChange(of: musicSourceMode) { newMode in
            userPreferences.preferredMusicSource = newMode
            musicSync.setMusicSourceMode(newMode)
        }
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
            SOSView()
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
        .sheet(isPresented: $showSmartRideSheet) {
            RideSheetView()
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $showRideSummary) {
            Phase20RideSummaryView(rideService: rideService)
        }
        .sheet(isPresented: $showRideTracking) {
            RideTrackingView()
                .ignoresSafeArea()
                .presentationDetents([.large, .fraction(0.3)], selection: $rideDetent)
                .presentationDragIndicator(.visible)
                .onAppear {
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
    
    // MARK: - New Action Handlers
    
    /// Handle onAppear lifecycle
    private func handleOnAppear() {
        print("🏁 HomeView loaded - ready for Start Connection")
        fcmService.startListeningForSOSAlerts()
        updateGoalAndStreakData()
        musicSourceMode = userPreferences.preferredMusicSource
        musicSync.setMusicSourceMode(musicSourceMode)
    }
    
    /// Handle primary ride button tap
    private func handlePrimaryRideTapped() {
        if rideSession.rideState == .idle || rideSession.rideState == .ended {
            RideSessionManager.shared.startSoloRide(musicSource: musicSourceMode)
            withAnimation(.spring()) { showSmartRideSheet = true }
        } else {
            withAnimation(.spring()) { showSmartRideSheet = true }
        }
        HapticsService.shared.mediumTap()
    }
    
    /// Handle connection button tap
    private func handleConnectionTapped() {
        connectionManager.toggleConnection()
        HapticsService.shared.mediumTap()
    }
    
    /// Handle voice chat button tap
    private func handleVoiceChatTapped() {
        if voiceService.isVoiceChatActive {
            voiceService.stopVoiceChat()
        } else {
            voiceService.startVoiceChat()
        }
        HapticsService.shared.mediumTap()
    }
    
    /// Handle SOS button tap
    private func handleSOSTapped() {
        showingSafetySettings = true
        HapticsService.shared.heavyTap()
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

// MARK: - Glass Grid Button with Rainbow Glow on Press
// Phase 76: Enhanced with isActive parameter for persistent rainbow halo
private struct GlassGridButton: View {
    let title: String
    let systemImage: String?
    let tint: Color
    let textColor: Color
    let isActive: Bool // Phase 76: Shows rainbow halo when feature is active
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundColor(textColor)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(textColor.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .rainbowGlow(active: isActive || isPressed) // Phase 76: Show halo when active OR pressed
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticsService.shared.lightTap()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
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
                    ZStack {
                        // Background pill – glass for selected, solid dark for unselected
                        if selectedSource == source {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(theme.brandYellow, lineWidth: 2)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(theme.surfaceBackground)
                        }
                        
                        // Centered badge image only
                        brandedLogo(for: source)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40) // was 32 – make badge bigger
                            .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52) // pill height similar to old yellow pill
                }
                .buttonStyle(.plain)
            }
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

#Preview {
    HomeView()
}

