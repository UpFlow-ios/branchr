//
//  AudioManager.swift
//  branchr
//
//  Created by Joe Dormond on 10/26/25.
//  Phase 18.3 - DJ Audio Mixing & Playback Integration
//

import Foundation
import AVFoundation
import Combine

final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var musicPlayer: AVAudioPlayer?
    private var voiceInputActive = false
    
    @Published var isMusicPlaying: Bool = false
    @Published var currentSong: String = "No song playing"
    
    private init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        // Use centralized AudioSessionManager for high-fidelity music + voice chat
        // This preserves full-range audio (including bass) while allowing mic input
        AudioSessionManager.shared.configureForRideMusicAndVoiceChat()
    }
    
    func playMusic(named fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("⚠️ AudioManager: Song not found: \(fileName).mp3")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.volume = 1.0
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
            
            isMusicPlaying = true
            currentSong = fileName
            print("🎵 AudioManager: Playing \(fileName)")
        } catch {
            print("❌ AudioManager: Error playing music: \(error.localizedDescription)")
        }
    }
    
    func stopMusic() {
        musicPlayer?.stop()
        isMusicPlaying = false
        currentSong = "No song playing"
        print("⏹ AudioManager: Music stopped")
    }
    
    func fadeMusic(forVoice active: Bool) {
        guard let player = musicPlayer else { return }
        
        if active {
            player.setVolume(0.3, fadeDuration: 0.5)
            print("🔉 AudioManager: Music faded to 30% for voice")
        } else {
            player.setVolume(1.0, fadeDuration: 0.5)
            print("🔊 AudioManager: Music restored to 100%")
        }
    }
    
    func toggleVoiceChat(active: Bool) {
        voiceInputActive = active
        fadeMusic(forVoice: active)
        print("🎙 AudioManager: Voice chat \(active ? "active" : "inactive")")
    }
    
    func toggleVoiceActivity(active: Bool) {
        // Alias for toggleVoiceChat - used by VoiceActivationService
        toggleVoiceChat(active: active)
    }
    
    func lowerMusicVolumeTemporarily() {
        musicPlayer?.setVolume(0.2, fadeDuration: 0.5)
        print("🔉 AudioManager: Music lowered temporarily to 20%")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.musicPlayer?.setVolume(1.0, fadeDuration: 0.5)
            print("🔊 AudioManager: Music restored to 100% after voice")
        }
    }
}
