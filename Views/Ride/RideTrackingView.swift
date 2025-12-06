//
//  RideTrackingView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-04
//  Phase 31 - Unified Ride Tracking Flow (Sheet View)
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit
import Combine
import EventKit

/**
 * 🚴‍♂️ Ride Tracking View
 *
 * Unified ride tracking interface launched from HomeView as a sheet.
 * Features:
 * - Real-time map with route tracking
 * - Distance, time, and speed stats
 * - Play/Stop controls
 * - Voice announcements
 * - Branchr black/yellow theme
 */
struct RideTrackingView: View {
    @ObservedObject private var rideService = RideTrackingService.shared // Phase 35A: Use shared singleton
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var preferences = UserPreferenceManager.shared
    @StateObject private var speechCommands = SpeechCommandService()
    @ObservedObject private var profileManager = ProfileManager.shared // Phase 5: Profile data
    @ObservedObject private var connectionManager = ConnectionManager.shared // Phase 5: Connection status
    @ObservedObject private var musicSync = MusicSyncService.shared // Phase 5: Music status
    @ObservedObject private var musicService = MusicService.shared // Phase 64: Now Playing strip
    @Environment(\.dismiss) private var dismiss

    @State private var showRideSummary = false // Phase 31: Ride summary sheet
    @State private var lastAnnouncedDistance: Double = 0.0
    @State private var lastAnnouncedTime: TimeInterval = 0.0

    // Phase 35B: Rainbow pulse countdown state
    @State private var countdown = 5
    @State private var progress: Double = 0
    @State private var isStopping = false
    @State private var countdownTimer: Timer?
    private let haptic = UINotificationFeedbackGenerator()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    // Phase 4: Selected rider for info panel
    @State private var selectedRider: UserAnnotation? = nil

    // Phase 35A: Store cancellables for notification subscription
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                // Phase 73: Map touches buttons - no gap
                let bottomInset = max(proxy.safeAreaInsets.bottom, 16)
                
                ZStack(alignment: .topLeading) {
                    // 1) BACKGROUND
                    theme.primaryBackground.ignoresSafeArea()
                    
                    // 2) MAIN CONTENT - Phase 73: Map fills to buttons, no gap
                    VStack(spacing: 0) {
                        // Phase 57: Grabber handle at top
                        grabberHandle
                            .padding(.top, 8)
                        
                        // Phase 73: Map + HUD overlay (fills to buttons)
                        ZStack(alignment: .top) {
                            // Map section - fills all available space
                            RideMapViewRepresentable(
                                region: $region,
                                coordinates: rideService.route,
                                showsUserLocation: true,
                                riderAnnotations: [],
                                selectedRider: $selectedRider
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: Color.black.opacity(0.45), radius: 20, x: 0, y: 16)
                            .onChange(of: rideService.route.count) { _ in
                                updateMapRegion()
                            }
                            
                            // Phase 70: Host HUD overlay on map (floating card)
                            VStack {
                                if rideService.rideState == .active || rideService.rideState == .paused {
                                    RideHostHUDView(
                                        hostName: profileManager.currentDisplayName,
                                        hostImage: profileManager.currentProfileImage,
                                        distanceMiles: rideService.totalDistanceMiles,
                                        speedMph: rideService.currentSpeedMph,
                                        durationText: rideService.formattedDuration,
                                        isConnected: connectionManager.state == .connected,
                                        isMusicOn: musicSync.currentTrack?.isPlaying ?? false,
                                        musicSourceMode: musicSync.musicSourceMode,
                                        nowPlaying: musicService.nowPlaying,
                                        isPlaying: musicService.isPlaying,
                                        onPrevious: {
                                            HapticsService.shared.lightTap()
                                            musicService.skipToPreviousTrack()
                                        },
                                        onTogglePlayPause: {
                                            HapticsService.shared.mediumTap()
                                            musicService.togglePlayPause()
                                        },
                                        onNext: {
                                            HapticsService.shared.lightTap()
                                            musicService.skipToNextTrack()
                                        }
                                    )
                                    .padding(.top, 24)
                                }
                                
                                Spacer() // Lets the map fill the remaining space
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Phase 73: Buttons directly below map (no spacer)
                        rideControls
                            .padding(.horizontal, 24)
                            .padding(.top, 0) // No gap between map and buttons
                            .padding(.bottom, bottomInset)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .ignoresSafeArea(edges: .bottom)
                }

                // Phase 43C: Host HUD moved to top header strip (removed from map overlay)

                // 4) RIDER INFO PANEL (BOTTOM SHEET)
                if let rider = selectedRider {
                    VStack {
                        Spacer()
                        RiderInfoPanel(
                            name: rider.name,
                            speed: rideService.speedFor(riderID: rider.riderID),
                            distance: rideService.distanceFromHost(riderID: rider.riderID),
                            profileImage: rider.profileImage,
                            isHost: rider.isHost
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8),
                            value: selectedRider?.riderID
                        )
                    }
                }

                // 5) RAINBOW PULSE COUNTDOWN OVERLAY
                if isStopping {
                    ZStack {
                        RainbowPulseView(progress: $progress)
                            .frame(width: 300, height: 300)
                            .transition(.opacity)

                        Text("Stopping ride in \(countdown)")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                            .shadow(radius: 8)
                            .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4).ignoresSafeArea())
                    .onAppear { playCountdown() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onAppear {
            print("🚴 RideTrackingView (Phase 5B) loaded")
            if rideService.rideState == .idle {
                updateMapRegion()
            }

            // Wire up voice commands
            speechCommands.setEnabled(preferences.voiceCommandsEnabled)
            if preferences.voiceCommandsEnabled {
                speechCommands.startListening()
            }
            
            // Phase 64: Refresh now playing when ride view appears (only for Apple Music mode)
            if musicSync.musicSourceMode == .appleMusicSynced {
                Task { @MainActor in
                    musicService.refreshNowPlayingFromNowPlayingInfoCenter()
                    print("Branchr RideTrackingView: Refreshed now playing for Apple Music mode")
                }
            }
        }
        .sheet(isPresented: $showRideSummary) {
            if let rideRecord = createRideRecord() {
                EnhancedRideSummaryView(
                    ride: rideRecord,
                    onDone: {
                        handleRideSummaryDone()
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            } else {
                Phase20RideSummaryView(rideService: rideService)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onDisappear {
            speechCommands.stopListening()
        }
        .onChange(of: speechCommands.detectedCommand) { command in
            guard let cmd = command else { return }
            switch cmd {
            case .pause:
                rideService.pauseRide()
                VoiceFeedbackService.shared.speak("Ride paused")
                RideHaptics.milestone()
            case .resume:
                rideService.resumeRide()
                VoiceFeedbackService.shared.speak("Ride resumed")
                RideHaptics.milestone()
            case .stop:
                rideService.endRide()
                VoiceFeedbackService.shared.speak("Ride ended")
                showRideSummary = true
                RideHaptics.milestone()
            case .status:
                speakStatus()
            }
        }
        .onChange(of: rideService.totalDistance) { distance in
            if preferences.distanceUpdatesEnabled {
                let miles = distance / 1609.34
                let milestone = Int(miles / 0.25)
                let lastMilestone = Int(lastAnnouncedDistance / 1609.34 / 0.25)

                if milestone > lastMilestone && milestone > 0 {
                    VoiceFeedbackService.shared.speak("Distance, \(String(format: "%.2f", miles)) miles")
                    lastAnnouncedDistance = distance
                    RideHaptics.milestone()
                }
            }
        }
        .onChange(of: rideService.duration) { duration in
            if preferences.paceOrSpeedUpdatesEnabled && rideService.rideState == .active {
                let timeDiff = duration - lastAnnouncedTime
                if timeDiff >= 60.0 {
                    let speed = rideService.averageSpeed * 0.621371
                    VoiceFeedbackService.shared.speak("Average speed, \(String(format: "%.1f", speed)) miles per hour")
                    lastAnnouncedTime = duration
                    RideHaptics.milestone()
                }
            }
        }
        .onChange(of: rideService.rideState) { state in
            if state == .ended && preferences.completionSummaryEnabled {
                let miles = rideService.totalDistance / 1609.34
                let hours = Int(rideService.duration) / 3600
                let minutes = (Int(rideService.duration) % 3600) / 60
                let speed = rideService.averageSpeed * 0.621371

                var summary = "Ride complete. "
                summary += "Total distance, \(String(format: "%.2f", miles)) miles. "
                if hours > 0 {
                    summary += "Time, \(hours) hours \(minutes) minutes. "
                } else {
                    summary += "Time, \(minutes) minutes. "
                }
                summary += "Average speed, \(String(format: "%.1f", speed)) miles per hour."

                VoiceFeedbackService.shared.speak(summary)
                RideHaptics.milestone()
            }
        }
    }

    // MARK: - Phase 42: UI Components
    
    /// Phase 57: Grabber handle at top of ride view
    private var grabberHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.25))
            .frame(width: 40, height: 4)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .onTapGesture {
                // Phase 57: Dismiss on tap (replaces old X button behavior)
                dismiss()
            }
    }
    
    /// Phase 70: Map card with Host HUD overlay and increased height
    private var mapCard: some View {
        ZStack(alignment: .top) {
            // Phase 70: Increased map height for better route visibility
            RideMapViewRepresentable(
                region: $region,
                coordinates: rideService.route,
                showsUserLocation: true,
                riderAnnotations: [],
                selectedRider: $selectedRider
            )
            .frame(height: 450) // Phase 70: Increased from 400
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            // Phase 70: Host HUD overlaid at top of map
            VStack {
                if rideService.rideState == .active || rideService.rideState == .paused {
                    RideHostHUDView(
                        hostName: profileManager.currentDisplayName,
                        hostImage: profileManager.currentProfileImage,
                        distanceMiles: rideService.totalDistanceMiles,
                        speedMph: rideService.currentSpeedMph,
                        durationText: rideService.formattedDuration,
                        isConnected: connectionManager.state == .connected,
                        isMusicOn: musicSync.currentTrack?.isPlaying ?? false,
                        musicSourceMode: musicSync.musicSourceMode,
                        nowPlaying: musicService.nowPlaying,
                        isPlaying: musicService.isPlaying,
                        onPrevious: {
                            HapticsService.shared.lightTap()
                            musicService.skipToPreviousTrack()
                        },
                        onTogglePlayPause: {
                            HapticsService.shared.mediumTap()
                            musicService.togglePlayPause()
                        },
                        onNext: {
                            HapticsService.shared.lightTap()
                            musicService.skipToNextTrack()
                        }
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                }
                
                Spacer()
            }
            
                            // Phase 73: Ride mode pill in top-right (only for Connected, not Solo Ride)
                            // Solo Ride badge now appears in HUD stats above Avg Speed column
                            if let badgeConfig = rideModeBadgeConfig, badgeConfig.label == "Connected" {
                                RideModeBadgeView(
                                    label: badgeConfig.label,
                                    color: badgeConfig.color
                                )
                                .padding(.top, 16)
                                .padding(.trailing, 16)
                                .frame(maxWidth: .infinity, alignment: .topTrailing)
                            }
        }
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
        .onChange(of: rideService.route.count) { _ in
            updateMapRegion()
        }
    }
    
    /// Phase 43C: Ride mode badge configuration
    private var rideModeBadgeConfig: (label: String, color: Color)? {
        if rideService.rideState == .active || rideService.rideState == .paused {
            if connectionManager.state == .connected {
                return ("Connected", Color.green)
            } else {
                return ("Solo Ride", theme.brandYellow)
            }
        }
        return nil
    }
    
    /// Stats card with black background and white/yellow text
    private var statsCard: some View {
        HStack(spacing: 24) {
            RideTrackingStatCard(
                icon: "location.fill",
                value: String(format: "%.2f", rideService.totalDistanceMiles),
                label: "Distance",
                unit: "mi"
            )
            
            RideTrackingStatCard(
                icon: "clock.fill",
                value: formatDuration(rideService.totalDurationSeconds > 0 ? rideService.totalDurationSeconds : rideService.duration),
                label: "Time"
            )
            
            RideTrackingStatCard(
                icon: "speedometer",
                value: String(format: "%.1f", rideService.averageSpeedMph),
                label: "Avg Speed",
                unit: "mph"
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
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
    
    // MARK: - Helper Methods

    private func updateMapRegion() {
        guard !rideService.route.isEmpty else { return }

        if let lastCoordinate = rideService.route.last {
            region = MKCoordinateRegion(
                center: lastCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private func speakStatus() {
        let miles = rideService.totalDistance / 1609.34
        let hours = Int(rideService.duration) / 3600
        let minutes = (Int(rideService.duration) % 3600) / 60
        let speed = rideService.averageSpeed * 0.621371

        var status = "Current status. "
        status += "Distance, \(String(format: "%.2f", miles)) miles. "
        if hours > 0 {
            status += "Time, \(hours) hours \(minutes) minutes. "
        } else {
            status += "Time, \(minutes) minutes. "
        }
        status += "Average speed, \(String(format: "%.1f", speed)) miles per hour."

        VoiceFeedbackService.shared.speak(status)
        RideHaptics.milestone()
    }

    // MARK: - Phase 67-69: Combined Music Section with Artwork Background
    
    @ViewBuilder
    private var rideMusicSection: some View {
        switch musicSync.musicSourceMode {
        case .appleMusicSynced:
            if let nowPlaying = musicService.nowPlaying {
                // Phase 67-69: Transport controls with artwork background
                ZStack {
                    // Background: blurred artwork or fallback
                    if let artwork = nowPlaying.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .blur(radius: 20)
                            .overlay(Color.black.opacity(0.45))
                    } else {
                        // Fallback background if no artwork
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    }
                    
                    // Foreground: transport controls
                    rideMusicTransportControlsContent
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                // No track state
                Text("Start Apple Music to control playback here.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
            }
            
        case .externalPlayer:
            // External Player mode - simple card without artwork
            Text("Using your other music app for playback.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                )
        }
    }
    
    // MARK: - Phase 64: Now Playing Strip Content (extracted for reuse)
    
    @ViewBuilder
    private var rideNowPlayingStripContent: some View {
        if let nowPlaying = musicService.nowPlaying {
            HStack(spacing: 12) {
                // Artwork thumbnail (kept visible even with background)
                Group {
                    if let artwork = nowPlaying.artwork {
                        Image(uiImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "music.note")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(nowPlaying.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(nowPlaying.artist)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
            }
        } else {
            // No track state
            Text("Start Apple Music to control playback here.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Phase 66: Transport Controls Content (extracted for reuse)
    
    @ViewBuilder
    private var rideMusicTransportControlsContent: some View {
        if musicService.nowPlaying != nil {
            // Phase 67-69: Transport buttons with artwork background
            HStack(spacing: 24) {
                // Previous track
                Button {
                    HapticsService.shared.lightTap()
                    musicService.skipToPreviousTrack()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .foregroundColor(theme.brandYellow)
                        .frame(width: 44, height: 44)
                }
                
                // Play/Pause
                Button {
                    HapticsService.shared.mediumTap()
                    musicService.togglePlayPause()
                } label: {
                    Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2.weight(.bold))
                        .foregroundColor(theme.brandYellow)
                        .frame(width: 56, height: 56)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                // Next track
                Button {
                    HapticsService.shared.lightTap()
                    musicService.skipToNextTrack()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(theme.brandYellow)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Phase 64: Now Playing Strip (kept for backward compatibility, now unused)
    
    @ViewBuilder
    private var rideNowPlayingStrip: some View {
        switch musicSync.musicSourceMode {
        case .appleMusicSynced:
            if let nowPlaying = musicService.nowPlaying {
                HStack(spacing: 12) {
                    // Artwork
                    Group {
                        if let artwork = nowPlaying.artwork {
                            Image(uiImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "music.note")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nowPlaying.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(nowPlaying.artist)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                )
            } else {
                // Optional subtle "no music" state
                Text("Apple Music is ready – start a song to see it here.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
            }
            
        case .externalPlayer:
            Text("Using your other music app for playback.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                )
        }
    }
    
    // MARK: - Phase 66: Inline Music Transport Controls
    
    @ViewBuilder
    private var rideMusicTransportControls: some View {
        switch musicSync.musicSourceMode {
        case .appleMusicSynced:
            if musicService.nowPlaying != nil {
                // Phase 66: Transport buttons when track is playing
                HStack(spacing: 24) {
                    // Previous track
                    Button {
                        HapticsService.shared.lightTap()
                        musicService.skipToPreviousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                            .foregroundColor(theme.brandYellow)
                            .frame(width: 44, height: 44)
                    }
                    
                    // Play/Pause
                    Button {
                        HapticsService.shared.mediumTap()
                        musicService.togglePlayPause()
                    } label: {
                        Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2.weight(.bold))
                            .foregroundColor(theme.brandYellow)
                            .frame(width: 56, height: 56)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    // Next track
                    Button {
                        HapticsService.shared.lightTap()
                        musicService.skipToNextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(theme.brandYellow)
                            .frame(width: 44, height: 44)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                )
            } else {
                // Phase 66: Helper text when no track
                Text("Start Apple Music to control playback here.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.black.opacity(0.25))
                    )
            }
            
        case .externalPlayer:
            // Phase 66: Helper text for External Player mode
            Text("Using another music app – control playback there while Branchr keeps your ride and voice chat in sync.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                )
        }
    }
    
    // MARK: - Phase 35A: Unified Ride Button
    
    // Phase 42: Ride controls with Home-style bottom strip
    private var rideControls: some View {
        VStack(spacing: 12) {
            // Primary action button (Start/Pause/Resume)
            Button(action: handleRideButtonTap) {
                Text(rideService.rideState.buttonTitle)
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(theme.brandYellow)
                    .cornerRadius(16)
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
            .buttonStyle(.plain)
            
            // End Ride button (if ride is active)
            if rideService.rideState != .idle && rideService.rideState != .ended {
                Button(role: .destructive) {
                    endRideDirectly()
                } label: {
                    Text("End Ride")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.red.opacity(0.9))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    
    // Phase 35B: Direct end ride function
    private func endRideDirectly() {
        print("🛑 endRideDirectly() tapped from RideTrackingView")
        withAnimation {
            rideService.endRide()
            showRideSummary = true
        }
        VoiceFeedbackService.shared.speak("Ride ended")
        RideHaptics.milestone()
    }
    
    // Phase 35B: Finalize ride after user dismisses summary
    private func handleRideSummaryDone() {
        print("✅ handleRideSummaryDone() - Finalizing ride")
        
        // 1. Grab the final ride record from the ride service
        guard let rideRecord = createRideRecord() else {
            print("⚠️ handleRideSummaryDone(): No rideRecord available, performing safety reset only.")
            RideSessionRecoveryService.shared.clearSession()
            rideService.resetRide()
            RideSessionManager.shared.resetRide()
            DispatchQueue.main.async {
                self.showRideSummary = false
            }
            return
        }
        
        // 2. Clear recovery data (we're done with this ride)
        RideSessionRecoveryService.shared.clearSession()
        print("🗑️ Cleared ride session recovery data")
        
        // 3. Persist to local history (used by in-app calendar and stats)
        //    Save ALL rides to local history, not just >= 300s
        RideDataManager.shared.saveRide(rideRecord)
        NotificationCenter.default.post(name: .branchrRidesDidChange, object: nil)
        print("💾 Saved ride to local history: \(String(format: "%.2f", rideRecord.distance / 1609.34)) mi")
        
        // 4. Persist to Firebase only for "real" rides (>= 300 seconds),
        //    preserving the existing behavior.
        if rideRecord.duration >= 300 {
            FirebaseRideService.shared.uploadRide(rideRecord) { error in
                if let error = error {
                    print("❌ Failed to upload ride: \(error.localizedDescription)")
                } else {
                    print("☁️ Ride synced to Firebase successfully")
                }
            }
        } else {
            print("📊 Skipping Firebase save (ride too short: \(String(format: "%.1f", rideRecord.duration))s < 300s)")
        }
        
        // 5. Try to save to iOS Calendar via EventKit (non-blocking, graceful on failure)
        RideCalendarService.shared.saveRideToCalendar(rideRecord) { success in
            DispatchQueue.main.async {
                if success {
                    VoiceFeedbackService.shared.speak("Ride stopped, saved to calendar")
                    print("✅ Ride finalized - calendar event saved")
                } else {
                    VoiceFeedbackService.shared.speak("Ride stopped")
                    print("⚠️ Ride finalized - calendar save skipped or failed")
                }
            }
        }
        
        // 6. Reset services to idle so HomeView shows "Start Ride" (on main thread)
        DispatchQueue.main.async {
            self.rideService.resetRide()
            RideSessionManager.shared.resetRide()
            print("🔄 Ride reset")
            self.showRideSummary = false
        }
    }

    private func handleRideButtonTap() {
        switch rideService.rideState {
        case .idle, .ended:
            rideService.startRide()
            VoiceFeedbackService.shared.speak("Tracking ride")
            RideHaptics.milestone()
            lastAnnouncedDistance = 0.0
            lastAnnouncedTime = 0.0
        case .active:
            rideService.pauseRide()
            VoiceFeedbackService.shared.speak("Ride paused")
            RideHaptics.milestone()
        case .paused:
            rideService.resumeRide()
            VoiceFeedbackService.shared.speak("Ride resumed")
            RideHaptics.milestone()
        }
    }

    // MARK: - Phase 35B: Rainbow Pulse Countdown

    private func startCountdown() {
        isStopping = true
        progress = 0
        countdown = 5
    }

    private func playCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            countdown -= 1
            progress += 0.2
            haptic.notificationOccurred(.success)
            VoiceFeedbackService.shared.speak("Stopping ride in \(countdown)")
            if countdown == 0 {
                timer.invalidate()
                finishStop()
            }
        }
    }

    private func finishStop() {
        withAnimation {
            isStopping = false
            rideService.endRide()
            showRideSummary = true
        }
        VoiceFeedbackService.shared.speak("Ride ended")
    }

    // Phase 36: Create RideRecord from service with accurate metrics
    private func createRideRecord() -> RideRecord? {
        guard rideService.rideState == .ended else { return nil }

        // Phase 36: Use final metrics from calculator for accuracy
        // The service already has computed metrics from routeLocations
        let distanceMeters = rideService.totalDistance
        let durationSeconds = rideService.totalDurationSeconds > 0 ? rideService.totalDurationSeconds : rideService.duration
        let avgSpeedMps = rideService.averageSpeedMph > 0 
            ? rideService.averageSpeedMph / 2.237 // Convert mph to m/s
            : (distanceMeters > 0 && durationSeconds > 0 ? distanceMeters / durationSeconds : 0.0)

        print("📊 Creating RideRecord – distance: \(String(format: "%.2f", distanceMeters/1609.34)) mi, duration: \(String(format: "%.0f", durationSeconds))s, avg speed: \(String(format: "%.1f", avgSpeedMps * 2.237)) mph")

        return RideRecord(
            distance: distanceMeters,
            duration: durationSeconds,
            averageSpeed: avgSpeedMps,
            calories: 0,
            route: rideService.route
        )
    }
}

// MARK: - Ride Haptics Helper

enum RideHaptics {
    static func milestone() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

// MARK: - Ride Stat Card Component (Phase 31 - Local to RideTrackingView)

struct RideTrackingStatCard: View {
    let icon: String
    let value: String
    let label: String
    let unit: String?

    @ObservedObject private var theme = ThemeManager.shared

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
                .foregroundColor(theme.brandYellow) // Phase 42: Yellow icons on black

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(Color.white) // Phase 42: White text on black

                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.78)) // Phase 42: Slightly dimmed white
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.78)) // Phase 42: Slightly dimmed white
        }
        .frame(width: 100)
    }
}

// MARK: - Preview

#Preview {
    RideTrackingView()
        .preferredColorScheme(.dark)
}
