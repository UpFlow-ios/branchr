//
//  SettingsView.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var modeManager = ModeManager.shared
    @ObservedObject var cloudSync = RideCloudSyncService.shared
    @ObservedObject var watchService = WatchConnectivityService.shared
    @ObservedObject var userPreferences = UserPreferenceManager.shared
    @State private var showingModeSelection = false
    @State private var showingSafetySettings = false
    @State private var showingVoiceSettings = false
    @State private var showingCalendarSettings = false
    
    var body: some View {
        // Phase 30: Static Settings View (no ScrollView, no logo)
        VStack(spacing: 24) {
            // Title
            Text("Settings")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(theme.primaryText)
                .padding(.top, 50)
            
            // Voice & Audio Section (Phase 30)
                SectionCard(title: "Voice & Audio") {
                    Button(action: {
                        showingVoiceSettings = true
                    }) {
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                            Text("Voice & Audio Settings")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primaryText)
                    }
                }
                
                // Phase 40: Calendar & Export Section
                SectionCard(title: "Calendar & Export") {
                    Button(action: {
                        showingCalendarSettings = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("Ride Calendar")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primaryText)
                    }
                }
                
                // Phase 41: Ride Goals Section
                SectionCard(title: "Ride Goals") {
                    weeklyGoalEditor
                }
                
                // Theme Settings
                SectionCard(title: "Appearance") {
                    themeToggle
                }
                
                // Mode Selection
                SectionCard(title: "Active Mode") {
                    modeSelection
                }
                
                // Cloud Sync Status
                SectionCard(title: "iCloud Sync") {
                    cloudStatus
                }
                
                // Watch Connection
                SectionCard(title: "Apple Watch") {
                    watchStatus
                }
                
                // Safety Settings Link
                Button(action: {
                    showingSafetySettings = true
                }) {
                    HStack {
                        Image(systemName: "shield.checkered")
                        Text("Safety & SOS Settings")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primaryButton)
                    .foregroundColor(theme.primaryButtonText)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.primaryBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Phase 30: Lock tab bar background to yellow
            UITabBar.appearance().backgroundColor = UIColor(theme.accentColor)
            UITabBar.appearance().unselectedItemTintColor = UIColor.black
        }
        .sheet(isPresented: $showingSafetySettings) {
            SafetyControlView()
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
        .sheet(isPresented: $showingCalendarSettings) {
            CalendarSettingsView()
        }
    }
    
    // Phase 30: Header section removed (no logo)
    
    // MARK: - Theme Toggle
    private var themeToggle: some View {
        HStack {
            Text("Appearance")
                .foregroundColor(theme.primaryText)
            Spacer()
            
            Button(action: {
                theme.toggleTheme()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
                    Text(theme.isDarkMode ? "Dark" : "Light")
                        .font(.subheadline.bold())
                }
                .foregroundColor(theme.primaryButtonText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(theme.primaryButton)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Mode Selection
    private var modeSelection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Current Mode")
                    .foregroundColor(theme.primaryText)
                Spacer()
                Text(modeManager.activeMode.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(theme.primaryButton)
            }
            
            Button(action: {
                showingModeSelection = true
            }) {
                Text("Change Mode")
                    .font(.subheadline.bold())
                    .foregroundColor(theme.primaryButtonText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.primaryButton)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Cloud Status
    private var cloudStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            if cloudSync.isSyncing {
                HStack {
                    ProgressView()
                        .tint(theme.primaryButton)
                    Text("Syncing to iCloud...")
                        .foregroundColor(theme.primaryText)
                }
            } else if let lastSync = cloudSync.lastSync {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundColor(theme.primaryText)
                }
            } else {
                Text("iCloud sync not configured")
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    // MARK: - Watch Status
    private var watchStatus: some View {
        HStack {
            Text("Apple Watch")
                .foregroundColor(theme.primaryText)
            Spacer()
            
            if watchService.isWatchConnected {
                Image(systemName: "applewatch")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "applewatch.slash")
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    // MARK: - Phase 41: Weekly Goal Editor
    private var weeklyGoalEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Distance Goal")
                    .foregroundColor(theme.primaryText)
                Spacer()
                Text("\(String(format: "%.0f", userPreferences.weeklyDistanceGoalMiles)) mi")
                    .font(.subheadline.bold())
                    .foregroundColor(theme.accentColor)
            }
            
            Stepper(
                value: Binding(
                    get: { userPreferences.weeklyDistanceGoalMiles },
                    set: { newValue in
                        userPreferences.weeklyDistanceGoalMiles = newValue
                    }
                ),
                in: 5...200,
                step: 5
            ) {
                Text("Adjust goal")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            .tint(theme.accentColor)
        }
    }
}

