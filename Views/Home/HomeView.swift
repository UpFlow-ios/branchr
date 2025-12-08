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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Full-screen black background
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Spacer(minLength: 0)
                    
                    mainRideCard
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                    
                    Spacer(minLength: 12)
                }
            }
            .onAppear {
                print("🏁 HomeView loaded - ready for Start Connection")
                fcmService.startListeningForSOSAlerts()
                updateGoalAndStreakData()
                musicSourceMode = userPreferences.preferredMusicSource
                musicSync.setMusicSourceMode(musicSourceMode)
                if musicSourceMode == .appleMusicSynced {
                    musicService.refreshNowPlayingFromNowPlayingInfoCenter()
                }
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
            .onChange(of: musicSourceMode) { newMode in
                userPreferences.preferredMusicSource = newMode
                musicSync.setMusicSourceMode(newMode)
                if newMode == .appleMusicSynced {
                    musicService.refreshNowPlayingFromNowPlayingInfoCenter()
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
        .sheet(isPresented: $showSmartRideSheet) {
            RideSheetView()
                .presentationDetents([.large])
        }
        .onChange(of: rideSession.rideState) { state in
            if state == .active || state == .paused {
                withAnimation(.spring()) { showSmartRideSheet = true }
            }
        }
    }
    
    // MARK: - Main Card Container
    
    private var mainRideCard: some View {
        ZStack(alignment: .topTrailing) {
            // Card content
            VStack(alignment: .leading, spacing: 20) {
                // Top spacing so connection pill doesn't overlap
                Spacer().frame(height: 8)
                
                nowPlayingBlock
                
                weeklyGoalSection
                
                pillControlsRow
                
                primaryActionButtons
            }
            .padding(20)
            
            connectionStatusPill
                .padding(.top, 12)
                .padding(.trailing, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(.systemGray6).opacity(0.15))
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Connection Status Pill
    
    private var connectionStatusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connectionStatusColor)
                .frame(width: 10, height: 10)
            
            Text(connectionText)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(.systemGray5).opacity(0.2))
        )
    }
    
    private var connectionText: String {
        if rideService.rideState == .active || rideService.rideState == .paused {
            if !connectionManager.isConnected {
                return "Solo Ride"
            }
        }
        if connectionManager.isConnected {
            return "Connected"
        } else if connectionManager.state == .connecting {
            return "Connecting..."
        } else {
            return "Disconnected"
        }
    }
    
    private var connectionStatusColor: Color {
        if (rideService.rideState == .active || rideService.rideState == .paused) && !connectionManager.isConnected {
            return Color.branchrAccent
        } else if connectionManager.isConnected {
            return .green
        } else {
            return .red
        }
    }
    
    // MARK: - Now Playing Block
    
    private var nowPlayingBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Large tile
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemGray6).opacity(0.15))
                
                if let nowPlaying = musicService.nowPlaying,
                   let artwork = nowPlaying.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(theme.brandYellow.opacity(0.6))
                        
                        Text("No Music Playing")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(height: 220)
            
            // Text below
            VStack(alignment: .leading, spacing: 4) {
                Text(currentTrackTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(currentArtistName)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var currentTrackTitle: String {
        if let nowPlaying = musicService.nowPlaying {
            return nowPlaying.title
        }
        return "No song playing"
    }
    
    private var currentArtistName: String {
        if let nowPlaying = musicService.nowPlaying {
            return nowPlaying.artist
        }
        return ""
    }
    
    // MARK: - Weekly Goal Section
    
    private var weeklyGoalSection: some View {
        WeeklyGoalCardView(
            totalThisWeekMiles: totalThisWeekMiles,
            goalMiles: userPreferences.weeklyDistanceGoalMiles,
            currentStreakDays: currentStreakDays,
            bestStreakDays: bestStreakDays
        )
        .padding(.top, 4)
    }
    
    // MARK: - Pill Controls Row
    
    private var pillControlsRow: some View {
        HStack(spacing: 12) {
            PillControlButton(
                iconName: isVoiceMuted ? "mic.slash.fill" : "mic.fill",
                title: isVoiceMuted ? "Muted" : "Unmuted",
                isActive: !isVoiceMuted
            ) {
                handleToggleMute()
            }
            
            PillControlButton(
                iconName: "slider.horizontal.3",
                title: "DJ Controls",
                isActive: showDJSheet
            ) {
                handleDJControlsTap()
            }
            
            PillControlButton(
                iconName: "music.note.list",
                title: "Music",
                isActive: !isMusicMuted
            ) {
                handleToggleMusic()
            }
        }
    }
    
    // MARK: - Primary Action Buttons
    
    private var primaryActionButtons: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                primaryRideActionTitle,
                systemImage: nil,
                isHero: true,
                isNeonHalo: true,
                disableOuterGlow: true
            ) {
                if rideSession.rideState == .idle || rideSession.rideState == .ended {
                    RideSessionManager.shared.startSoloRide(musicSource: musicSourceMode)
                    withAnimation(.spring()) { showSmartRideSheet = true }
                } else {
                    withAnimation(.spring()) { showSmartRideSheet = true }
                }
            }
            .rainbowGlow(active: rideSession.rideState == .active)
            
            PrimaryButton(
                connectionManager.state == .connected
                    ? "Stop Connection"
                    : connectionManager.state == .connecting
                      ? "Connecting..."
                      : "Start Connection",
                systemImage: nil,
                isHero: false,
                isNeonHalo: true
            ) {
                connectionManager.toggleConnection()
            }
            .rainbowGlow(active: connectionManager.state == .connecting || connectionManager.state == .connected)
            
            PrimaryButton(
                voiceService.isVoiceChatActive ? "End Voice Chat" : "Start Voice Chat",
                systemImage: voiceService.isVoiceChatActive ? "mic.slash.fill" : "mic.fill",
                isHero: false,
                isNeonHalo: true
            ) {
                if voiceService.isVoiceChatActive {
                    voiceService.stopVoiceChat()
                } else {
                    voiceService.startVoiceChat()
                }
            }
            .rainbowGlow(active: voiceService.isVoiceChatActive)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Phase 28: SOS Alert Helpers
    
    private func openMap(latitude: Double, longitude: Double) {
        if let url = URL(string: "https://maps.apple.com/?q=\(latitude),\(longitude)") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Phase 41: Weekly Goal & Streak Helpers
    
    private func updateGoalAndStreakData() {
        totalThisWeekMiles = rideDataManager.totalDistanceThisWeek()
        currentStreakDays = rideDataManager.currentStreakDays()
        bestStreakDays = rideDataManager.bestStreakDays()
    }
    
    // MARK: - Phase 44: Audio Control Handlers
    
    private func handleToggleMute() {
        isVoiceMuted.toggle()
        AudioManager.shared.toggleVoiceChat(active: !isVoiceMuted)
        HapticsService.shared.lightTap()
        print(isVoiceMuted ? "Voice muted" : "Voice unmuted")
    }
    
    private func handleToggleMusic() {
        isMusicMuted.toggle()
        if isMusicMuted {
            AudioManager.shared.stopMusic()
        }
        HapticsService.shared.lightTap()
        print(isMusicMuted ? "Music muted" : "Music unmuted")
    }
    
    private func handleDJControlsTap() {
        showDJSheet.toggle()
        HapticsService.shared.mediumTap()
        print("DJ Controls tapped - opening sheet")
    }
    
    // MARK: - Ride Tracking
    
    private func handleRideButtonPress() {
        switch rideService.rideState {
        case .idle, .ended:
            rideService.startRide()
            if !locationService.isTracking {
                locationService.startTracking()
            }
        case .active:
            showRideOptions = true
        case .paused:
            rideService.resumeRide()
        }
    }
}

// MARK: - Pill Control Button

private struct PillControlButton: View {
    let iconName: String?
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? Color.yellow.opacity(0.25) : Color(.systemGray5).opacity(0.25))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Control Button Component (Legacy - kept for compatibility)

struct ControlButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(theme.brandYellow)
                    .frame(width: 44, height: 44)
                    .background(theme.cardBackground)
                    .cornerRadius(10)
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.9))
            }
        }
    }
}

// MARK: - Phase 51: Music Source Selector

struct MusicSourceSelectorView: View {
    @Binding var selectedSource: MusicSourceMode
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(MusicSourceMode.allCases) { source in
                Button {
                    selectedSource = source
                    HapticsService.shared.lightTap()
                    print("Branchr: Music source changed to \(source.title)")
                } label: {
                    ZStack {
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
                        
                        brandedLogo(for: source)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.horizontal, 12)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func brandedLogo(for mode: MusicSourceMode) -> Image {
        if UIImage(named: mode.assetName) != nil {
            return Image(mode.assetName)
                .renderingMode(.original)
        } else {
            return Image(systemName: mode.systemIconName)
                .renderingMode(.template)
        }
    }
}

#Preview {
    HomeView()
}
