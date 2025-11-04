//
//  ConnectedRidersSheet.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 20 - Group Ride UI + Dual-Audio Control System
//

import SwiftUI

/**
 * 🚴 Connected Riders Sheet
 *
 * Group ride interface with per-rider audio controls:
 * - Voice mute/unmute per rider
 * - Music mute/unmute per rider
 * - Animated sound level indicators
 * - Audio mode switcher (Voice/Music/Both)
 * - Host controls (mute all, SOS, end ride)
 */
struct ConnectedRidersSheet: View {
    
    @ObservedObject var groupManager: GroupSessionManager
    @ObservedObject var voiceService: VoiceChatService
    @ObservedObject var musicSync: MusicSyncService
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("audioMode") private var selectedAudioMode: String = "both"
    @State private var showingEndRideAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Connected Riders")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(theme.primaryText)
                            
                            Text("\(groupManager.groupSize) rider\(groupManager.groupSize == 1 ? "" : "s") connected")
                                .font(.subheadline)
                                .foregroundColor(theme.primaryText.opacity(0.7))
                        }
                        .padding(.top, 20)
                        
                        // Riders Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            // Host (Self)
                            RiderTile(
                                riderID: groupManager.myDisplayName,
                                name: groupManager.myDisplayName,
                                isHost: groupManager.isHost,
                                isSelf: true,
                                voiceService: voiceService,
                                musicSync: musicSync,
                                groupManager: groupManager
                            )
                            
                            // Connected Peers
                            ForEach(groupManager.connectedPeers, id: \.displayName) { peer in
                                RiderTile(
                                    riderID: peer.displayName,
                                    name: peer.displayName,
                                    isHost: false,
                                    isSelf: false,
                                    voiceService: voiceService,
                                    musicSync: musicSync,
                                    groupManager: groupManager
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Audio Mode Switcher
                        VStack(spacing: 12) {
                            Text("Audio Mode")
                                .font(.headline)
                                .foregroundColor(theme.primaryText)
                            
                            Picker("Audio Mode", selection: $selectedAudioMode) {
                                Text("Voice Only").tag("voice")
                                Text("Music Only").tag("music")
                                Text("Both").tag("both")
                            }
                            .pickerStyle(.segmented)
                            .tint(theme.accentColor)
                            .onChange(of: selectedAudioMode) { mode in
                                handleAudioModeChange(mode)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Host Controls
                        if groupManager.isHost {
                            HostControlsSection(
                                groupManager: groupManager,
                                voiceService: voiceService,
                                musicSync: musicSync,
                                showingEndRideAlert: $showingEndRideAlert
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.accentColor)
                }
            }
        }
        .alert("End Group Ride", isPresented: $showingEndRideAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Ride", role: .destructive) {
                groupManager.endGroupSession()
                dismiss()
            }
        } message: {
            Text("This will disconnect all riders from the group ride.")
        }
    }
    
    private func handleAudioModeChange(_ mode: String) {
        switch mode {
        case "voice":
            voiceService.isMuted = false
            musicSync.isMusicMuted = true
        case "music":
            voiceService.isMuted = true
            musicSync.isMusicMuted = false
        default: // "both"
            voiceService.isMuted = false
            musicSync.isMusicMuted = false
        }
    }
}

// MARK: - Rider Tile Component

struct RiderTile: View {
    let riderID: String
    let name: String
    let isHost: Bool
    let isSelf: Bool
    @ObservedObject var voiceService: VoiceChatService
    @ObservedObject var musicSync: MusicSyncService
    @ObservedObject var groupManager: GroupSessionManager
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar with Sound Indicator
            ZStack {
                // Avatar
                Image(systemName: isHost ? "crown.fill" : "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(theme.accentColor)
                    .frame(width: 60, height: 60)
                    .background(theme.cardBackground)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(theme.accentColor.opacity(0.3), lineWidth: 2)
                    )
                
                // Animated Sound Indicator
                if voiceService.isSpeaking(peerID: riderID) {
                    Circle()
                        .strokeBorder(theme.accentColor, lineWidth: 3)
                        .frame(width: 70, height: 70)
                        .scaleEffect(1.1)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: voiceService.isSpeaking(peerID: riderID))
                }
            }
            
            // Rider Name
            Text(name)
                .font(.subheadline.bold())
                .foregroundColor(theme.primaryText)
                .lineLimit(1)
            
            // Status Dot
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(theme.primaryText.opacity(0.7))
            }
            
            // Audio Controls (Phase 21: Visual Feedback)
            HStack(spacing: 12) {
                // Voice Mute Toggle - Green when active, Red when muted
                Button(action: {
                    if isSelf {
                        voiceService.toggleMute()
                    } else {
                        voiceService.toggleUserMute(peerID: riderID)
                    }
                }) {
                    Image(systemName: voiceService.isUserMuted(peerID: riderID) ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 16))
                        .foregroundColor(voiceService.isUserMuted(peerID: riderID) ? .white : .white)
                        .frame(width: 40, height: 40)
                        .background(voiceService.isUserMuted(peerID: riderID) ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(voiceService.isUserMuted(peerID: riderID) ? Color.red : Color.green, lineWidth: 2)
                        )
                        .cornerRadius(12)
                        .shadow(color: voiceService.isUserMuted(peerID: riderID) ? Color.red.opacity(0.3) : Color.green.opacity(0.3), radius: 6)
                }
                
                // Music Mute Toggle - Green when active, Gray when muted
                Button(action: {
                    if isSelf {
                        musicSync.toggleMusicMute()
                    }
                    // Note: Music mute is local only per rider
                }) {
                    Image(systemName: musicSync.isMusicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(musicSync.isMusicMuted ? .gray : .white)
                        .frame(width: 40, height: 40)
                        .background(musicSync.isMusicMuted ? Color.gray.opacity(0.2) : Color.green.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(musicSync.isMusicMuted ? Color.gray : Color.green, lineWidth: 2)
                        )
                        .cornerRadius(12)
                        .shadow(color: musicSync.isMusicMuted ? Color.gray.opacity(0.3) : Color.green.opacity(0.3), radius: 6)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHost ? theme.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .shadow(color: theme.accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var statusColor: Color {
        if voiceService.isUserMuted(peerID: riderID) {
            return .red
        } else if voiceService.isSpeaking(peerID: riderID) {
            return .green
        } else {
            return .gray
        }
    }
    
    private var statusText: String {
        if voiceService.isUserMuted(peerID: riderID) {
            return "Muted"
        } else if voiceService.isSpeaking(peerID: riderID) {
            return "Speaking"
        } else {
            return "Listening"
        }
    }
}

// MARK: - Host Controls Section

struct HostControlsSection: View {
    @ObservedObject var groupManager: GroupSessionManager
    @ObservedObject var voiceService: VoiceChatService
    @ObservedObject var musicSync: MusicSyncService
    @Binding var showingEndRideAlert: Bool
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Host Controls")
                .font(.headline)
                .foregroundColor(theme.primaryText)
            
            HStack(spacing: 12) {
                // Mute All Voices
                BranchrButton(title: "Mute All Voices", icon: "mic.slash.fill") {
                    groupManager.broadcastMuteAllVoices()
                }
                
                // Mute All Music
                BranchrButton(title: "Mute All Music", icon: "speaker.slash.fill") {
                    musicSync.muteAllMusic()
                }
            }
            
            HStack(spacing: 12) {
                // SOS
                BranchrButton(title: "SOS", icon: "exclamationmark.triangle.fill") {
                    groupManager.triggerSOS()
                }
                
                // End Ride
                BranchrButton(title: "End Ride", icon: "flag.checkered") {
                    showingEndRideAlert = true
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    ConnectedRidersSheet(
        groupManager: GroupSessionManager(),
        voiceService: VoiceChatService(),
        musicSync: MusicSyncService()
    )
    .preferredColorScheme(.dark)
}

