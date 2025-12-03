//
//  DJControlSheetView.swift
//  branchr
//
//  Created by Joe Dormond on 10/26/25.
//  Phase 18.4 - Apple Music API Integration
//

import SwiftUI

struct DJControlSheetView: View {
    @ObservedObject private var audioManager = AudioManager.shared
    @ObservedObject private var musicService = MusicService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isDJModeOn: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    Text("🎧 DJ Mode")
                        .font(.title.bold())
                        .foregroundColor(theme.primaryText)
                        .padding(.top, 10)
                    
                    // MARK: - DJ Mode Toggle
                    Toggle("DJ Mode", isOn: $isDJModeOn)
                        .padding(.horizontal)
                        .tint(theme.accentColor)
                    
                    // MARK: - Apple Music Authorization
                    if !musicService.isAuthorized {
                        VStack(spacing: 16) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundColor(theme.accentColor)
                                .padding()
                            
                            Text("Connect Apple Music")
                                .font(.headline)
                                .foregroundColor(theme.primaryText)
                            
                            Text("Access your playlists and stream music during rides")
                                .font(.subheadline)
                                .foregroundColor(theme.primaryText.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                Task { await musicService.requestAuthorization() }
                            }) {
                                Label("Connect Apple Music", systemImage: "music.note.list")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.purple.opacity(0.9))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        // MARK: - Now Playing Section
                        VStack(spacing: 16) {
                            // Album Artwork
                            if let artworkURL = musicService.artworkURL {
                                AsyncImage(url: artworkURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(12)
                                            .shadow(color: theme.accentColor.opacity(0.3), radius: 10)
                                    case .failure:
                                        placeholderArtwork
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 200)
                                    @unknown default:
                                        placeholderArtwork
                                    }
                                }
                                .frame(height: 200)
                            } else {
                                placeholderArtwork
                            }
                            
                            // Song Info
                            VStack(spacing: 8) {
                                Text(musicService.currentSongTitle)
                                    .font(.headline)
                                    .foregroundColor(theme.primaryText)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                
                                Text(musicService.currentArtist)
                                    .font(.subheadline)
                                    .foregroundColor(theme.primaryText.opacity(0.7))
                                    .lineLimit(1)
                                
                                if musicService.isPlaying {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 10, height: 10)
                                        Text("Playing")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // MARK: - Playback Controls
                        VStack(spacing: 16) {
                            // Primary Controls
                            HStack(spacing: 20) {
                                // Previous Button
                                Button(action: {
                                    Task { await musicService.skipToPrevious() }
                                }) {
                                    Image(systemName: "backward.fill")
                                        .font(.title2)
                                        .frame(width: 60, height: 60)
                                        .background(theme.cardBackground)
                                        .foregroundColor(theme.accentColor)
                                        .cornerRadius(12)
                                }
                                
                                       // Play/Pause Button
                                       Button(action: {
                                           if musicService.isPlaying {
                                               musicService.pause()
                                           } else {
                                               // If no song is loaded, play music (hybrid); otherwise resume
                                               if musicService.currentSongTitle == "No song playing" {
                                                   Task { await musicService.playMusic() }
                                               } else {
                                                   Task { await musicService.resume() }
                                               }
                                           }
                                       }) {
                                    Image(systemName: musicService.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.title)
                                        .frame(width: 80, height: 80)
                                        .background(theme.accentColor)
                                        .foregroundColor(theme.isDarkMode ? .black : .white)
                                        .cornerRadius(16)
                                        .shadow(color: theme.accentColor.opacity(0.3), radius: 8)
                                }
                                
                                // Next Button
                                Button(action: {
                                    Task { await musicService.skipToNext() }
                                }) {
                                    Image(systemName: "forward.fill")
                                        .font(.title2)
                                        .frame(width: 60, height: 60)
                                        .background(theme.cardBackground)
                                        .foregroundColor(theme.accentColor)
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Stop Button
                            Button(action: {
                                musicService.stop()
                            }) {
                                Label("Stop", systemImage: "stop.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.9))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Legacy MP3 Playback
                        VStack(spacing: 12) {
                            Text("Local MP3 Playback")
                                .font(.caption)
                                .foregroundColor(theme.primaryText.opacity(0.5))
                            
                            Button(action: {
                                audioManager.playMusic(named: "ride_track")
                            }) {
                                Label("Play Local MP3", systemImage: "music.note")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(theme.cardBackground)
                                    .foregroundColor(theme.primaryText)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Voice Control
                    Button(action: {
                        audioManager.lowerMusicVolumeTemporarily()
                    }) {
                        Label("Test Voice Fade (Lower Volume)", systemImage: "mic.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .background(theme.primaryBackground.ignoresSafeArea())
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
        .presentationDetents([.medium, .large])
        .onAppear {
            // Check authorization status when sheet appears
            Task {
                await musicService.checkAuthorizationStatus()
            }
        }
    }
    
    // MARK: - Placeholder Artwork
    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
            
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(theme.accentColor.opacity(0.5))
        }
        .frame(height: 200)
    }
}

#Preview {
    DJControlSheetView()
}
