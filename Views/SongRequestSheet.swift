//
//  SongRequestSheet.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import SwiftUI

/// Sheet for riders to request songs from the host DJ
struct SongRequestSheet: View {
    @ObservedObject var songRequests: SongRequestManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var songTitle = ""
    @State private var artistName = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Request a Song")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Ask the DJ to play your favorite track")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Form
                VStack(spacing: 16) {
                    // Song Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Song Title")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter song title", text: $songTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    // Artist Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Artist (Optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter artist name", text: $artistName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                }
                .padding(.horizontal)
                
                // Recent Requests
                if !songRequests.requestHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Requests")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(songRequests.getRecentRequests(limit: 5)) { request in
                                    RecentRequestRow(request: request)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Submit Button
                Button(action: submitRequest) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        
                        Text(isSubmitting ? "Sending..." : "Send Request")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSubmit || isSubmitting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Song Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Request Sent!", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your song request has been sent to the DJ.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSubmit: Bool {
        return !songTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    private func submitRequest() {
        guard canSubmit else { return }
        
        isSubmitting = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                // Send the request
                await songRequests.sendRequest(
                    title: songTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    artist: artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : artistName.trimmingCharacters(in: .whitespacesAndNewlines),
                    requestedBy: "You" // In a real app, this would be the user's display name
                )
                
                isSubmitting = false
                showingSuccess = true
                
                // Clear form
                songTitle = ""
                artistName = ""
            }
        }
    }
}

/// Row view for recent requests
struct RecentRequestRow: View {
    let request: SongRequest
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)
            
            // Request info
            VStack(alignment: .leading, spacing: 2) {
                Text(request.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let artist = request.artist {
                        Text(artist)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(request.requestedBy)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Timestamp
            Text(request.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch request.status {
        case .pending: return "clock"
        case .approved: return "checkmark.circle"
        case .rejected: return "xmark.circle"
        case .played: return "music.note"
        }
    }
    
    private var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .played: return .blue
        }
    }
}

#Preview {
    SongRequestSheet(songRequests: SongRequestManager())
}
