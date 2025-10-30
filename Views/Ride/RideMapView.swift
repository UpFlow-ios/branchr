//
//  RideMapView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI
import MapKit
import Combine
import CoreLocation

/// Live map view showing current ride tracking
struct RideMapView: View {
    
    // MARK: - Properties
    @StateObject private var locationService = LocationTrackingService()
    @StateObject private var rideDataManager = RideDataManager()
    @StateObject private var motionService = MotionDetectionService()
    @StateObject private var voiceAssistant = VoiceAssistantService()
    @State private var speechCommands: SpeechCommandService?
    @StateObject private var preferenceManager = UserPreferenceManager.shared
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showingSummary = false
    @State private var showingHistory = false
    @State private var showingRidePrompt = false
    @State private var showingVoiceSettings = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco default
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $region, 
                interactionModes: [.pan, .zoom],
                showsUserLocation: true,
                userTrackingMode: .constant(.none),
                annotationItems: locationService.locations.isEmpty ? [] : [MapAnnotation(coordinate: locationService.locations.last!.coordinate)]) { location in
                MapPin(coordinate: location.coordinate, tint: .red)
            }
            .overlay(
                // Route polyline
                MapPolylineOverlay(coordinates: locationService.locations.map { $0.coordinate })
            )
            .onChange(of: locationService.locations) { locations in
                updateMapRegion()
            }
            
            // Top controls
            VStack {
                HStack {
                    Button(action: {
                        showingHistory = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Button(action: {
                        showingVoiceSettings = true
                    }) {
                        Image(systemName: preferenceManager.voiceAssistantEnabled ? "mic.fill" : "mic.slash.fill")
                            .font(.title2)
                            .foregroundColor(preferenceManager.voiceAssistantEnabled ? .green : .gray)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if locationService.isTracking {
                            if locationService.isPaused {
                                locationService.resumeTracking()
                                if preferenceManager.voiceAssistantEnabled {
                                    voiceAssistant.announceRideResumed()
                                }
                            } else {
                                locationService.pauseTracking()
                                if preferenceManager.voiceAssistantEnabled {
                                    voiceAssistant.announceRidePaused()
                                }
                            }
                        } else {
                            locationService.startTracking()
                            if preferenceManager.voiceAssistantEnabled {
                                voiceAssistant.announceRideStart()
                            }
                            if preferenceManager.voiceCommandsEnabled {
                                if speechCommands == nil {
                                    let service = SpeechCommandService()
                                    speechCommands = service
                                    // Subscribe to voice commands
                                    service.$detectedCommand.sink { [weak service] command in
                                        guard let _ = service else { return }
                                        handleVoiceCommand(command)
                                    }.store(in: &cancellables)
                                }
                                speechCommands?.startListening()
                            }
                        }
                    }) {
                        Image(systemName: locationService.isTracking ? 
                              (locationService.isPaused ? "play.circle.fill" : "pause.circle.fill") : 
                              "play.circle.fill")
                            .font(.title)
                            .foregroundColor(locationService.isTracking ? .orange : .green)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if locationService.isTracking {
                            stopRide()
                        } else {
                            locationService.reset()
                        }
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Bottom dashboard
            VStack {
                Spacer()
                
                // Stats dashboard
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        // Distance
                        StatCard(
                            title: "Distance",
                            value: locationService.formattedDistance,
                            icon: "location.fill",
                            color: .blue
                        )
                        
                        // Duration
                        StatCard(
                            title: "Time",
                            value: locationService.formattedElapsedTime,
                            icon: "clock.fill",
                            color: .green
                        )
                        
                        // Average Speed
                        StatCard(
                            title: "Avg Speed",
                            value: locationService.formattedAverageSpeed,
                            icon: "speedometer",
                            color: .orange
                        )
                    }
                    
                    // Current speed (if tracking)
                    if locationService.isTracking && !locationService.isPaused {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.white)
                            Text("Current: \(locationService.formattedCurrentSpeed)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Ride prompt overlay
            if showingRidePrompt {
                RidePromptView(
                    motionService: motionService,
                    locationService: locationService,
                    isPresented: $showingRidePrompt
                )
            }
        }
        .navigationTitle("Ride Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestLocationPermission()
            }
            
            // Start motion detection
            motionService.startMonitoring()
        }
        .onDisappear {
            // Stop motion detection when leaving the view
            motionService.stopMonitoring()
        }
        .onReceive(motionService.$rideDetected) { rideDetected in
            if rideDetected && !locationService.isTracking {
                showingRidePrompt = true
            }
        }
        .sheet(isPresented: $showingSummary) {
            RideSummaryView(
                ride: createRideRecord(),
                rideDataManager: rideDataManager,
                onDismiss: {
                    showingSummary = false
                    locationService.reset()
                }
            )
        }
        .sheet(isPresented: $showingHistory) {
            RideHistoryView(rideDataManager: rideDataManager)
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
        .onChange(of: locationService.distanceTraveled) { distance in
            if locationService.isTracking && !locationService.isPaused {
                voiceAssistant.announceProgress(
                    distance: distance,
                    speed: locationService.currentSpeed,
                    duration: locationService.elapsedTime
                )
            }
        }
        .onAppear {
            voiceAssistant.setEnabled(preferenceManager.voiceAssistantEnabled)
            if speechCommands == nil {
                let service = SpeechCommandService()
                speechCommands = service
                // Subscribe to voice commands
                service.$detectedCommand.sink { [weak service] command in
                    guard let _ = service else { return }
                    handleVoiceCommand(command)
                }.store(in: &cancellables)
            }
            speechCommands?.setEnabled(preferenceManager.voiceCommandsEnabled)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleVoiceCommand(_ command: SpeechCommandService.RideVoiceCommand?) {
        guard let command = command else { return }
        
        switch command {
        case .pause:
            if locationService.isTracking && !locationService.isPaused {
                locationService.pauseTracking()
                if preferenceManager.voiceAssistantEnabled {
                    voiceAssistant.announceRidePaused()
                }
            }
            
        case .resume:
            if locationService.isTracking && locationService.isPaused {
                locationService.resumeTracking()
                if preferenceManager.voiceAssistantEnabled {
                    voiceAssistant.announceRideResumed()
                }
            }
            
        case .stop:
            if locationService.isTracking {
                stopRide()
            }
            
        case .status:
            if locationService.isTracking {
                voiceAssistant.announceStatus(
                    distance: locationService.distanceTraveled,
                    speed: locationService.currentSpeed,
                    duration: locationService.elapsedTime
                )
            }
        }
        
        // Clear the command after handling
        speechCommands?.clearCommand()
    }
    
    private func updateMapRegion() {
        guard let lastLocation = locationService.locations.last else { return }
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region.center = lastLocation.coordinate
        }
    }
    
    private func stopRide() {
        locationService.stopTracking()
        speechCommands?.stopListening()
        
        let ride = createRideRecord()
        if ride.distance > 10 { // Only save rides longer than 10 meters
            rideDataManager.saveRide(ride)
            
            // Announce ride end if voice assistant is enabled
            if preferenceManager.voiceAssistantEnabled {
                voiceAssistant.announceRideEnd(
                    distance: ride.distance,
                    duration: ride.duration,
                    averageSpeed: ride.averageSpeed
                )
            }
        }
        
        showingSummary = true
    }
    
    private func createRideRecord() -> RideRecord {
        let route = locationService.locations.map { $0.coordinate }
        return RideRecord(
            distance: locationService.distanceTraveled,
            duration: locationService.elapsedTime,
            averageSpeed: locationService.averageSpeed,
            route: route
        )
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}


#Preview {
    NavigationView {
        RideMapView()
    }
}
