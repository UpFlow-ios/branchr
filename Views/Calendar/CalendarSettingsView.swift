//
//  CalendarSettingsView.swift
//  branchr
//
//  Created for Phase 40 - Calendar Settings & Apple Calendar Selection
//

import SwiftUI
import EventKit

/**
 * 📆 Calendar Settings View
 *
 * Allows users to:
 * - View calendar permission status
 * - Request calendar access
 * - Select which Apple Calendar Branchr writes rides into
 */
struct CalendarSettingsView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var preferences = UserPreferenceManager.shared
    private let calendarService = RideCalendarService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @State private var availableCalendars: [EKCalendar] = []
    @State private var selectedCalendarID: String?
    @State private var isRequestingAccess = false
    @State private var showingSettingsAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Calendar & Export")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        
                        Text("Choose where Branchr saves your rides")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.top, 20)
                    
                    // Status Section
                    statusSection
                        .padding(.horizontal, 16)
                    
                    // Permission Action Section
                    // Phase 40: iOS 17+ uses .fullAccess or .writeOnly instead of .authorized
                    let hasAccess: Bool = {
                        if #available(iOS 17.0, *) {
                            return authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
                        } else {
                            return authorizationStatus == .authorized
                        }
                    }()
                    
                    if !hasAccess {
                        permissionActionSection
                            .padding(.horizontal, 16)
                    }
                    
                    // Calendar Picker Section (only if authorized)
                    if hasAccess {
                        calendarPickerSection
                            .padding(.horizontal, 16)
                    }
                    
                    // Info Footer
                    infoFooter
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
            .onAppear {
                updateAuthorizationStatus()
                loadCalendars()
            }
            .alert("Open Settings", isPresented: $showingSettingsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    openAppSettings()
                }
            } message: {
                Text("To enable calendar access, please open Settings and allow Branchr to access your calendars.")
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Access Status")
                .font(.headline)
                .foregroundColor(theme.primaryText)
            
            HStack {
                statusIcon
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(theme.primaryText)
                Spacer()
            }
            .padding()
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch authorizationStatus {
            case .authorized:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .fullAccess:
                if #available(iOS 17.0, *) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(theme.secondaryText)
                }
            case .writeOnly:
                if #available(iOS 17.0, *) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(theme.secondaryText)
                }
            case .denied, .restricted:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .notDetermined:
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(theme.secondaryText)
            @unknown default:
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    private var statusText: String {
        switch authorizationStatus {
        case .authorized:
            return "Access: Allowed"
        case .fullAccess:
            if #available(iOS 17.0, *) {
                return "Access: Full Access"
            } else {
                return "Access: Allowed"
            }
        case .writeOnly:
            if #available(iOS 17.0, *) {
                return "Access: Write Only"
            } else {
                return "Access: Allowed"
            }
        case .denied:
            return "Access: Denied"
        case .restricted:
            return "Access: Restricted"
        case .notDetermined:
            return "Access: Not Determined"
        @unknown default:
            return "Access: Unknown"
        }
    }
    
    // MARK: - Permission Action Section
    
    private var permissionActionSection: some View {
        VStack(spacing: 16) {
            if authorizationStatus == .notDetermined {
                Button(action: {
                    requestCalendarAccess()
                }) {
                    HStack {
                        if isRequestingAccess {
                            ProgressView()
                                .tint(theme.primaryButtonText)
                        } else {
                            Image(systemName: "calendar.badge.plus")
                        }
                        Text(isRequestingAccess ? "Requesting Access..." : "Allow Calendar Access")
                            .font(.headline)
                    }
                    .foregroundColor(theme.primaryButtonText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryButton)
                    .cornerRadius(12)
                }
                .disabled(isRequestingAccess)
            } else if authorizationStatus == .denied {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Calendar access is currently denied. To enable it:")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                    
                    Text("1. Open iOS Settings")
                        .font(.subheadline)
                        .foregroundColor(theme.primaryText)
                    Text("2. Find Branchr")
                        .font(.subheadline)
                        .foregroundColor(theme.primaryText)
                    Text("3. Enable Calendar access")
                        .font(.subheadline)
                        .foregroundColor(theme.primaryText)
                }
                .padding()
                .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                
                Button(action: {
                    showingSettingsAlert = true
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                            .font(.headline)
                    }
                    .foregroundColor(theme.primaryButtonText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryButton)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Calendar Picker Section
    
    private var calendarPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Calendar")
                .font(.headline)
                .foregroundColor(theme.primaryText)
            
            if availableCalendars.isEmpty {
                Text("No writable calendars available")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                        CalendarRow(
                            calendar: calendar,
                            isSelected: selectedCalendarID == calendar.calendarIdentifier,
                            theme: theme
                        ) {
                            selectCalendar(calendar)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Info Footer
    
    private var infoFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Calendar Export")
                .font(.subheadline.bold())
                .foregroundColor(theme.primaryText)
            
            Text("Branchr writes completed rides as events to your selected calendar. Upcoming versions will add richer calendar summaries.")
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .padding()
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func updateAuthorizationStatus() {
        authorizationStatus = calendarService.calendarAuthorizationStatus
    }
    
    private func loadCalendars() {
        availableCalendars = calendarService.availableWritableCalendars()
        
        // Load selected calendar from preferences
        if let preferredID = preferences.preferredCalendarIdentifier {
            selectedCalendarID = preferredID
        } else {
            // Default to first available calendar if none selected
            selectedCalendarID = availableCalendars.first?.calendarIdentifier
        }
    }
    
    private func requestCalendarAccess() {
        isRequestingAccess = true
        calendarService.requestCalendarAccess { granted in
            isRequestingAccess = false
            updateAuthorizationStatus()
            if granted {
                loadCalendars()
            }
        }
    }
    
    private func selectCalendar(_ calendar: EKCalendar) {
        selectedCalendarID = calendar.calendarIdentifier
        preferences.preferredCalendarIdentifier = calendar.calendarIdentifier
        print("📆 CalendarSettingsView: Selected calendar: \(calendar.title)")
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Calendar Row Component

struct CalendarRow: View {
    let calendar: EKCalendar
    let isSelected: Bool
    let theme: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Calendar color indicator
                Circle()
                    .fill(Color(calendar.cgColor))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(calendar.title)
                        .font(.subheadline.bold())
                        .foregroundColor(theme.primaryText)
                    
                    if let source = calendar.source {
                        Text(source.title)
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding()
            .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

