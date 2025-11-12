//
//  RideSessionManager.swift
//  branchr
//
//  Smart Group Ride System – ride tracking + Firebase sync
//

import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import FirebaseAuth
import UIKit
import SwiftUI

/**
 * 🚴‍♂️ Ride Session Manager
 *
 * Responsibilities:
 *  - Solo & group ride lifecycle management
 *  - GPS route logging + statistics
 *  - Real-time Firebase sync of riders, commands, and summaries
 *  - Calendar auto-save (rides ≥ 5 minutes)
 *  - Shared summary + rider annotations for UI
 */
@MainActor
final class RideSessionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let shared = RideSessionManager()
    
    // MARK: Published state
    @Published var rideState: RideSessionState = .idle
    @Published var totalDistance: Double = 0.0
    @Published var duration: TimeInterval = 0.0
    @Published var route: [CLLocationCoordinate2D] = []
    @Published var averageSpeed: Double = 0.0
    @Published var currentSpeed: Double = 0.0
    
    @Published var isGroupRide: Bool = false
    @Published var groupRideId: String?
    @Published var isHost: Bool = false
    @Published var hostDisplayName: String?
    
    @Published var connectedRiders: [RiderInfo] = []
    @Published var riderAnnotations: [RiderAnnotation] = []
    @Published var sharedSummary: RideRecord?
    @Published var remoteStatusMessage: String?
    
    // Phase 35.1: Control when summary appears
    @Published var showSummary: Bool = false
    
    // MARK: Private properties
    private let locationManager = CLLocationManager()
    private let db = Firestore.firestore()
    
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var lastPauseTime: Date?
    private var timer: Timer?
    private var lastLocation: CLLocation?
    
    private var ridersListener: ListenerRegistration?
    private var commandListener: ListenerRegistration?
    private var groupRideListener: ListenerRegistration?
    private var lastCommandTimestamp: TimeInterval = 0
    private var processingRemoteCommand = false
    
    // Phase 34I: Haptic sync
    private var hapticPulseTimer: Timer?
    private var lastHapticPhase: Double = -1.0
    private let hapticPulseInterval: Double = 1.6 // matches PulseSyncService pulseCycleDuration
    
    // Phase 35: Session recovery
    private let recoveryService = RideSessionRecoveryService.shared
    private var recoverySaveTimer: Timer?
    
    override init() {
        super.init()
        configureLocationManager()
    }
    
    // Note: stopListeners() is called explicitly when needed
    // (e.g., in resetRideData()) rather than in deinit
    // to avoid main actor isolation issues
    
    // MARK: Ride lifecycle
    func startSoloRide() {
        guard rideState == .idle else { return }
        resetRideData()
        showSummary = false  // Phase 35.4: Hide summary when starting new ride
        isGroupRide = false
        isHost = false
        groupRideId = nil
        
        requestLocationPermissionIfNeeded { [weak self] granted in
            guard let self = self, granted else { return }
            self.beginActiveRide()
            VoiceFeedbackService.shared.speak("Ride started")
            print("🚴 Solo ride started")
        }
    }
    
    func startGroupRide() {
        guard rideState == .idle, let uid = Auth.auth().currentUser?.uid else { return }
        resetRideData()
        showSummary = false  // Phase 35.4: Hide summary when starting new ride
        isGroupRide = true
        isHost = true
        groupRideId = UUID().uuidString
        
        let profile = currentUserProfile()
        hostDisplayName = profile.name
        
        let pulseTimestamp = PulseSyncService.shared.generateHostTimestamp()
        
        let sessionData: [String: Any] = [
            "hostId": uid,
            "hostName": profile.name,
            "isActive": true,
            "isPaused": false,
            "startTime": Timestamp(date: Date()),
            "pulseStartTime": Timestamp(date: Date(timeIntervalSince1970: pulseTimestamp))
        ]
        
        db.collection("groupRides").document(groupRideId!).setData(sessionData) { [weak self] error in
            guard let self = self, error == nil else {
                print("❌ Failed to create group ride session: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            self.addOrUpdateRiderDocument(uid: uid, profile: profile, coordinate: nil)
            self.requestLocationPermissionIfNeeded { granted in
                guard granted else { return }
                self.beginActiveRide()
                self.listenForGroupRideUpdates()
                self.listenForCommands()
                VoiceFeedbackService.shared.speak("Group ride started")
                print("🚴 Group ride started (host)")
            }
        }
    }
    
    func joinGroupRide(rideId: String) {
        guard rideState == .idle, let uid = Auth.auth().currentUser?.uid else { return }
        resetRideData()
        showSummary = false  // Phase 35.4: Hide summary when starting new ride
        isGroupRide = true
        isHost = false
        groupRideId = rideId
        
        db.collection("groupRides").document(rideId).getDocument { [weak self] snapshot, _ in
            if let hostName = snapshot?.data()?["hostName"] as? String {
                self?.hostDisplayName = hostName
                self?.remoteStatusMessage = "Connected to \(hostName)’s group"
            }
            if let pulse = snapshot?.data()?["pulseStartTime"] as? Timestamp {
                PulseSyncService.shared.startSync(withHostTimestamp: pulse.dateValue().timeIntervalSince1970)
            }
        }
        
        addOrUpdateRiderDocument(uid: uid, profile: currentUserProfile(), coordinate: nil) { [weak self] error in
            guard let self = self, error == nil else {
                print("❌ Failed to join group ride: \(error?.localizedDescription ?? "unknown")")
                return
            }
            
            self.requestLocationPermissionIfNeeded { granted in
                guard granted else { return }
                self.beginActiveRide()
                self.listenForGroupRideUpdates()
                self.listenForCommands()
                print("🚴 Joined group ride")
            }
        }
    }
    
    func pauseRide() {
        guard rideState == .active else { return }
        rideState = .paused
        locationManager.stopUpdatingLocation()
        stopTimer()
        lastPauseTime = Date()
        
        if isGroupRide, let rideId = groupRideId {
            updateGroupRideState(isPaused: true, rideId: rideId)
            if !processingRemoteCommand { broadcastRideCommand(.pause) }
        }
        
        if !processingRemoteCommand {
            VoiceFeedbackService.shared.speak("Ride paused")
        }
        print("⏸ Ride paused")
    }
    
    func resumeRide() {
        guard rideState == .paused else { return }
        if let pauseStart = lastPauseTime {
            pausedTime += Date().timeIntervalSince(pauseStart)
            lastPauseTime = nil
        }
        rideState = .active
        locationManager.startUpdatingLocation()
        startTimer()
        
        if isGroupRide, let rideId = groupRideId {
            updateGroupRideState(isPaused: false, rideId: rideId)
            if !processingRemoteCommand { broadcastRideCommand(.resume) }
        }
        
        if !processingRemoteCommand {
            VoiceFeedbackService.shared.speak("Ride resumed")
        }
        print("▶️ Ride resumed")
    }
    
    func endRide() {
        guard rideState == .active || rideState == .paused else { return }
        
        // Phase 35.4: Log who called endRide for debugging
        print("🛑 endRide() called - processingRemoteCommand: \(processingRemoteCommand), isHost: \(isHost)")
        
        rideState = .ended
        locationManager.stopUpdatingLocation()
        stopTimer()
        
        if let start = startTime {
            duration = Date().timeIntervalSince(start) - pausedTime
        }
        if duration > 0 { averageSpeed = totalDistance / duration }
        
        if duration >= 300 { saveRideToCalendar() }
        
        if isGroupRide, let rideId = groupRideId, isHost {
            let summary = RideRecord(
                distance: totalDistance,
                duration: duration,
                averageSpeed: averageSpeed,
                calories: 0,
                route: route
            )
            sharedSummary = summary
            db.collection("groupRides").document(rideId).setData([
                "isActive": false,
                "endTime": Timestamp(date: Date()),
                "summary": [
                    "distance": totalDistance,
                    "duration": duration,
                    "averageSpeed": averageSpeed,
                    "timestamp": Timestamp(date: Date())
                ]
            ], merge: true)
            if !processingRemoteCommand { broadcastRideCommand(.end) }
        }
        
        PulseSyncService.shared.stopSync()
        stopHapticPulseSync()
        stopRecoverySaving()
        recoveryService.clearSession()
        
        // Phase 35.1: Show summary only when actually ending (not just pausing)
        showSummary = true
        
        if !processingRemoteCommand {
            let distanceMiles = totalDistance / 1609.34
            VoiceFeedbackService.shared.speak(String(format: "Ride ended. %.1f miles in %@", distanceMiles, formatTime(duration)))
        }
        
        print("🏁 Ride ended - Distance: \(String(format: "%.2f", totalDistance/1000)) km, Duration: \(formatTime(duration))")
    }
    
    func resetRide() {
        rideState = .idle
        isGroupRide = false
        isHost = false
        groupRideId = nil
        hostDisplayName = nil
        showSummary = false
        resetRideData()
    }
    
    // MARK: CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard rideState == .active, let newLocation = locations.last else { return }
        guard newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy < 50 else { return }
        
        if let last = lastLocation {
            let distance = newLocation.distance(from: last)
            totalDistance += distance
            currentSpeed = max(newLocation.speed, 0)
        }
        
        route.append(newLocation.coordinate)
        lastLocation = newLocation
        
        if isGroupRide {
            syncCurrentLocationToGroup(newLocation)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in print("❌ Location error: \(error.localizedDescription)") }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            let status = manager.authorizationStatus
            locationManager.allowsBackgroundLocationUpdates = (status == .authorizedAlways)
        }
    }
    
    // MARK: Helpers
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = locationManager.authorizationStatus == .authorizedAlways
    }
    
    private func beginActiveRide() {
        rideState = .active
        startTime = Date()
        locationManager.startUpdatingLocation()
        startTimer()
        startHapticPulseSync()
        startRecoverySaving()
    }
    
    private func resetRideData() {
        totalDistance = 0
        duration = 0
        route.removeAll()
        pausedTime = 0
        startTime = nil
        lastPauseTime = nil
        lastLocation = nil
        averageSpeed = 0
        currentSpeed = 0
        connectedRiders.removeAll()
        riderAnnotations.removeAll()
        sharedSummary = nil
        remoteStatusMessage = nil
        stopListeners()
        PulseSyncService.shared.stopSync()
        stopHapticPulseSync()
        stopRecoverySaving()
        recoveryService.clearSession()
    }
    
    private func requestLocationPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let granted = self.locationManager.authorizationStatus == .authorizedWhenInUse ||
                              self.locationManager.authorizationStatus == .authorizedAlways
                completion(granted)
            }
        case .authorizedAlways, .authorizedWhenInUse:
            completion(true)
        default:
            completion(false)
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.duration = Date().timeIntervalSince(start) - self.pausedTime
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, secs)
                         : String(format: "%d:%02d", minutes, secs)
    }
    
    private func saveRideToCalendar() {
        let record = RideRecord(
            distance: totalDistance,
            duration: duration,
            averageSpeed: averageSpeed,
            calories: 0,
            route: route
        )
        RideDataManager.shared.saveRide(record)
        FirebaseRideService.shared.uploadRide(record) { error in
            if let error = error {
                print("❌ Failed to upload ride: \(error.localizedDescription)")
            } else {
                print("☁️ Ride synced to Firebase successfully")
            }
        }
    }
    
    private func updateGroupRideState(isPaused: Bool, rideId: String) {
        db.collection("groupRides").document(rideId).setData([
            "isPaused": isPaused,
            "lastStateChange": Timestamp(date: Date())
        ], merge: true)
    }
    
    private func broadcastRideCommand(_ command: RideCommandAction) {
        guard let rideId = groupRideId else { return }
        db.collection("groupRides").document(rideId)
            .collection("commands").document("latest")
            .setData([
                "action": command.rawValue,
                "timestamp": Timestamp(date: Date())
            ], merge: true)
    }
    
    private func listenForCommands() {
        guard let rideId = groupRideId else { return }
        commandListener?.remove()
        commandListener = db.collection("groupRides").document(rideId)
            .collection("commands").document("latest")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self,
                      let data = snapshot?.data(),
                      let raw = data["action"] as? String,
                      let action = RideCommandAction(rawValue: raw),
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue().timeIntervalSince1970 else { return }
                
                if timestamp <= self.lastCommandTimestamp { return }
                self.lastCommandTimestamp = timestamp
                if self.isHost { return }
                
                self.processingRemoteCommand = true
                switch action {
                case .pause:
                    self.pauseRide()
                case .resume:
                    self.resumeRide()
                case .end:
                    // Phase 35.4: Only end if we're the host or explicitly requested
                    if self.isHost {
                        print("🛑 endRide() called by REMOTE/HOST command")
                        self.endRide()
                    } else {
                        print("⚠️ Non-host received end command - ignoring to prevent auto-stop")
                        // Non-hosts should see summary but not end their own ride
                        // The summary will come from the shared summary system
                    }
                }
                self.processingRemoteCommand = false
            }
    }
    
    private func listenForGroupRideUpdates() {
        guard let rideId = groupRideId else { return }
        
        ridersListener?.remove()
        ridersListener = db.collection("groupRides").document(rideId)
            .collection("riders")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                let docs = snapshot?.documents ?? []
                
                var riders: [RiderInfo] = []
                var annotations: [RiderAnnotation] = []
                
                for doc in docs {
                    let data = doc.data()
                    guard let name = data["name"] as? String else { continue }
                    let photoURL = data["photoURL"] as? String
                    let lat = data["lat"] as? CLLocationDegrees
                    let lon = data["lon"] as? CLLocationDegrees
                    let state = data["state"] as? String ?? "active"
                    let coordinate = (lat != nil && lon != nil) ? CLLocationCoordinate2D(latitude: lat!, longitude: lon!) : nil
                    
                    let info = RiderInfo(
                        id: doc.documentID,
                        name: name,
                        photoURL: photoURL?.isEmpty == true ? nil : photoURL,
                        coordinate: coordinate,
                        isOnline: state != "paused"
                    )
                    riders.append(info)
                    
                    if let coordinate = coordinate {
                        annotations.append(RiderAnnotation(
                            id: doc.documentID,
                            name: name,
                            photoURL: photoURL?.isEmpty == true ? nil : photoURL,
                            coordinate: coordinate,
                            isOnline: state != "paused"
                        ))
                    }
                }
                
                let previousCount = self.connectedRiders.count
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    self.connectedRiders = riders
                    self.riderAnnotations = annotations
                }
                
                if riders.count > previousCount {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else if riders.count < previousCount {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
        
        groupRideListener?.remove()
        groupRideListener = db.collection("groupRides").document(rideId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let data = snapshot?.data() else { return }
                
                if let hostName = data["hostName"] as? String {
                    self.hostDisplayName = hostName
                    if !self.isHost {
                        self.remoteStatusMessage = "Connected to \(hostName)’s group"
                    }
                }
                
                if let pulse = data["pulseStartTime"] as? Timestamp {
                    PulseSyncService.shared.startSync(withHostTimestamp: pulse.dateValue().timeIntervalSince1970)
                }
                
                if let isActive = data["isActive"] as? Bool, !isActive,
                   let summary = data["summary"] as? [String: Any],
                   let distance = summary["distance"] as? Double,
                   let duration = summary["duration"] as? Double,
                   let averageSpeed = summary["averageSpeed"] as? Double {
                    self.sharedSummary = RideRecord(
                        distance: distance,
                        duration: duration,
                        averageSpeed: averageSpeed,
                        calories: 0,
                        route: self.route
                    )
                    PulseSyncService.shared.stopSync()
                }
            }
    }
    
    private func stopListeners() {
        ridersListener?.remove()
        commandListener?.remove()
        groupRideListener?.remove()
        ridersListener = nil
        commandListener = nil
        groupRideListener = nil
        lastCommandTimestamp = 0
    }
    
    private func addOrUpdateRiderDocument(uid: String, profile: UserProfileBasic, coordinate: CLLocationCoordinate2D?, completion: ((Error?) -> Void)? = nil) {
        guard let rideId = groupRideId else {
            completion?(nil)
            return
        }
        var data: [String: Any] = [
            "name": profile.name,
            "photoURL": profile.photoURL ?? "",
            "updatedAt": Timestamp(date: Date()),
            "state": rideState == .paused ? "paused" : "active"
        ]
        if let coordinate = coordinate {
            data["lat"] = coordinate.latitude
            data["lon"] = coordinate.longitude
        }
        db.collection("groupRides").document(rideId)
            .collection("riders")
            .document(uid)
            .setData(data, merge: true, completion: completion)
    }
    
    private func syncCurrentLocationToGroup(_ location: CLLocation) {
        guard isGroupRide, let uid = Auth.auth().currentUser?.uid else { return }
        addOrUpdateRiderDocument(uid: uid, profile: currentUserProfile(), coordinate: location.coordinate)
    }
    
    private func currentUserProfile() -> UserProfileBasic {
        if let profile = FirebaseProfileService.shared.currentProfileOptional {
            return UserProfileBasic(name: profile.name, photoURL: profile.photoURL)
        }
        let name = UserDefaults.standard.string(forKey: "userName") ?? "Rider"
        let photo = UserDefaults.standard.string(forKey: "userPhotoURL")
        return UserProfileBasic(name: name, photoURL: photo)
    }
    
    // MARK: - Phase 34I: Haptic Pulse Sync
    
    private func startHapticPulseSync() {
        guard rideState == .active else { return }
        stopHapticPulseSync()
        
        hapticPulseTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            guard let self = self, self.rideState == .active else {
                self?.stopHapticPulseSync()
                return
            }
            
            // Use PulseSyncService phase if synced, otherwise use local timer
            let currentPhase: Double
            if PulseSyncService.shared.isSynced {
                currentPhase = PulseSyncService.shared.syncPhase
            } else {
                // Local pulse for solo rides
                guard let start = self.startTime else {
                    currentPhase = 0.0
                    return
                }
                let elapsed = Date().timeIntervalSince(start)
                currentPhase = (elapsed.truncatingRemainder(dividingBy: self.hapticPulseInterval)) / self.hapticPulseInterval
            }
            
            // Trigger haptic at pulse peak (phase 0.0 or crossing from 0.99 to 0.0)
            if (self.lastHapticPhase > 0.9 && currentPhase < 0.1) || (self.lastHapticPhase < 0 && currentPhase < 0.1) {
                self.triggerHapticPulse()
            }
            
            self.lastHapticPhase = currentPhase
        }
        
        print("💓 Haptic pulse sync started")
    }
    
    private func stopHapticPulseSync() {
        hapticPulseTimer?.invalidate()
        hapticPulseTimer = nil
        lastHapticPhase = -1.0
    }
    
    private func triggerHapticPulse() {
        // Subtle haptic feedback for group heartbeat
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.5)
    }
    
    // MARK: - Phase 35: Session Recovery
    
    private func startRecoverySaving() {
        recoverySaveTimer?.invalidate()
        recoverySaveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.saveRecoveryState()
        }
    }
    
    private func stopRecoverySaving() {
        recoverySaveTimer?.invalidate()
        recoverySaveTimer = nil
    }
    
    private func saveRecoveryState() {
        recoveryService.saveSession(
            state: rideState,
            distance: totalDistance,
            duration: duration,
            route: route,
            startTime: startTime,
            pausedTime: pausedTime,
            isGroupRide: isGroupRide,
            groupRideId: groupRideId
        )
    }
    
    /// Restore a previous ride session
    func restoreSession(_ session: RecoveredRideSession) {
        guard rideState == .idle else { return }
        
        rideState = session.state
        totalDistance = session.distance
        duration = session.duration
        route = session.route
        startTime = session.startTime
        pausedTime = session.pausedTime
        isGroupRide = session.isGroupRide
        groupRideId = session.groupRideId
        
        if let start = startTime {
            let elapsed = Date().timeIntervalSince(start)
            duration = elapsed - pausedTime
        }
        
        if duration > 0 && totalDistance > 0 {
            averageSpeed = totalDistance / duration
        }
        
        if rideState == .active {
            locationManager.startUpdatingLocation()
            startTimer()
            startHapticPulseSync()
        }
        
        startRecoverySaving()
        
        if isGroupRide, let rideId = groupRideId {
            listenForGroupRideUpdates()
            listenForCommands()
        }
        
        print("🔄 Restored ride session: \(rideState), \(String(format: "%.2f", totalDistance/1000)) km")
    }
}

// MARK: - Supporting types
enum RideSessionState {
    case idle, active, paused, ended
}

struct RiderInfo: Identifiable {
    let id: String
    let name: String
    let photoURL: String?
    let coordinate: CLLocationCoordinate2D?
    let isOnline: Bool
}

struct UserProfileBasic {
    let name: String
    let photoURL: String?
}

enum RideCommandAction: String {
    case pause, resume, end
}
