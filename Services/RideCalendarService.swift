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
@MainActor
final class RideCalendarService {
    static let shared = RideCalendarService()
    
    private let eventStore = EKEventStore()
    
    private init() {
        print("📆 RideCalendarService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Save a ride to the iOS Calendar app
    /// - Parameter ride: The ride record to save
    /// - Returns: True if the event was saved successfully, false otherwise
    func saveRideToCalendar(_ ride: RideRecord) async throws {
        // Request calendar access
        let granted = try await requestCalendarAccess()
        
        guard granted else {
            print("⚠️ Calendar: Permission denied by user")
            throw CalendarError.permissionDenied
        }
        
        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.title = formatRideTitle(ride)
        event.notes = formatRideNotes(ride)
        event.startDate = ride.date
        event.endDate = ride.date.addingTimeInterval(ride.duration)
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.isAllDay = false
        
        // Add location if route has coordinates
        if let firstLocation = ride.route.first {
            let location = CLLocation(latitude: firstLocation.latitude, longitude: firstLocation.longitude)
            let geocoder = CLGeocoder()
            // Note: Reverse geocoding is async, but we'll use coordinates as fallback
            event.location = String(format: "%.4f, %.4f", firstLocation.latitude, firstLocation.longitude)
        }
        
        print("📆 Calendar: attempting to save event with title '\(event.title)' from \(event.startDate) to \(event.endDate)")
        
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            print("📆 Calendar event saved successfully for ride at \(ride.date)")
        } catch {
            print("❌ Calendar: failed to save event – \(error.localizedDescription)")
            throw CalendarError.saveFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func requestCalendarAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .authorized:
            print("📆 Calendar permission: already granted")
            return true
            
        case .notDetermined:
            print("📆 Calendar permission: requesting access...")
            let granted = try await eventStore.requestAccess(to: .event)
            print("📆 Calendar permission: granted=\(granted), error=nil")
            return granted
            
        case .denied, .restricted:
            print("📆 Calendar permission: denied or restricted (status: \(status.rawValue))")
            return false
            
        @unknown default:
            print("📆 Calendar permission: unknown status (\(status.rawValue))")
            return false
        }
    }
    
    private func formatRideTitle(_ ride: RideRecord) -> String {
        let distanceMiles = ride.distance / 1609.34
        let hours = Int(ride.duration) / 3600
        let minutes = (Int(ride.duration) % 3600) / 60
        
        if hours > 0 {
            return String(format: "🚴 Branchr Ride: %.2f mi (%dh %dm)", distanceMiles, hours, minutes)
        } else {
            return String(format: "🚴 Branchr Ride: %.2f mi (%dm)", distanceMiles, minutes)
        }
    }
    
    private func formatRideNotes(_ ride: RideRecord) -> String {
        let distanceMiles = ride.distance / 1609.34
        let distanceKm = ride.distance / 1000.0
        let hours = Int(ride.duration) / 3600
        let minutes = (Int(ride.duration) % 3600) / 60
        let seconds = Int(ride.duration) % 60
        let avgSpeedMph = ride.averageSpeed * 2.237 // m/s to mph
        
        var notes = "Branchr Ride Summary\n\n"
        notes += "Distance: \(String(format: "%.2f", distanceMiles)) mi (\(String(format: "%.2f", distanceKm)) km)\n"
        
        if hours > 0 {
            notes += "Duration: \(hours)h \(minutes)m \(seconds)s\n"
        } else if minutes > 0 {
            notes += "Duration: \(minutes)m \(seconds)s\n"
        } else {
            notes += "Duration: \(seconds)s\n"
        }
        
        notes += String(format: "Average Speed: %.1f mph (%.1f km/h)\n", avgSpeedMph, ride.averageSpeed * 3.6)
        notes += "Route Points: \(ride.route.count)\n"
        
        return notes
    }
}

// MARK: - Calendar Errors

enum CalendarError: LocalizedError {
    case permissionDenied
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Calendar permission was denied"
        case .saveFailed(let error):
            return "Failed to save calendar event: \(error.localizedDescription)"
        }
    }
}

