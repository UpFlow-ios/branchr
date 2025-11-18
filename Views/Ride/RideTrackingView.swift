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
            ZStack(alignment: .topLeading) {

                // 1) MAP BACKGROUND
                theme.primaryBackground.ignoresSafeArea()

                RideMapViewRepresentable(
                    region: $region,
                    coordinates: rideService.route,
                    showsUserLocation: true,
                    riderAnnotations: [],
                    selectedRider: $selectedRider
                )
                .ignoresSafeArea() // Phase 34D: Map fills entire screen
                .onChange(of: rideService.route.count) { _ in
                    updateMapRegion()
                }

                // 2) MAIN VSTACK (HEADER + STATS + BUTTON)
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Ride Tracking")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color.branchrAccent)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color.branchrAccent)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()

                    // Stats HUD
                    HStack(spacing: 30) {
                        RideTrackingStatCard(
                            icon: "location.fill",
                            value: String(format: "%.2f", rideService.totalDistance / 1609.34),
                            label: "Distance",
                            unit: "mi"
                        )

                        RideTrackingStatCard(
                            icon: "clock.fill",
                            value: formatDuration(rideService.duration),
                            label: "Time"
                        )

                        RideTrackingStatCard(
                            icon: "speedometer",
                            value: String(format: "%.1f", rideService.averageSpeed * 0.621371),
                            label: "Avg Speed",
                            unit: "mph"
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.isDarkMode ? Color.branchrAccent : Color.black)
                            .opacity(0.9)
                    )
                    .foregroundColor(theme.isDarkMode ? Color.black : Color.branchrAccent)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    // Ride controls - Phase 35B: Added explicit End Ride button
                    rideControls
                        .padding(.bottom, 50)
                }

                // 3) HOST HUD OVERLAY (TOP-LEFT) - Phase 35B: Moved lower to avoid header overlap
                if rideService.rideState == .active || rideService.rideState == .paused {
                    RideHostHUDView(
                        hostName: profileManager.currentDisplayName,
                        hostImage: profileManager.currentProfileImage,
                        distanceMiles: rideService.totalDistanceMiles,
                        speedMph: rideService.currentSpeedMph,
                        durationText: rideService.formattedDuration,
                        isConnected: connectionManager.state == .connected,
                        isMusicOn: musicSync.currentTrack?.isPlaying ?? false
                    )
                    .padding(.top, 96) // Phase 35B: Moved down to avoid header overlap
                    .padding(.leading, 16)
                    .padding(.trailing, 40)
                    .onAppear {
                        print("🎛 RideHostHUDView visible – host HUD overlay active")
                    }
                }

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

    // MARK: - Phase 35A: Unified Ride Button
    
    // Phase 35B: Ride controls with explicit End Ride button
    private var rideControls: some View {
        VStack(spacing: 8) {
            rideButton
            
            // Step 1B: Show End Ride for all "in progress" states (not idle, not ended)
            if rideService.rideState != .idle && rideService.rideState != .ended {
                Button(role: .destructive) {
                    endRideDirectly()
                } label: {
                    Text("End Ride")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 36)
                        .background(Color.red.opacity(0.95))
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    private var rideButton: some View {
        Button(action: handleRideButtonTap) {
            Text(rideService.rideState.buttonTitle)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 220, height: 60)
                .background(rideService.rideState.buttonColor)
                .cornerRadius(15)
                .shadow(radius: 8)
        }
        // Phase 35B: Removed long-press gesture for simpler UX
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
        
        // 1) Clear ride session recovery data (stops spammy "Saved ride session for recovery" logs)
        RideSessionRecoveryService.shared.clearSession()
        
        // 2) Ensure ride is saved (EnhancedRideSummaryView already saves on appear if duration >= 300,
        //    but we ensure it's persisted here as well for consistency)
        if let rideRecord = createRideRecord(), rideRecord.duration >= 300 {
            RideDataManager.shared.saveRide(rideRecord)
            FirebaseRideService.shared.uploadRide(rideRecord) { error in
                if let error = error {
                    print("❌ Failed to upload ride: \(error.localizedDescription)")
                } else {
                    print("☁️ Ride synced to Firebase successfully")
                }
            }
            NotificationCenter.default.post(name: .branchrRidesDidChange, object: nil)
        }
        
        // 3) Reset ride state to idle in BOTH services so HomeView shows "Start Ride" instead of "Pause Ride"
        //    HomeView uses RideSessionManager.shared, RideTrackingView uses RideTrackingService.shared
        rideService.resetRide()
        RideSessionManager.shared.resetRide()
        
        // 4) Voice feedback for calendar save (matching previous behavior)
        VoiceFeedbackService.shared.speak("Ride stopped, saved to calendar")
        
        // 5) Dismiss summary sheet
        withAnimation {
            showRideSummary = false
        }
        
        print("✅ Ride finalized - state reset to idle in both services, recovery cleared, calendar saved")
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

    // Phase 35C: Create RideRecord from service
    private func createRideRecord() -> RideRecord? {
        guard rideService.rideState == .ended else { return nil }

        let avgSpeed = rideService.totalDistance > 0 && rideService.duration > 0
            ? rideService.totalDistance / rideService.duration // m/s
            : 0

        return RideRecord(
            distance: rideService.totalDistance,
            duration: rideService.duration,
            averageSpeed: avgSpeed,
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
                .foregroundColor(theme.isDarkMode ? Color.black : Color.branchrAccent)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(theme.isDarkMode ? Color.black : Color.branchrAccent)

                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor((theme.isDarkMode ? Color.black : Color.branchrAccent).opacity(0.7))
                }
            }

            Text(label)
                .font(.caption)
                .foregroundColor((theme.isDarkMode ? Color.black : Color.branchrAccent).opacity(0.7))
        }
        .frame(width: 100)
    }
}

// MARK: - Preview

#Preview {
    RideTrackingView()
        .preferredColorScheme(.dark)
}
