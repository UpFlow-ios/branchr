//
//  AudioSessionManager.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-01-XX
//  Centralized audio session configuration for high-fidelity music + voice chat
//

import Foundation
import AVFoundation

/// Centralized audio session manager that preserves full-range music quality
/// while allowing simultaneous microphone input for voice chat.
///
/// Key design decision: Uses `.default` mode instead of `.voiceChat` to avoid
/// system voice processing that destroys bass and makes music sound thin.
final class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private let session = AVAudioSession.sharedInstance()
    
    private init() {
        print("🎵 Branchr AudioSessionManager: Initialized")
    }
    
    /// Configure audio session for high-fidelity music playback + voice chat
    /// This preserves full-range audio (including bass) while allowing mic input
    func configureForRideMusicAndVoiceChat() {
        do {
            // Deactivate any existing session to avoid conflicts
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            
            // High-fidelity, full-range audio with mic input
            // IMPORTANT: Using .default mode (not .voiceChat/.videoChat/.spokenAudio)
            // to preserve full-range music quality including bass
            try session.setCategory(
                .playAndRecord,
                mode: .default, // No voice processing - preserves music quality
                options: [
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .defaultToSpeaker,
                    .mixWithOthers // Allows music apps to continue playing
                ]
            )
            
            // High-quality audio settings
            try session.setPreferredSampleRate(48000) // 48kHz for high fidelity
            try session.setPreferredIOBufferDuration(0.005) // 5ms for low latency
            
            // Activate the session
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
            
            print("🎵 Branchr AudioSessionManager: Configured for music + voice chat (full range, no voice processing)")
            print("🎵 Branchr AudioSessionManager: Category: \(session.category.rawValue), Mode: \(session.mode.rawValue)")
            print("🎵 Branchr AudioSessionManager: Sample Rate: \(session.sampleRate) Hz, IO Buffer: \(session.ioBufferDuration)s")
            
        } catch {
            print("❌ Branchr AudioSessionManager: Failed to configure session: \(error.localizedDescription)")
            print("❌ Branchr AudioSessionManager: Error code: \((error as NSError).code), domain: \((error as NSError).domain)")
            
            // Fallback: minimal configuration
            do {
                try session.setCategory(.playAndRecord, options: [.mixWithOthers])
                try session.setActive(true)
                print("⚠️ Branchr AudioSessionManager: Activated with minimal configuration (fallback)")
            } catch {
                print("❌ Branchr AudioSessionManager: Complete audio session setup failed: \(error)")
            }
        }
    }
    
    /// Configure audio session for music-only playback (no mic)
    func configureForMusicOnly() {
        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: [
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .mixWithOthers
                ]
            )
            try session.setActive(true)
            print("🎵 Branchr AudioSessionManager: Configured for music-only playback")
        } catch {
            print("❌ Branchr AudioSessionManager: Failed to configure for music-only: \(error)")
        }
    }
    
    /// Deactivate audio session
    func deactivate() {
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
            print("🎵 Branchr AudioSessionManager: Audio session deactivated")
        } catch {
            print("❌ Branchr AudioSessionManager: Failed to deactivate session: \(error)")
        }
    }
}

