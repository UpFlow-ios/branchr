//
//  DJControlView.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import SwiftUI

/// Host-only control panel for managing DJ functionality and song requests
struct DJControlView: View {
    @ObservedObject var dj: HostDJController
    @ObservedObject var musicSync: MusicSyncService
    @ObservedObject var songRequests: SongRequestManager
    
    @State private var showingRequestDetails = false
    @State private var selectedRequest: SongRequest?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Now Playing Card
                nowPlayingCard
                
                // Transport Controls
                transportControls
                
                // Song Requests Section
                songRequestsSection
                
                // Host Actions
                hostActionsSection
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showingRequestDetails) {
            if let request = selectedRequest {
                RequestDetailSheet(request: request, dj: dj)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "music.note.house.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text("DJ Controls")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Host status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(dj.isActiveHost ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(dj.isActiveHost ? "Active" : "Inactive")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(dj.hostStatusSummary)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Now Playing Card
    private var nowPlayingCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Now Playing")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Playback status
                HStack(spacing: 6) {
                    Image(systemName: musicSync.currentTrack?.isPlaying == true ? "play.circle.fill" : "pause.circle.fill")
                        .foregroundColor(musicSync.currentTrack?.isPlaying == true ? .green : .orange)
                    
                    Text(musicSync.currentTrack?.isPlaying == true ? "Playing" : "Paused")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            if let track = musicSync.currentTrack {
                VStack(spacing: 12) {
                    // Track info
                    VStack(spacing: 4) {
                        Text(track.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(track.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                        
                        if let album = track.album {
                            Text(album)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                    }
                    
                    // Progress bar
                    if let position = track.playbackPosition,
                       let duration = track.trackDuration {
                        VStack(spacing: 4) {
                            ProgressView(value: position, total: duration)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            HStack {
                                Text(formatTime(position))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatTime(duration))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Source app
                    HStack(spacing: 6) {
                        Image(systemName: track.sourceApp.icon)
                            .foregroundColor(.blue)
                        
                        Text(track.sourceApp.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No music playing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Transport Controls
    private var transportControls: some View {
        VStack(spacing: 16) {
            Text("Transport Controls")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // Previous track
                Button(action: {
                    dj.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.blue, in: Circle())
                }
                
                // Play/Pause
                Button(action: {
                    dj.togglePlayback()
                }) {
                    Image(systemName: dj.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(dj.isPlaying ? Color.orange : Color.green, in: Circle())
                }
                
                // Next track
                Button(action: {
                    dj.skipTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.blue, in: Circle())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Song Requests Section
    private var songRequestsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Song Requests")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Request count badge
                if songRequests.pendingCount > 0 {
                    Text("\(songRequests.pendingCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.red, in: Circle())
                }
            }
            
            if songRequests.pendingRequests.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No pending requests")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(songRequests.pendingRequests) { request in
                        RequestRowView(
                            request: request,
                            onApprove: { 
                                Task {
                                    await dj.approveRequest(request)
                                }
                            },
                            onReject: { 
                                Task {
                                    await dj.rejectRequest(request)
                                }
                            },
                            onTap: {
                                selectedRequest = request
                                showingRequestDetails = true
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Host Actions Section
    private var hostActionsSection: some View {
        VStack(spacing: 12) {
            if dj.isActiveHost {
                Button(action: {
                    dj.deactivateHost()
                }) {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("Stop Being DJ")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button(action: {
                    dj.activateHost()
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Become DJ")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Clear requests button
            if !songRequests.pendingRequests.isEmpty {
                Button(action: {
                    songRequests.clearAllPendingRequests()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Requests")
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Individual request row view
struct RequestRowView: View {
    let request: SongRequest
    let onApprove: () -> Void
    let onReject: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Request info
            VStack(alignment: .leading, spacing: 4) {
                Text(request.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(request.artist ?? "Unknown Artist")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(request.requestedBy)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: onReject) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                
                Button(action: onApprove) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap()
        }
    }
}

/// Request detail sheet
struct RequestDetailSheet: View {
    let request: SongRequest
    let dj: HostDJController
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Request details
                VStack(spacing: 16) {
                    Text("🎵 \(request.title)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    if let artist = request.artist {
                        Text("by \(artist)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Requested by \(request.requestedBy)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Requested \(request.timestamp, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await dj.approveRequest(request)
                        }
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Approve Request")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: {
                        Task {
                            await dj.rejectRequest(request)
                        }
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Reject Request")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Song Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DJControlView(
        dj: HostDJController(
            musicSync: MusicSyncService(),
            songRequests: SongRequestManager()
        ),
        musicSync: MusicSyncService(),
        songRequests: SongRequestManager()
    )
    .padding()
}
