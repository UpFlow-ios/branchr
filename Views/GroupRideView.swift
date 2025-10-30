//
//  GroupRideView.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import SwiftUI
import MusicKit

struct GroupRideView: View {
    
    // MARK: - State Objects
    @StateObject private var groupManager = GroupSessionManager()
    @StateObject private var musicSync = MusicSyncService()
    @StateObject private var pandoraService = PandoraIntegrationService()
    @StateObject private var songRequests = SongRequestManager()
    @StateObject private var hostDJ = HostDJController(musicSync: MusicSyncService(), songRequests: SongRequestManager())
    @StateObject private var voiceService = VoiceChatService()
    @StateObject private var hudManager = HUDManager()
    @StateObject private var gestureService = GestureControlService()
    @StateObject private var remoteCommands = RemoteCommandRegistrar()
    @ObservedObject private var theme = ThemeManager.shared
    
    // MARK: - State Variables
    @State private var showingLeaveAlert = false
    @State private var showingAudioControl = false
    @State private var showingDJControls = false
    @State private var showingSongRequest = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    // Background
                    theme.primaryBackground.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // MARK: - Music Status Banner
                            if musicSync.currentTrack != nil {
                                MusicStatusBannerView(
                                    musicSync: musicSync,
                                    pandoraService: pandoraService
                                )
                            }
                            
                            // MARK: - Header Section
                            headerSection
                            
                            // MARK: - Group Status
                            groupStatusSection
                            
                            // MARK: - Connected Riders
                            connectedRidersSection
                            
                            // MARK: - DJ Controls Section
                            djControlsSection
                            
                            // MARK: - Voice Chat Controls
                            voiceChatSection
                            
                            // MARK: - Action Buttons
                            actionButtonsSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                }
                .navigationTitle("Group Ride")
                .navigationBarTitleDisplayMode(.inline)
                .preferredColorScheme(.dark)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Leave") {
                            showingLeaveAlert = true
                        }
                        .foregroundColor(.red)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            // DJ Controls Button (Host only)
                            if groupManager.isHost {
                                Button(action: {
                                    showingDJControls = true
                                }) {
                                    Image(systemName: "music.note.house.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // HUD Toggle Button
                            Button(action: {
                                hudManager.toggleHUD()
                            }) {
                                Image(systemName: hudManager.isVisible ? "eye.fill" : "eye")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                            
                            // Audio Control Button
                            Button(action: {
                                showingAudioControl = true
                            }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                            
                            Text("\(groupManager.groupSize)/4")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // MARK: - HUD Overlay
            if hudManager.isVisible {
                VStack {
                    HStack {
                        Spacer()
                        RideHUDView()
                            .padding(.top, 100)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            setupServices()
        }
        .sheet(isPresented: $showingAudioControl) {
            AudioControlView()
        }
        .sheet(isPresented: $showingDJControls) {
            DJControlView(
                dj: hostDJ,
                musicSync: musicSync,
                songRequests: songRequests
            )
        }
        .sheet(isPresented: $showingSongRequest) {
            SongRequestSheet(songRequests: songRequests)
        }
        .alert("Leave Group Ride", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                leaveGroupRide()
            }
        } message: {
            Text("Are you sure you want to leave the group ride?")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Group Ride Mode")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(groupManager.isHost ? "You're hosting" : "Connected to group")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Group Status Section
    private var groupStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(groupManager.sessionActive ? .green : .gray)
                    .frame(width: 12, height: 12)
                
                Text(groupManager.sessionActive ? "Group Active" : "Disconnected")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Sync Status
                HStack(spacing: 4) {
                    Circle()
                        .fill(musicSync.isHostDJ ? Color.green : Color.blue)
                        .frame(width: 8, height: 8)
                    
                    Text(musicSync.isHostDJ ? "Host DJ" : "Connected")
                        .font(.caption)
                        .foregroundColor(musicSync.isHostDJ ? Color.green : Color.blue)
                }
            }
            
            if groupManager.maxPeersReached {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.orange)
                    
                    Text("Group is full")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Connected Riders Section
    private var connectedRidersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connected Riders")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(groupManager.groupSize)/4")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // Host (self)
                riderCard(
                    name: groupManager.myDisplayName,
                    isHost: true,
                    isConnected: true,
                    isSelf: true
                )
                
                // Connected peers
                ForEach(groupManager.connectedPeers, id: \.displayName) { peer in
                    riderCard(
                        name: peer.displayName,
                        isHost: false,
                        isConnected: true,
                        isSelf: false
                    )
                }
                
                // Empty slots
                ForEach(0..<groupManager.availableSlots, id: \.self) { _ in
                    riderCard(
                        name: "Empty Slot",
                        isHost: false,
                        isConnected: false,
                        isSelf: false
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func riderCard(name: String, isHost: Bool, isConnected: Bool, isSelf: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isConnected ? .green : .gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isHost ? "crown.fill" : "person.fill")
                    .foregroundColor(isConnected ? .white : .gray)
                    .font(.system(size: 16))
            }
            
            Text(name)
                .font(.caption)
                .foregroundColor(isConnected ? .white : .gray)
                .lineLimit(1)
            
            if isHost {
                Text("Host")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .opacity(isConnected ? 1.0 : 0.6)
    }
    
    // MARK: - DJ Controls Section
    private var djControlsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("DJ Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // DJ Status
                HStack(spacing: 6) {
                    Circle()
                        .fill(hostDJ.isActiveHost ? .green : .gray)
                        .frame(width: 8, height: 8)
                    
                    Text(hostDJ.isActiveHost ? "Active DJ" : "No DJ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if groupManager.isHost {
                // Host DJ Controls
                VStack(spacing: 12) {
                    if !hostDJ.isActiveHost {
                        Button(action: {
                            hostDJ.activateHost()
                        }) {
                            HStack {
                                Image(systemName: "music.note.house.fill")
                                Text("Become DJ")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        // Quick DJ controls
                        HStack(spacing: 16) {
                            Button(action: {
                                hostDJ.togglePlayback()
                            }) {
                                Image(systemName: hostDJ.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                hostDJ.skipTrack()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Pending requests indicator
                            if songRequests.pendingCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "music.note.list")
                                        .font(.caption)
                                    
                                    Text("\(songRequests.pendingCount)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.red, in: Circle())
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                // Rider controls
                VStack(spacing: 12) {
                    if musicSync.currentTrack != nil {
                        Text("🎵 Now Playing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No music playing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        showingSongRequest = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Request Song")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Voice Chat Section
    private var voiceChatSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Voice Chat")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Audio level indicator
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Rectangle()
                            .fill(audioLevelColor(for: index))
                            .frame(width: 3, height: CGFloat(8 + index * 2))
                            .cornerRadius(1.5)
                    }
                }
            }
            
            HStack(spacing: 20) {
                // Mute/Unmute Button
                Button(action: {
                    voiceService.toggleMute()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: voiceService.isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(voiceService.isMuted ? .red : .green)
                        
                        Text(voiceService.isMuted ? "Muted" : "Unmuted")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 80, height: 60)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Audio Control Button
                Button(action: {
                    showingAudioControl = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        Text("Audio")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 80, height: 60)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                Spacer()
                
                // Voice Chat Status
                VStack(alignment: .trailing, spacing: 4) {
                    Text(voiceService.isVoiceChatActive ? "Voice Active" : "Voice Inactive")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(voiceService.isVoiceChatActive ? .green : .gray)
                    
                    Text("Quality: \(voiceService.connectionQuality.description)")
                        .font(.caption)
                        .foregroundColor(voiceService.connectionQuality.color)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Start Voice Chat Button
            Button(action: {
                if voiceService.isVoiceChatActive {
                    voiceService.stopVoiceChat()
                } else {
                    voiceService.startVoiceChat()
                }
            }) {
                HStack {
                    Image(systemName: voiceService.isVoiceChatActive ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 20))
                    
                    Text(voiceService.isVoiceChatActive ? "Stop Voice Chat" : "Start Voice Chat")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(voiceService.isVoiceChatActive ? .red : .blue)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupServices() {
        // Setup music sync service
        musicSync.setGroupSessionManager(groupManager)
        
        // Setup song request manager
        songRequests.setGroupSessionManager(groupManager)
        
        // Setup HUD manager
        hudManager.setGroupManager(groupManager)
        hudManager.setGestureService(gestureService)
        
        // Setup gesture service
        gestureService.start()
        
        // Setup remote commands
        remoteCommands.setupAudioSession()
        remoteCommands.registerCommands()
        remoteCommands.setHUDManager(hudManager)
        
        // Listen for data received notifications
        NotificationCenter.default.addObserver(
            forName: .groupSessionDataReceived,
            object: nil,
            queue: .main
        ) { notification in
            if let data = notification.userInfo?["data"] as? Data {
                handleReceivedData(data)
            }
        }
        
        print("Branchr: All DJ services initialized and connected")
    }
    
    private func handleReceivedData(_ data: Data) {
        // Handle different types of data received from peers
        // This would need to be implemented based on your data protocol
        print("Branchr: Received data from peer")
    }
    
    private func leaveGroupRide() {
        // Stop gesture detection
        gestureService.stop()
        
        // Unregister remote commands
        remoteCommands.unregisterCommands()
        
        // Hide HUD
        hudManager.hideHUD()
        
        // Leave group session
        groupManager.leaveGroupSession()
        
        // Stop voice chat
        voiceService.stopVoiceChat()
        
        // Dismiss view
        dismiss()
        
        print("Branchr: Group ride left, all services cleaned up")
    }
    
    private func audioLevelColor(for index: Int) -> Color {
        let threshold = Float(index) / 5.0
        return voiceService.audioLevel > threshold ? .green : .gray.opacity(0.3)
    }
}

// MARK: - Preview
#Preview {
    GroupRideView()
}
