//
//  CommandProcessor.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//

import Foundation
import AVFoundation

/// Processes voice commands and returns appropriate responses
final class CommandProcessor: ObservableObject {
    
    static let shared = CommandProcessor()
    
    // MARK: - Song Requests
    private weak var songRequestManager: SongRequestManager?
    private weak var musicSync: MusicSyncService?
    
    // MARK: - Initialization
    private init() {
        print("Branchr: CommandProcessor initialized")
    }
    
    /// Set dependencies
    func setDependencies(songRequestManager: SongRequestManager?, musicSync: MusicSyncService?) {
        self.songRequestManager = songRequestManager
        self.musicSync = musicSync
    }
    
    /// Process a voice command and return a response
    func process(_ text: String) -> String {
        let command = text.lowercased()
        
        // Song request commands
        if command.contains("play") || command.contains("add song") {
            return handleSongRequest(command)
        }
        
        // Ride control commands (handled by existing SpeechCommandService)
        if command.contains("pause") {
            return "Pausing ride"
        }
        
        if command.contains("resume") {
            return "Resuming ride"
        }
        
        if command.contains("stop") {
            return "Stopping ride"
        }
        
        if command.contains("status") {
            return "Checking ride status"
        }
        
        // General responses
        return handleGeneralCommand(command)
    }
    
    // MARK: - Private Methods
    
    private func handleSongRequest(_ text: String) -> String {
        // Extract song name from command
        var songName = text
        
        // Remove trigger words
        songName = songName.replacingOccurrences(of: "play", with: "")
        songName = songName.replacingOccurrences(of: "add song", with: "")
        songName = songName.replacingOccurrences(of: "hey branchr", with: "")
        songName = songName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if songName.isEmpty {
            return "I didn't catch that song. Please try again."
        }
        
        print("Branchr: Song request detected: \(songName)")
        
        // In a real implementation, this would create a song request
        // For now, just confirm
        return "Adding \(songName) to the queue"
    }
    
    private func handleGeneralCommand(_ text: String) -> String {
        if text.contains("hello") || text.contains("hi") {
            return "Hey there! Ready to ride?"
        }
        
        if text.contains("help") {
            return "I can help you request songs, control your ride, and get status updates. Just say Hey Branchr followed by your command."
        }
        
        if text.contains("thanks") || text.contains("thank you") {
            return "You're welcome!"
        }
        
        return "I heard you say: \(text). Try asking for a song or ride control."
    }
}

