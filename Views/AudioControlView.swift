//
//  AudioControlView.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import SwiftUI

struct AudioControlView: View {
    
    // MARK: - State Objects
    @StateObject private var audioMixer = AudioMixerService()
    @StateObject private var noiseControl = AINoiseControlService()
    @ObservedObject private var theme = ThemeManager.shared
    
    // MARK: - State Variables
    @State private var showingAdvancedSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // MARK: - Header Section
                        headerSection
                        
                        // MARK: - Volume Controls
                        volumeControlsSection
                        
                        // MARK: - Mode Selection
                        modeSelectionSection
                        
                        // MARK: - AI Noise Control
                        noiseControlSection
                        
                        // MARK: - Advanced Settings
                        if showingAdvancedSettings {
                            advancedSettingsSection
                        }
                        
                        // MARK: - Action Buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Audio Control")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingAdvancedSettings ? "Simple" : "Advanced") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAdvancedSettings.toggle()
                        }
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
        .onAppear {
            setupServices()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Audio Control")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Fine-tune your ride audio experience")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Volume Controls Section
    private var volumeControlsSection: some View {
        VStack(spacing: 20) {
            Text("Volume Controls")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Voice Volume Slider
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                    
                    Text("Voice Volume")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(audioMixer.voiceVolume * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Slider(value: Binding(
                    get: { audioMixer.voiceVolume },
                    set: { audioMixer.setVoiceVolume($0) }
                ), in: 0...1, step: 0.05)
                .accentColor(.green)
                
                // Voice level indicator
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { index in
                        Rectangle()
                            .fill(voiceLevelColor(for: index))
                            .frame(width: 3, height: CGFloat(8 + index * 2))
                            .cornerRadius(1.5)
                    }
                }
            }
            
            // Music Volume Slider
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.purple)
                        .font(.system(size: 16))
                    
                    Text("Music Volume")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(audioMixer.musicVolume * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Slider(value: Binding(
                    get: { audioMixer.musicVolume },
                    set: { audioMixer.setMusicVolume($0) }
                ), in: 0...1, step: 0.05)
                .accentColor(.purple)
                
                // Music level indicator
                HStack(spacing: 2) {
                    ForEach(0..<10, id: \.self) { index in
                        Rectangle()
                            .fill(musicLevelColor(for: index))
                            .frame(width: 3, height: CGFloat(8 + index * 2))
                            .cornerRadius(1.5)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Mode Selection Section
    private var modeSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Audio Mode")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                ForEach(AudioMixerService.AudioMode.allCases, id: \.self) { mode in
                    Button(action: {
                        audioMixer.switchMode(mode)
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 24))
                                .foregroundColor(audioMixer.mode == mode ? .white : .gray)
                            
                            Text(mode.displayName)
                                .font(.caption)
                                .foregroundColor(audioMixer.mode == mode ? .white : .gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(audioMixer.mode == mode ? Color.blue : Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Noise Control Section
    private var noiseControlSection: some View {
        VStack(spacing: 16) {
            Text("AI Noise Control")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // AI Noise Filter Toggle
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                Text("AI Noise Filter")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { noiseControl.isNoiseFilterEnabled },
                    set: { value in
                        if value {
                            noiseControl.enableNoiseFilter()
                        } else {
                            noiseControl.disableNoiseFilter()
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
            
            // Wind Reduction Toggle
            HStack {
                Image(systemName: "wind")
                    .foregroundColor(.cyan)
                    .font(.system(size: 16))
                
                Text("Wind Reduction")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { noiseControl.isWindReductionEnabled },
                    set: { value in
                        if value {
                            noiseControl.enableWindReduction()
                        } else {
                            noiseControl.disableWindReduction()
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
            }
            
            // Auto Gain Toggle
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
                
                Text("Auto Gain")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { noiseControl.isAutoGainEnabled },
                    set: { value in
                        if value {
                            noiseControl.enableAutoGain()
                        } else {
                            noiseControl.disableAutoGain()
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Advanced Settings Section
    private var advancedSettingsSection: some View {
        VStack(spacing: 16) {
            Text("Advanced Settings")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Noise Reduction Level
            VStack(spacing: 8) {
                HStack {
                    Text("Noise Reduction Level")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(noiseControl.noiseReductionLevel * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Slider(value: Binding(
                    get: { noiseControl.noiseReductionLevel },
                    set: { noiseControl.setNoiseReductionLevel($0) }
                ), in: 0...1, step: 0.1)
                .accentColor(.orange)
            }
            
            // Wind Reduction Level
            VStack(spacing: 8) {
                HStack {
                    Text("Wind Reduction Level")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(noiseControl.windReductionLevel * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Slider(value: Binding(
                    get: { noiseControl.windReductionLevel },
                    set: { noiseControl.setWindReductionLevel($0) }
                ), in: 0...1, step: 0.1)
                .accentColor(.cyan)
            }
            
            // Auto Gain Level
            VStack(spacing: 8) {
                HStack {
                    Text("Auto Gain Level")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(noiseControl.autoGainLevel * 100))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Slider(value: Binding(
                    get: { noiseControl.autoGainLevel },
                    set: { noiseControl.setAutoGainLevel($0) }
                ), in: 0...1, step: 0.1)
                .accentColor(.yellow)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Start/Stop Audio Mixer
            Button(action: {
                if audioMixer.isActive {
                    audioMixer.stopMixer()
                } else {
                    audioMixer.startMixer()
                }
            }) {
                HStack {
                    Image(systemName: audioMixer.isActive ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 20))
                    
                    Text(audioMixer.isActive ? "Stop Audio Mixer" : "Start Audio Mixer")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(audioMixer.isActive ? .red : .green)
                .cornerRadius(12)
            }
            
            // Reset to Defaults
            Button(action: {
                audioMixer.resetToDefaults()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                    
                    Text("Reset to Defaults")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.gray)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupServices() {
        // Initialize audio mixer
        audioMixer.startMixer()
        
        // Setup noise control integration
        // This would connect the noise control service to the audio mixer
        print("Branchr: Audio control services initialized")
    }
    
    private func voiceLevelColor(for index: Int) -> Color {
        let threshold = Float(index) / 10.0
        return audioMixer.voiceVolume > threshold ? .green : .gray.opacity(0.3)
    }
    
    private func musicLevelColor(for index: Int) -> Color {
        let threshold = Float(index) / 10.0
        return audioMixer.musicVolume > threshold ? .purple : .gray.opacity(0.3)
    }
}

// MARK: - Preview
#Preview {
    AudioControlView()
}
