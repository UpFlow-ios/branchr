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
    @State private var showingModeSelection = false
    @State private var showingSafetySettings = false
    @State private var showingVoiceSettings = false
    @State private var showingProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Account Section
                SectionCard(title: "Account") {
                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                            Text("Profile")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primaryText)
                    }
                }
                
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
                
                Spacer(minLength: 100)
            }
            .padding(.vertical)
        }
        .background(theme.primaryBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingSafetySettings) {
            SafetyControlView()
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryButton)
            
            Text("branchr")
                .font(.title.bold())
                .foregroundColor(theme.primaryText)
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .padding(.vertical, 20)
    }
    
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
}

