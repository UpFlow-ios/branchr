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
            GeometryReader { geometry in
                VStack(spacing: 12) {

                            // MARK: - Phase 28: SOS Alert Banner
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
                                        Capsule()
                                            .fill(Color.red.opacity(0.95))
                                    )
                                    .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 5)
                                }
                                .padding(.horizontal, 16)
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

                            Spacer()
                                .frame(height: 8)

                            // MARK: - Ride Control Panel (large glass card)
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
                            .padding(.top, 8)
                            .onChange(of: musicSourceMode) { newMode in
                                userPreferences.preferredMusicSource = newMode
                                musicSync.setMusicSourceMode(newMode)
                            }

                            // MARK: - Audio Controls Row (Unmuted / DJ / Music On)
                            if #available(iOS 26.0, *) {
                                GlassEffectContainer(spacing: 16) {
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
                                .padding(.top, 8)
                            } else {
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
                                .padding(.top, 8)
                            }

                            // MARK: - Main Actions (glass pill buttons)
                            if #available(iOS 26.0, *) {
                                GlassEffectContainer {
                                    VStack(spacing: 14) {
                                    // Start / Resume Ride Tracking
                                    GlassActionButton(
                                        title: primaryRideActionTitle,
                                        systemImage: nil,
                                        isProminent: true,
                                        isActive: rideSession.rideState == .active
                                    ) {
                                        if rideSession.rideState == .idle || rideSession.rideState == .ended {
                                            RideSessionManager.shared.startSoloRide(musicSource: musicSourceMode)
                                            withAnimation(.spring()) { showSmartRideSheet = true }
                                        } else {
                                            withAnimation(.spring()) { showSmartRideSheet = true }
                                        }
                                    }
                                    .frame(height: 54)
                                    .rainbowGlow(active: rideSession.rideState == .active)

                                    // Start / Stop Connection
                                    GlassActionButton(
                                        title: connectionManager.state == .connected
                                        ? "Stop Connection"
                                        : connectionManager.state == .connecting
                                        ? "Connecting..."
                                        : "Start Connection",
                                        systemImage: nil,
                                        isProminent: false,
                                        isActive: connectionManager.state == .connecting || connectionManager.state == .connected
                                    ) {
                                        connectionManager.toggleConnection()
                                    }
                                    .frame(height: 54)
                                    .rainbowGlow(active: connectionManager.state == .connecting || connectionManager.state == .connected)

                                    // Connected Riders list (unchanged logic / layout)
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

                                    // Start / End Voice Chat
                                    GlassActionButton(
                                        title: voiceService.isVoiceChatActive ? "End Voice Chat" : "Start Voice Chat",
                                        systemImage: voiceService.isVoiceChatActive ? "mic.slash.fill" : "mic.fill",
                                        isProminent: false,
                                        isActive: voiceService.isVoiceChatActive
                                    ) {
                                        if voiceService.isVoiceChatActive {
                                            voiceService.stopVoiceChat()
                                        } else {
                                            voiceService.startVoiceChat()
                                        }
                                    }
                                    .frame(height: 54)
                                    .rainbowGlow(active: voiceService.isVoiceChatActive)

                                    // Safety & SOS
                                    GlassActionButton(
                                        title: "Safety & SOS",
                                        systemImage: "exclamationmark.triangle.fill",
                                        isProminent: false,
                                        isActive: false
                                    ) {
                                        showingSafetySettings = true
                                    }
                                    .frame(height: 54)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)

                            Spacer()
                                .frame(height: 8)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
                        .background(
                            RadialGradient(
                                colors: [
                                    Color.gray.opacity(0.8),
                                    Color.black.opacity(0.9)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 500
                            )
                            .ignoresSafeArea()
                        )
                } else {
                    // Fallback for iOS < 26
                    VStack(spacing: 12) {

                        // MARK: - Phase 28: SOS Alert Banner
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
                                    Capsule()
                                        .fill(Color.red.opacity(0.95))
                                )
                                .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal, 16)
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

                        Spacer()
                            .frame(height: 8)

                        // MARK: - Ride Control Panel (large glass card)
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
                        .padding(.top, 8)
                        .onChange(of: musicSourceMode) { newMode in
                            userPreferences.preferredMusicSource = newMode
                            musicSync.setMusicSourceMode(newMode)
                        }

                        // MARK: - Audio Controls Row (Unmuted / DJ / Music On)
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
                        .padding(.top, 8)

                        // MARK: - Main Actions (glass pill buttons)
                        VStack(spacing: 14) {
                            // Start / Resume Ride Tracking
                            GlassActionButton(
                                title: primaryRideActionTitle,
                                systemImage: nil,
                                isProminent: true,
                                isActive: rideSession.rideState == .active
                            ) {
                                if rideSession.rideState == .idle || rideSession.rideState == .ended {
                                    RideSessionManager.shared.startSoloRide(musicSource: musicSourceMode)
                                    withAnimation(.spring()) { showSmartRideSheet = true }
                                } else {
                                    withAnimation(.spring()) { showSmartRideSheet = true }
                                }
                            }
                            .frame(height: 54)
                            .rainbowGlow(active: rideSession.rideState == .active)

                            // Start / Stop Connection
                            GlassActionButton(
                                title: connectionManager.state == .connected
                                ? "Stop Connection"
                                : connectionManager.state == .connecting
                                ? "Connecting..."
                                : "Start Connection",
                                systemImage: nil,
                                isProminent: false,
                                isActive: connectionManager.state == .connecting || connectionManager.state == .connected
                            ) {
                                connectionManager.toggleConnection()
                            }
                            .frame(height: 54)
                            .rainbowGlow(active: connectionManager.state == .connecting || connectionManager.state == .connected)

                            // Connected Riders list (unchanged logic / layout)
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

                            // Start / End Voice Chat
                            GlassActionButton(
                                title: voiceService.isVoiceChatActive ? "End Voice Chat" : "Start Voice Chat",
                                systemImage: voiceService.isVoiceChatActive ? "mic.slash.fill" : "mic.fill",
                                isProminent: false,
                                isActive: voiceService.isVoiceChatActive
                            ) {
                                if voiceService.isVoiceChatActive {
                                    voiceService.stopVoiceChat()
                                } else {
                                    voiceService.startVoiceChat()
                                }
                            }
                            .frame(height: 54)
                            .rainbowGlow(active: voiceService.isVoiceChatActive)

                            // Safety & SOS
                            GlassActionButton(
                                title: "Safety & SOS",
                                systemImage: "exclamationmark.triangle.fill",
                                isProminent: false,
                                isActive: false
                            ) {
                                showingSafetySettings = true
                            }
                            .frame(height: 54)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        Spacer()
                            .frame(height: 8)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.9),
                                Color.gray.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    )
                }
            .onAppear {
                print("🏁 HomeView loaded - ready for Start Connection")
                fcmService.startListeningForSOSAlerts()
                updateGoalAndStreakData()
                musicSourceMode = userPreferences.preferredMusicSource
                musicSync.setMusicSourceMode(musicSourceMode)
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
            RideOptionsSheet(
                rideService: rideService,
                showSummary: $showRideSummary,
                dismiss: $showRideOptions
            )
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

// MARK: - Audio Control Button (glassy compact buttons)

struct AudioControlButton: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .background(
                        Group {
                            if isActive {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(theme.brandYellow)
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .foregroundColor(isActive ? .black : .white)

                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(isActive ? 1.0 : 0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .branchrGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous), interactive: true)
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

// MARK: - Glass Action Button (shared for big pill buttons)

struct GlassActionButton: View {
    let title: String
    let systemImage: String?
    let isProminent: Bool
    let isActive: Bool
    let action: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        let radius: CGFloat = isProminent ? 26 : 22
        
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, isProminent ? 14 : 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(isActive ? 0.35 : 0.18), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(isProminent ? 0.45 : 0.30),
                radius: isProminent ? 24 : 18,
                x: 0,
                y: isProminent ? 16 : 12
            )
            .overlay(
                LinearGradient(
                    colors: [
                        theme.brandYellow.opacity(isActive ? 0.0 : 0.0),
                        theme.brandYellow.opacity(isActive ? 0.7 : 0.0),
                        theme.brandYellow.opacity(isActive ? 0.0 : 0.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: isActive ? 3 : 0)
                .cornerRadius(999),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
