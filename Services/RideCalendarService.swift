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
 * Phase 40: Added calendar selection and permission management.
 */
final class RideCalendarService {
    static let shared = RideCalendarService()
    
    private let eventStore = EKEventStore()
    private var hasRequestedAccess = false
    
    private init() {
        print("📆 RideCalendarService initialized")
    }
    
    // MARK: - Phase 40: Calendar Permission Status
    
    /// Get current EventKit authorization status
    var calendarAuthorizationStatus: EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    /// Request calendar access (only call when user explicitly requests it)
    /// Phase 40: Updated for iOS 17+ APIs (write-only access is sufficient for saving events)
    /// - Parameter completion: Called with true if granted, false otherwise
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        let status = calendarAuthorizationStatus
        
        switch status {
        case .notDetermined:
            print("📆 Calendar permission: requesting access...")
            if #available(iOS 17.0, *) {
                // iOS 17+: Use write-only access (sufficient for saving events)
                eventStore.requestWriteOnlyAccessToEvents { granted, error in
                    DispatchQueue.main.async {
                        print("📆 Calendar permission: granted=\(granted), error=\(String(describing: error))")
                        completion(granted)
                    }
                }
            } else {
                // iOS 16 and earlier: Use legacy API
                eventStore.requestAccess(to: .event) { granted, error in
                    DispatchQueue.main.async {
                        print("📆 Calendar permission: granted=\(granted), error=\(String(describing: error))")
                        completion(granted)
                    }
                }
            }
        case .authorized, .fullAccess, .writeOnly:
            completion(true)
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Phase 40: Available Calendars
    
    /// Get all writable calendars available for saving rides
    /// Phase 40: Updated for iOS 17+ authorization status
    /// - Returns: Array of calendars that allow content modifications
    func availableWritableCalendars() -> [EKCalendar] {
        let status = calendarAuthorizationStatus
        // iOS 17+: Check for fullAccess or writeOnly; iOS 16: check for authorized
        let hasAccess: Bool
        if #available(iOS 17.0, *) {
            hasAccess = (status == .fullAccess || status == .writeOnly)
        } else {
            hasAccess = (status == .authorized)
        }
        
        guard hasAccess else {
            return []
        }
        
        let allCalendars = eventStore.calendars(for: .event)
        return allCalendars.filter { $0.allowsContentModifications }
    }
    
    // MARK: - Phase 40: Calendar Resolution
    
    /// Resolve the target calendar for saving rides
    /// Uses preferred calendar if set, otherwise falls back to default logic
    /// Phase 40: Handles deleted calendars gracefully by clearing invalid preferences
    /// - Returns: The calendar to use, or nil if none available
    @MainActor
    func resolveTargetCalendar() -> EKCalendar? {
        let status = calendarAuthorizationStatus
        // iOS 17+: Check for fullAccess or writeOnly; iOS 16: check for authorized
        let hasAccess: Bool
        if #available(iOS 17.0, *) {
            hasAccess = (status == .fullAccess || status == .writeOnly)
        } else {
            hasAccess = (status == .authorized)
        }
        
        guard hasAccess else {
            return nil
        }
        
        // Try to load preferred calendar from UserPreferenceManager (MainActor isolated)
        let preferences = UserPreferenceManager.shared
        if let preferredID = preferences.preferredCalendarIdentifier {
            if let preferredCalendar = eventStore.calendar(withIdentifier: preferredID),
               preferredCalendar.allowsContentModifications {
                print("📆 Calendar: Using preferred calendar: \(preferredCalendar.title)")
                return preferredCalendar
            } else {
                // Calendar was deleted or is no longer writable - clear preference
                print("⚠️ Calendar: Preferred calendar '\(preferredID)' no longer exists, clearing preference")
                preferences.preferredCalendarIdentifier = nil
            }
        }
        
        // Fallback to default calendar
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            print("📆 Calendar: Using default calendar: \(defaultCalendar.title)")
            return defaultCalendar
        }
        
        // Last resort: first writable calendar
        let writableCalendars = availableWritableCalendars()
        if let firstCalendar = writableCalendars.first {
            print("📆 Calendar: Using first available calendar: \(firstCalendar.title)")
            return firstCalendar
        }
        
        print("⚠️ Calendar: No writable calendars available")
        return nil
    }
    
    // MARK: - Public Methods
    
    /// Save a ride to the iOS Calendar app
    /// Phase 40: Now uses preferred calendar selection and only saves if authorized + calendar resolved
    /// - Parameters:
    ///   - ride: The ride record to save
    ///   - completion: Called with true if saved successfully, false otherwise
    func saveRideToCalendar(_ ride: RideRecord, completion: @escaping (Bool) -> Void) {
        // Phase 40: Check authorization and calendar resolution
        let status = calendarAuthorizationStatus
        
        // iOS 17+: Check for fullAccess or writeOnly; iOS 16: check for authorized
        let hasAccess: Bool
        if #available(iOS 17.0, *) {
            hasAccess = (status == .fullAccess || status == .writeOnly)
        } else {
            hasAccess = (status == .authorized)
        }
        
        guard hasAccess else {
            print("⚠️ Calendar: skipping save – no permission (status: \(status.rawValue))")
            completion(false)
            return
        }
        
        // Resolve calendar on main actor (UserPreferenceManager is MainActor isolated)
        Task { @MainActor in
            guard let targetCalendar = self.resolveTargetCalendar() else {
                print("⚠️ Calendar: skipping save – no calendar selection")
                completion(false)
                return
            }
            
            // Proceed with event creation using resolved calendar
            self.createEvent(for: ride, calendar: targetCalendar, completion: completion)
        }
    }
    
    // MARK: - Private Methods
    
    /// Create and save calendar event for a ride
    /// Phase 40: Now accepts explicit calendar parameter
    private func createEvent(for ride: RideRecord, calendar: EKCalendar, completion: @escaping (Bool) -> Void) {
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
            
            // Phase 40: Use the explicitly provided calendar
            event.calendar = calendar
            
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
            
            let title = event.title ?? "Untitled Event"
            let startDateStr = String(describing: event.startDate)
            let endDateStr = String(describing: event.endDate)
            print("📆 Calendar: attempting to save event with title '\(title)' from \(startDateStr) to \(endDateStr)")
            
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

