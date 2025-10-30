//
//  SafetyControlView.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//

import SwiftUI

struct SafetyControlView: View {
    @ObservedObject var theme = ThemeManager.shared
    @State private var showEmergencyAlert = false
    @State private var emergencyContacts: [String] = ["Joe Dormond", "Manny Ramirez", "Anthony Torres"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Emergency SOS Section
                    SectionCard(title: "Emergency SOS") {
                        emergencySOSSection
                    }
                    
                    // Auto-Safety Features
                    SectionCard(title: "Auto-Safety Features") {
                        autoSafetySection
                    }
                    
                    // Emergency Contacts
                    SectionCard(title: "Emergency Contacts") {
                        emergencyContactsSection
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Safety & SOS")
            .navigationBarTitleDisplayMode(.large)
            .alert("SOS Triggered", isPresented: $showEmergencyAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    triggerSOS()
                }
            } message: {
                Text("This will send emergency alerts to your contacts and emergency services.")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Safety Mode")
                .font(.title.bold())
                .foregroundColor(theme.primaryText)
            
            Text("Your safety is our priority")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Emergency SOS Section
    private var emergencySOSSection: some View {
        Button(action: {
            showEmergencyAlert = true
        }) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                Text("Trigger Emergency SOS")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.red)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Auto-Safety Section
    private var autoSafetySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ToggleRow(title: "Auto-mute at High Speed", isOn: .constant(true))
            ToggleRow(title: "Crash Detection", isOn: .constant(true))
            ToggleRow(title: "Motion Alerts", isOn: .constant(false))
        }
    }
    
    // MARK: - Emergency Contacts Section
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(emergencyContacts, id: \.self) { contact in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(theme.primaryButton)
                    Text(contact)
                        .foregroundColor(theme.primaryText)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    theme.isDarkMode
                        ? Color.white.opacity(0.05)
                        : Color.black.opacity(0.06)
                )
                .cornerRadius(10)
            }
        }
    }
    
    private func triggerSOS() {
        print("🚨 Emergency SOS triggered")
        // In production, this would:
        // 1. Send emergency message to contacts
        // 2. Call emergency services
        // 3. Share location
        // 4. Alert group riders
    }
}

// Helper view for toggle rows
private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(theme.primaryText)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(theme.primaryButton)
        }
        .padding(.vertical, 8)
    }
}

