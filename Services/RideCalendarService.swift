//
//  RideCalendarService.swift
//  branchr
//
//  Created for Phase 35B - EventKit Calendar Integration
//

import Foundation
import EventKit
import CoreLocation
import SwiftUI

/**
 * 📆 Ride Calendar Service
 *
 * Handles saving rides to the iOS Calendar app using EventKit.
 * Creates calendar events with ride details (distance, duration, route).
 */
final class RideCalendarService {
    static let shared = RideCalendarService()
    
    private let eventStore = EKEventStore()
    private var hasRequestedAccess = false
    
    private init() {
        print("📆 RideCalendarService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Save a ride to the iOS Calendar app
    /// - Parameters:
    ///   - ride: The ride record to save
    ///   - completion: Called with true if saved successfully, false otherwise
    func saveRideToCalendar(_ ride: RideRecord, completion: @escaping (Bool) -> Void) {
        // Request permission if needed
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            print("📆 Calendar permission: requesting access...")
            eventStore.requestAccess(to: .event) { granted, error in
                print("📆 Calendar permission: granted=\(granted), error=\(String(describing: error))")
                if granted {
                    self.createEvent(for: ride, completion: completion)
                } else {
                    print("⚠️ Calendar: Permission denied - skipping calendar save")
                    completion(false)
                }
            }
            
        case .authorized:
            createEvent(for: ride, completion: completion)
            
        case .denied, .restricted:
            print("⚠️ Calendar: Permission denied/restricted - skipping calendar save")
            completion(false)
            
        @unknown default:
            print("⚠️ Calendar: Unknown authorization status - skipping calendar save")
            completion(false)
        }
    }
    
    // MARK: - Private Methods
    
    private func createEvent(for ride: RideRecord, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let event = EKEvent(eventStore: self.eventStore)
            
            // Format title with distance and duration
            let distanceMiles = ride.distance / 1609.34
            let hours = Int(ride.duration) / 3600
            let minutes = (Int(ride.duration) % 3600) / 60
            
            let titleDistance = String(format: "%.2f", distanceMiles)
            let titleDuration: String
            if hours > 0 {
                titleDuration = "\(hours)h \(minutes)m"
            } else {
                titleDuration = "\(minutes)m"
            }
            
            event.title = "🚴 Branchr Ride: \(titleDistance) mi (\(titleDuration))"
            
            // Start/end times based on ride's recorded date + duration
            let startDate = ride.date
            let endDate = ride.date.addingTimeInterval(ride.duration)
            event.startDate = startDate
            event.endDate = endDate
            
            // Use default calendar, or first available calendar if default is nil
            if let defaultCalendar = self.eventStore.defaultCalendarForNewEvents {
                event.calendar = defaultCalendar
            } else if let firstCalendar = self.eventStore.calendars(for: .event).first {
                event.calendar = firstCalendar
                print("⚠️ Calendar: Using first available calendar (default was nil)")
            } else {
                print("❌ Calendar: No calendars available - cannot save event")
                completion(false)
                return
            }
            
            event.isAllDay = false
            
            // Optional notes/metadata (keep brief)
            let avgSpeedMph = ride.averageSpeed * 2.237 // m/s to mph
            let formattedDuration: String
            if hours > 0 {
                let mins = (Int(ride.duration) % 3600) / 60
                let secs = Int(ride.duration) % 60
                formattedDuration = "\(hours)h \(mins)m \(secs)s"
            } else {
                let mins = Int(ride.duration) / 60
                let secs = Int(ride.duration) % 60
                formattedDuration = "\(mins)m \(secs)s"
            }
            
            event.notes = """
            Distance: \(titleDistance) miles
            Duration: \(formattedDuration)
            Avg speed: \(String(format: "%.1f", avgSpeedMph)) mph
            """
            
            // Add location if route has coordinates
            if let firstLocation = ride.route.first {
                event.location = String(format: "%.4f, %.4f", firstLocation.latitude, firstLocation.longitude)
            }
            
            print("📆 Calendar: attempting to save event with title '\(event.title ?? "")' from \(event.startDate) to \(event.endDate)")
            
            do {
                try self.eventStore.save(event, span: .thisEvent)
                print("📆 Calendar event saved successfully with title: \(event.title ?? "")")
                completion(true)
            } catch {
                print("⚠️ Calendar save error: \(error)")
                completion(false)
            }
        }
    }
}

