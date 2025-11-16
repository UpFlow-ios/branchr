//
//  RideSheetView.swift
//  branchr
//
//  Created for Smart Group Ride System - Universal Ride Interface
//

import SwiftUI
import MapKit
import Foundation

/**
 * 🚴‍♂️ Ride Sheet View
 *
 * Universal expandable bottom sheet that adapts to Solo or Group rides.
 * Shows map, stats, and controls based on ride mode.
 */
struct RideSheetView: View {
    @ObservedObject private var rideManager = RideSessionManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showRideSummary = false
    @State private var showConnectedRidersSheet = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var selectedRider: UserAnnotation? = nil // Phase 4: Selected rider for info panel
    @Namespace private var rideNamespace
    @Namespace private var riderNamespace
    
    // Phase 35.5: Log state changes to track auto-stops
    init() {
        print("🎯 RideSheetView initialized")
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                // Top controls (pause/stop buttons)
                headerView
                    .matchedGeometryEffect(id: "rideHeader", in: rideNamespace)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Map section ~40% of height (Phase 2)
                ZStack(alignment: .topLeading) {
                    RideMapViewRepresentable(
                        region: $region,
                        coordinates: rideManager.route,
                        showsUserLocation: true,
                        riderAnnotations: rideManager.riderAnnotations,
                        selectedRider: $selectedRider
                    )
                    .frame(height: 260) // Explicit height to stay stable
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: theme.glowColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    .onChange(of: rideManager.route.count) {
                        updateMapRegion()
                    }
                    
                    // LIVE tracking badge + HUD (Phase 2)
                    if rideManager.rideState == .active {
                        VStack(alignment: .leading, spacing: 8) {
                            // LIVE Tracking Badge
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: .green.opacity(0.6), radius: 6)
                                Text("LIVE TRACKING")
                                    .font(.caption.bold())
                                    .textCase(.uppercase)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .shadow(radius: 12)
                            
                            // Group Ride HUD
                            if rideManager.isGroupRide {
                                HStack(spacing: 6) {
                                    Text("👑")
                                    Text("\(rideManager.connectedRiders.count + 1) riders")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .shadow(radius: 12)
                            }
                        }
                        .padding(20)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                
                // Stats row (Phase 2)
                statsView
                    .matchedGeometryEffect(id: "rideStats", in: rideNamespace)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                // Phase 35.7: Music Area Placeholder
                musicPlaceholderView
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                // Phase 35.7: Connected Riders Preview Strip
                if rideManager.isGroupRide && !rideManager.connectedRiders.isEmpty {
                    connectedRidersPreview
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                
                Spacer()
                
                // Phase 35.1: Host Controls Section
                if rideManager.isGroupRide && rideManager.isHost {
                    RideSheetHostControls()
                        .matchedGeometryEffect(id: "hostControls", in: rideNamespace)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Overlays (Phase 2)
            riderOverlay
            
            // Phase 35.4: Show summary as overlay instead of new sheet
            if rideManager.showSummary, let rideRecord = createRideRecord() {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation { rideManager.showSummary = false }
                    }
                
                EnhancedRideSummaryView(ride: rideRecord)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.primaryBackground.ignoresSafeArea())
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: rideManager.connectedRiders.count)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: rideManager.showSummary)
        .onChange(of: rideManager.rideState) { newState in
            print("🎯 rideState changed to: \(newState)")
        }
        .sheet(isPresented: $showConnectedRidersSheet) {
            // Phase 35.2: Connected Riders Sheet with local instances
            ConnectedRidersSheet(
                groupManager: GroupSessionManager.shared,
                voiceService: VoiceChatService(),
                musicSync: MusicSyncService.shared
            )
            .presentationDetents([.large, .medium])
            .transition(.opacity)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateMapRegion() {
        guard !rideManager.route.isEmpty else { return }
        let lastCoordinate = rideManager.route.last!
        region = MKCoordinateRegion(
            center: lastCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
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
    
    private func createRideRecord() -> RideRecord? {
        if let shared = rideManager.sharedSummary {
            return shared
        }
        guard rideManager.rideState == .ended else { return nil }
        
        // Phase 35: Create unique ride record with current timestamp
        return RideRecord(
            id: UUID(), // Always generate new ID to prevent duplicates
            date: Date(),
            distance: rideManager.totalDistance,
            duration: rideManager.duration,
            averageSpeed: rideManager.averageSpeed,
            calories: 0,
            route: rideManager.route
        )
    }
    
    // Phase 34I: Stop countdown
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rideManager.isGroupRide ? "Group Ride" : "Ride Tracking")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.branchrAccent)
                
                if let status = rideManager.remoteStatusMessage {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if rideManager.isGroupRide, let hostName = rideManager.hostDisplayName {
                    Text("Connected to \(hostName)’s group")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            Spacer()
            
            if rideManager.isGroupRide {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(rideManager.connectedRiders.count) riders")
                        .font(.caption)
                        .foregroundColor(Color.branchrAccent)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Phase 34I: Smooth button transitions
            Group {
                if rideManager.rideState == .active {
                    Button(action: {
                        rideManager.pauseRide()
                    }) {
                        Image(systemName: "pause.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .padding(8)
                            .background(
                                Circle().fill(.ultraThinMaterial)
                            )
                    }
                    .accessibilityLabel("Pause ride")
                    .transition(.scale.combined(with: .opacity))
                } else if rideManager.rideState == .paused {
                    HStack(spacing: 12) {
                        Button(action: {
                            rideManager.resumeRide()
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                                .padding(8)
                                .background(
                                    Circle().fill(.ultraThinMaterial)
                                )
                        }
                        .accessibilityLabel("Resume ride")
                        
                        Button(action: {
                            // Phase 35.3: Instant stop
                            rideManager.endRide()
                            Task { @MainActor in
                                await VoiceFeedbackService.shared.speak("Ride stopped, saved to calendar")
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                                .padding(8)
                                .background(
                                    Circle().fill(.ultraThinMaterial)
                                )
                        }
                        .accessibilityLabel("Stop ride")
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button(action: {
                        rideManager.endRide()
                        showRideSummary = true
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(
                                Circle().fill(.ultraThinMaterial)
                            )
                    }
                    .accessibilityLabel("End ride")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: rideManager.rideState)
        }
    }
    
    private var statsView: some View {
        HStack(spacing: 16) {
            statCard(icon: "location.fill", title: "Distance", value: String(format: "%.2f", rideManager.totalDistance / 1609.34), unit: "mi")
            statCard(icon: "clock.fill", title: "Time", value: formatDuration(rideManager.duration), unit: nil)
            statCard(icon: "speedometer", title: "Avg Speed", value: String(format: "%.1f", rideManager.averageSpeed * 2.237), unit: "mph")
        }
    }
    
    private func statCard(icon: String, title: String, value: String, unit: String?) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.primaryText)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(theme.primaryText)
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                        .opacity(0.7)
                }
            }
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.cardBackground)
                .shadow(color: theme.glowColor.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
    
    private var riderOverlay: some View {
        VStack {
            Spacer()
            
            // Phase 35.2: Connected riders display with View All button
            if rideManager.isGroupRide && !rideManager.connectedRiders.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text("Connected Riders")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Phase 35.2: View All Riders Button
                        Button {
                            showConnectedRidersSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("View All")
                                    .font(.caption2.bold())
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundColor(Color.branchrAccent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(rideManager.connectedRiders) { rider in
                                VStack(spacing: 4) {
                                    MapRiderAnnotationView(
                                        name: rider.name,
                                        photoURL: rider.photoURL,
                                        isOnline: rider.isOnline
                                    )
                                    .frame(width: 48, height: 48)
                                    .matchedGeometryEffect(id: rider.id, in: riderNamespace)
                                    
                                    Text(rider.name)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
        }
    }
    
    // Phase 35.7: Music Placeholder View
    private var musicPlaceholderView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Music")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 50)
                .overlay(
                    Text("Coming Soon")
                        .foregroundColor(.gray)
                        .font(.footnote)
                )
        }
    }
    
    // Phase 35.7: Connected Riders Preview Strip
    private var connectedRidersPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(rideManager.connectedRiders) { rider in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text(String(rider.name.prefix(1)))
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(radius: 5)
                }
            }
        }
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

