//
//  VoiceSettingsView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI
import AVFoundation

/// Settings view for voice assistant and audio preferences
/// Provides toggles for voice features with glass-style design
struct VoiceSettingsView: View {
    
    // MARK: - State Objects
    @StateObject private var preferenceManager = UserPreferenceManager.shared
    @StateObject private var voiceAssistant = VoiceAssistantService()
    @StateObject private var speechCommands = SpeechCommandService()
    
    // MARK: - State Variables
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    // MARK: - Body
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Phase 31: Apply Branchr theme
                theme.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        voiceAssistantSection
                        voiceCommandsSection
                        audioAnnouncementsSection
                        musicSyncSection
                        hapticFeedbackSection
                        resetSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Voice & Audio")
            .navigationBarTitleDisplayMode(.large)
            .foregroundColor(theme.primaryText)
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(permissionAlertMessage)
        }
        .onAppear {
            voiceAssistant.setEnabled(preferenceManager.voiceAssistantEnabled)
            speechCommands.setEnabled(preferenceManager.voiceCommandsEnabled)
        }
        .onChange(of: preferenceManager.voiceAssistantEnabled) { _, enabled in
            voiceAssistant.setEnabled(enabled)
        }
        .onChange(of: preferenceManager.voiceCommandsEnabled) { _, enabled in
            speechCommands.setEnabled(enabled)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Voice Assistant")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Text("Hear real-time ride updates and use voice commands hands-free")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Voice Assistant Section
    private var voiceAssistantSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Voice Assistant")
                .font(.headline)
                .foregroundColor(.white)
            
            Toggle("Enable Voice Assistant", isOn: $preferenceManager.voiceAssistantEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .foregroundColor(.white)
            
            if preferenceManager.voiceAssistantEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Features:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    FeatureRow(icon: "speaker.wave.2.fill", text: "Real-time distance announcements")
                    FeatureRow(icon: "speedometer", text: "Speed and progress updates")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Ride completion summaries")
                }
                .padding(.leading, 16)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Voice Commands Section
    private var voiceCommandsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Voice Commands")
                .font(.headline)
                .foregroundColor(.white)
            
            Toggle("Enable Voice Commands", isOn: $preferenceManager.voiceCommandsEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .foregroundColor(.white)
            
            if preferenceManager.voiceCommandsEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Commands:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    CommandRow(command: "Pause tracking", description: "Pause your ride")
                    CommandRow(command: "Resume ride", description: "Continue your ride")
                    CommandRow(command: "Stop ride", description: "End your ride")
                    CommandRow(command: "Status update", description: "Get current stats")
                }
                .padding(.leading, 16)
                
                if !speechCommands.hasPermission {
                    Button("Grant Microphone Permission") {
                        requestMicrophonePermission()
                    }
                    .foregroundColor(.orange)
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Audio Announcements Section
    private var audioAnnouncementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Audio Announcements")
                .font(.headline)
                .foregroundColor(.white)
            
            Toggle("Enable Audio Announcements", isOn: $preferenceManager.audioAnnouncementsEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .purple))
                .foregroundColor(.white)
            
            if preferenceManager.audioAnnouncementsEnabled {
                Text("Hear announcements every 0.5 miles during your ride")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Music Sync Section
    private var musicSyncSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Music Sync")
                .font(.headline)
                .foregroundColor(.white)
            
            Toggle("Enable Music Sync", isOn: $preferenceManager.musicSyncEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .foregroundColor(.white)
            
            if preferenceManager.musicSyncEnabled {
                Text("Sync music playback with group rides")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Haptic Feedback Section
    private var hapticFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Haptic Feedback")
                .font(.headline)
                .foregroundColor(.white)
            
            Toggle("Enable Haptic Feedback", isOn: $preferenceManager.hapticFeedbackEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .pink))
                .foregroundColor(.white)
            
            if preferenceManager.hapticFeedbackEnabled {
                Text("Feel vibrations for ride milestones and notifications")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Reset Section
    private var resetSection: some View {
        VStack(spacing: 16) {
            Button("Reset to Defaults") {
                preferenceManager.resetToDefaults()
            }
            .foregroundColor(.red)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Views
    private func FeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private func CommandRow(command: String, description: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .foregroundColor(.green)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\"\(command)\"")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Branchr: Microphone permission granted")
                } else {
                    permissionAlertMessage = "Microphone access is required for voice commands. Please enable it in Settings."
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Preview
struct VoiceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceSettingsView()
            .preferredColorScheme(.dark)
    }
}
