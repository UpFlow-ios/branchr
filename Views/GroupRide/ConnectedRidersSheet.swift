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
                            
                            HStack(spacing: 8) {
                                Text("\(groupManager.groupSize) rider\(groupManager.groupSize == 1 ? "" : "s") connected")
                                    .font(.subheadline)
                                    .foregroundColor(theme.primaryText.opacity(0.7))
                                
                                // Phase 23: Show Firebase online count
                                if !groupManager.onlineRiders.isEmpty {
                                    Text("•")
                                        .foregroundColor(theme.primaryText.opacity(0.5))
                                    Text("\(groupManager.onlineRiders.filter { $0.isOnline }.count) online")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Phase 23: Firebase Online Riders Section
                        if !groupManager.onlineRiders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Online Riders")
                                    .font(.headline)
                                    .foregroundColor(theme.primaryText)
                                    .padding(.horizontal, 20)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 16) {
                                    ForEach(groupManager.onlineRiders) { rider in
                                        RiderCard(profile: rider, theme: theme)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 10)
                        }
                        
                        // Riders Grid (Phase 21B: Using Profile Data - Local Multipeer)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nearby Riders (Bluetooth)")
                                .font(.headline)
                                .foregroundColor(theme.primaryText)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                // Host (Self) - Use profile data
                                RiderTile(
                                    riderID: groupManager.myDisplayName,
                                    profile: groupManager.myProfile,
                                    isHost: groupManager.isHost,
                                    isSelf: true,
                                    voiceService: voiceService,
                                    musicSync: musicSync,
                                    groupManager: groupManager
                                )
                                
                                // Connected Peers - Use profile data
                                ForEach(groupManager.connectedPeers, id: \.displayName) { peer in
                                    RiderTile(
                                        riderID: peer.displayName,
                                        profile: groupManager.getProfile(for: peer),
                                        isHost: false,
                                        isSelf: false,
                                        voiceService: voiceService,
                                        musicSync: musicSync,
                                        groupManager: groupManager
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 10)
                        .onAppear {
                            // Broadcast profile when sheet appears
                            groupManager.broadcastProfile()
                            // Phase 23: Start listening for Firebase presence
                            groupManager.startListeningForPresence()
                        }
                        .onDisappear {
                            // Phase 23: Stop listening when sheet closes
                            // Note: Don't stop here if group session is still active
                        }
                        
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
                        LegacyHostControlsSection(
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
    let profile: RiderProfile // Phase 21B: Use profile data
    let isHost: Bool
    let isSelf: Bool
    @ObservedObject var voiceService: VoiceChatService
    @ObservedObject var musicSync: MusicSyncService
    @ObservedObject var groupManager: GroupSessionManager
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar with Sound Indicator (Phase 21B: Profile Photo)
            ZStack {
                // Profile Photo or Initials
                if let image = profile.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(theme.accentColor, lineWidth: isHost ? 3 : 2)
                        )
                        .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    // Default avatar with initials
                    Circle()
                        .fill(theme.accentColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(profile.name.prefix(1).uppercased()))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(theme.accentColor)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(theme.accentColor, lineWidth: isHost ? 3 : 2)
                        )
                        .shadow(color: theme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Phase 31: Crown icon removed per user request
                
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
            
            // Rider Name (from profile)
            VStack(spacing: 2) {
                Text(profile.name)
                    .font(.subheadline.bold())
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                
                // Bio preview (if available)
                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(.caption2)
                        .foregroundColor(theme.primaryText.opacity(0.6))
                        .lineLimit(1)
                }
            }
            
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

// MARK: - Legacy Host Controls Section (Phase 35.2: Renamed to avoid conflict)

struct LegacyHostControlsSection: View {
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
            
            // Phase 34: Mute All Voices - Toggle text & color
            Button(action: {
                groupManager.toggleMuteVoices()
            }) {
                Text(groupManager.isMutingVoices ? "Unmute All Voices" : "Mute All Voices")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(groupManager.isMutingVoices ? Color.red : Color.branchrButtonBackground)
                    .foregroundColor(groupManager.isMutingVoices ? .white : Color.branchrButtonText)
                    .cornerRadius(12)
            }
            
            // Phase 34: Mute All Music - Toggle text & color
            Button(action: {
                groupManager.toggleMuteMusic()
                if groupManager.isMutingMusic {
                    musicSync.muteAllMusic()
                } else {
                    musicSync.isMusicMuted = false
                }
            }) {
                Text(groupManager.isMutingMusic ? "Unmute Music" : "Mute All Music")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(groupManager.isMutingMusic ? Color.red : Color.branchrButtonBackground)
                    .foregroundColor(groupManager.isMutingMusic ? .white : Color.branchrButtonText)
                    .cornerRadius(12)
            }
            
            // Phase 34: SOS - Always red
            Button(action: {
                groupManager.triggerSOS()
            }) {
                Text("🆘 SOS")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            // Phase 34: End Ride - Always red
            Button(action: {
                showingEndRideAlert = true
            }) {
                Text("End Ride")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Phase 23: Rider Card Component (Firebase Online Presence)

struct RiderCard: View {
    let profile: UserProfile
    @ObservedObject var theme: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Phase 34: Profile Photo with Green Online Ring
            ZStack {
                // Green ring when online
                if profile.isOnline {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 60, height: 60)
                }
                
                // Profile Photo
                if let photoURL = profile.photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            Circle()
                                .fill(theme.accentColor.opacity(0.3))
                                .overlay(
                                    Text(String(profile.name.prefix(1).uppercased()))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(theme.accentColor)
                                )
                        @unknown default:
                            Circle()
                                .fill(theme.accentColor.opacity(0.3))
                        }
                    }
                    .frame(width: 55, height: 55)
                    .clipShape(Circle())
                } else {
                    // Default avatar with initials
                    Circle()
                        .fill(theme.accentColor.opacity(0.3))
                        .frame(width: 55, height: 55)
                        .overlay(
                            Text(String(profile.name.prefix(1).uppercased()))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(theme.accentColor)
                        )
                }
            }
            
            // Rider Name
            Text(profile.name)
                .font(.caption.bold())
                .foregroundColor(theme.primaryText)
                .lineLimit(1)
            
            // Bio (if available)
            if !profile.bio.isEmpty {
                Text(profile.bio)
                    .font(.caption2)
                    .foregroundColor(theme.primaryText.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(theme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(profile.isOnline ? Color.green.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
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

