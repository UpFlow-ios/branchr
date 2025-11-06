//
//  VoiceChatService.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import AVFoundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Service for managing real-time voice chat using AVAudioEngine
/// Handles audio input/output, mute functionality, and low-latency voice streaming
@MainActor
class VoiceChatService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isVoiceChatActive = false
    @Published var isMuted = false
    @Published var audioLevel: Float = 0.0
    @Published var connectionQuality: ConnectionQuality = .excellent
    @Published var speakingPeers: [String: Bool] = [:] // peerID : isSpeaking
    @Published var mutedPeers: [String: Bool] = [:] // peerID : isMuted
#if canImport(UIKit)
    @Published var microphonePermissionStatus: AVAudioSession.RecordPermission = .undetermined
#else
    @Published var microphonePermissionStatus: Int = 0 // Placeholder for macOS
#endif
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private var outputNode: AVAudioOutputNode
    private var mixerNode: AVAudioMixerNode
#if canImport(UIKit)
    private var audioSession: AVAudioSession
#else
    private var audioSession: Any? = nil // Placeholder for macOS
#endif
    
    // MARK: - Connection Quality Enum
    enum ConnectionQuality {
        case excellent
        case good
        case fair
        case poor
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .yellow
            case .fair: return .orange
            case .poor: return .red
            }
        }
        
        var description: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        self.audioEngine = AVAudioEngine()
        self.inputNode = audioEngine.inputNode
        self.outputNode = audioEngine.outputNode
        self.mixerNode = AVAudioMixerNode()
#if canImport(UIKit)
        self.audioSession = AVAudioSession.sharedInstance()
#else
        self.audioSession = nil
#endif
        
        super.init()
        
#if canImport(UIKit)
        // Check current microphone permission status
        microphonePermissionStatus = audioSession.recordPermission
        
        // Only setup audio if we have permission
        if microphonePermissionStatus == .granted {
            setupAudioSession()
            setupAudioEngine()
        }
#endif
        
        print("Branchr VoiceChatService initialized - Microphone permission: \(microphonePermissionStatus)")
        print("Branchr VoiceChatService: Audio engine created successfully")
    }
    
    // MARK: - Permission Management
    
    /// Request microphone permission from the user
    func requestMicrophonePermission() {
#if canImport(UIKit)
        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.microphonePermissionStatus = granted ? .granted : .denied
                
                if granted {
                    self?.setupAudioSession()
                    self?.setupAudioEngine()
                    print("Branchr: Microphone permission granted")
                } else {
                    print("Branchr: Microphone permission denied")
                }
            }
        }
#endif
    }
    
    /// Check if microphone permission is granted
    var hasMicrophonePermission: Bool {
#if canImport(UIKit)
        return microphonePermissionStatus == .granted
#else
        return false
#endif
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
#if canImport(UIKit)
        do {
            // First, deactivate any existing session to avoid conflicts
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            // Configure audio session for voice chat
            try audioSession.setCategory(.playAndRecord, 
                                      mode: .voiceChat, 
                                      options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
            
            // Set preferred buffer duration for low latency
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer
            
            // Set preferred sample rate for compatibility
            try audioSession.setPreferredSampleRate(44100.0)
            
            // Enable audio session with options
            try audioSession.setActive(true, options: [])
            
            print("Branchr: Audio session configured for voice chat")
            print("Branchr: Audio session is now active: \(audioSession.isOtherAudioPlaying)")
        } catch {
            print("Branchr: Failed to configure audio session: \(error)")
            
            // Try to activate with minimal configuration as fallback
            do {
                try audioSession.setCategory(.playAndRecord)
                try audioSession.setActive(true)
                print("Branchr: Audio session activated with minimal configuration")
            } catch {
                print("Branchr: Complete audio session setup failed: \(error)")
            }
        }
#endif
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() {
        // Ensure audio session is active before proceeding
#if canImport(UIKit)
        do {
            try audioSession.setActive(true)
        } catch {
            print("Branchr: Cannot setup audio engine - audio session not active: \(error)")
            return
        }
#endif
        
        // Attach mixer node to audio engine
        audioEngine.attach(mixerNode)
        
        // Wait a moment for the audio engine to be ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            // Get the actual hardware format
            let inputFormat = self.inputNode.outputFormat(forBus: 0)
            let hardwareFormat = self.inputNode.inputFormat(forBus: 0)
            
            print("Branchr: Hardware input format: \(hardwareFormat.sampleRate) Hz, \(hardwareFormat.channelCount) channels")
            print("Branchr: Input node output format: \(inputFormat.sampleRate) Hz, \(inputFormat.channelCount) channels")
            
            // Validate the format before using it
            guard self.isValidFormat(hardwareFormat) else {
                print("Branchr: Invalid hardware format, using fallback")
                self.setupAudioEngineWithFallback()
                return
            }
            
            do {
                // Connect input to mixer with hardware format
                self.audioEngine.connect(self.inputNode, to: self.mixerNode, format: hardwareFormat)
                
                // Connect mixer to output with hardware format
                self.audioEngine.connect(self.mixerNode, to: self.outputNode, format: hardwareFormat)
                
                // Install tap on input node for audio level monitoring
                self.installAudioLevelTap()
                
                print("Branchr: Audio engine configured with hardware format")
            } catch {
                print("Branchr: Failed to setup audio engine: \(error)")
                // Try fallback if hardware format fails
                self.setupAudioEngineWithFallback()
            }
        }
    }
    
    // MARK: - Fallback Audio Engine Setup
    private func setupAudioEngineWithFallback() {
        print("Branchr: Using fallback audio format")
        
        // Use a standard format as fallback
        let fallbackFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                                          sampleRate: 44100.0, 
                                          channels: 2, 
                                          interleaved: false)!
        
        do {
            // Connect input to mixer with fallback format
            audioEngine.connect(inputNode, to: mixerNode, format: fallbackFormat)
            
            // Connect mixer to output with fallback format
            audioEngine.connect(mixerNode, to: outputNode, format: fallbackFormat)
            
            // Install tap on input node
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: fallbackFormat) { [weak self] buffer, _ in
                DispatchQueue.main.async {
                    self?.updateAudioLevel(from: buffer)
                }
            }
            
            print("Branchr: Audio engine configured with fallback format")
        } catch {
            print("Branchr: Failed to setup audio engine with fallback: \(error)")
        }
    }
    
    // MARK: - Format Validation
    private func isValidFormat(_ format: AVAudioFormat) -> Bool {
        return format.sampleRate > 0 && format.channelCount > 0
    }
    
    // MARK: - Audio Level Monitoring
    private func installAudioLevelTap() {
        // Use the same hardware format as the audio engine connections
        let hardwareFormat = inputNode.inputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { [weak self] buffer, _ in
            DispatchQueue.main.async {
                self?.updateAudioLevel(from: buffer)
            }
        }
    }
    
    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        var sum: Float = 0.0
        
        // Calculate RMS (Root Mean Square) for audio level
        for i in 0..<frameCount {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameCount))
        audioLevel = min(rms * 10, 1.0) // Scale and clamp to 0-1 range
        
        // Update connection quality based on audio level
        updateConnectionQuality()
    }
    
    private func updateConnectionQuality() {
        if audioLevel > 0.7 {
            connectionQuality = .excellent
        } else if audioLevel > 0.4 {
            connectionQuality = .good
        } else if audioLevel > 0.1 {
            connectionQuality = .fair
        } else {
            connectionQuality = .poor
        }
    }
    
    // MARK: - Public Methods
    
    // Phase 29C: Haptic feedback generator
    private var hapticGenerator = UINotificationFeedbackGenerator()
    
    /// Start voice chat
    func startVoiceChat() {
        guard !isVoiceChatActive else { return }
        
        // Check microphone permission first
        guard hasMicrophonePermission else {
            print("Branchr: Cannot start voice chat - microphone permission not granted")
            return
        }
        
        do {
            // Start audio engine
            try audioEngine.start()
            isVoiceChatActive = true
            
            // Phase 29C: Haptic feedback on start
            hapticGenerator.notificationOccurred(.success)
            
            print("🎤 Starting voice chat...")
            print("Branchr: Voice chat started successfully")
        } catch {
            print("Branchr: Failed to start voice chat: \(error)")
            isVoiceChatActive = false
        }
    }
    
    /// Stop voice chat
    func stopVoiceChat() {
        guard isVoiceChatActive else { return }
        
        audioEngine.stop()
        isVoiceChatActive = false
        audioLevel = 0.0
        
        // Phase 29C: Haptic feedback on stop
        hapticGenerator.notificationOccurred(.warning)
        
        print("🛑 Stopping voice chat...")
        print("Branchr: Voice chat stopped")
    }
    
    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
        
        if isMuted {
            muteMicrophone()
        } else {
            unmuteMicrophone()
        }
        
        print("Branchr: Microphone \(isMuted ? "muted" : "unmuted")")
    }
    
    // MARK: - Per-User Mute & Speaking Detection (Phase 20)
    
    /// Toggle mute for a specific peer
    func toggleUserMute(peerID: String) {
        mutedPeers[peerID] = !(mutedPeers[peerID] ?? false)
        print("Branchr: User \(peerID) \(mutedPeers[peerID] ?? false ? "muted" : "unmuted")")
    }
    
    /// Check if a specific peer is muted
    func isUserMuted(peerID: String) -> Bool {
        return mutedPeers[peerID] ?? false
    }
    
    /// Check if a specific peer is currently speaking
    func isSpeaking(peerID: String) -> Bool {
        return speakingPeers[peerID] ?? false
    }
    
    /// Start monitoring audio levels for speaking detection
    func startMonitoringAudioLevels(for peers: [String]) {
        // Initialize speaking state for all peers
        for peer in peers {
            if speakingPeers[peer] == nil {
                speakingPeers[peer] = false
            }
        }
        
        // Monitor audio levels every 200ms
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self, self.isVoiceChatActive else {
                timer.invalidate()
                return
            }
            
            // Update speaking state for self
            let selfIsSpeaking = self.audioLevel > 0.3
            let selfID = UIDevice.current.name
            self.speakingPeers[selfID] = selfIsSpeaking
            
            // For other peers, simulate based on audio level threshold
            // TODO: Replace with actual peer audio level data from Bluetooth
            for peer in peers {
                if peer != selfID {
                    // Simulate speaking detection (replace with real data)
                    let simulatedLevel = Float.random(in: 0...1)
                    self.speakingPeers[peer] = simulatedLevel > 0.4 && !self.isUserMuted(peerID: peer)
                }
            }
        }
    }
    
    /// Stop monitoring audio levels
    func stopMonitoringAudioLevels() {
        speakingPeers.removeAll()
    }
    
    /// Mute the microphone
    func muteMicrophone() {
        isMuted = true
        // In a real implementation, you would stop sending audio data here
        // For now, we'll just update the UI state
    }
    
    /// Unmute the microphone
    func unmuteMicrophone() {
        isMuted = false
        // In a real implementation, you would resume sending audio data here
        // For now, we'll just update the UI state
    }
    
    /// Set microphone mute state
    func setMute(_ muted: Bool) {
        if muted != isMuted {
            toggleMute()
        }
    }
    
    /// Check if voice chat is ready
    var isReady: Bool {
        return audioEngine.isRunning && !isMuted
    }
    
    /// Get current audio level as percentage
    var audioLevelPercentage: Int {
        return Int(audioLevel * 100)
    }
    
    // MARK: - Cleanup
    deinit {
        // Note: deinit cannot be @MainActor, so we handle cleanup differently
        audioEngine.stop()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print("Branchr: Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - Audio Session Interruption Handling
extension VoiceChatService {
    
    /// Handle audio session interruptions
    func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio session was interrupted (e.g., phone call)
            DispatchQueue.main.async {
                self.stopVoiceChat()
            }
            print("Branchr: Audio session interrupted")
            
        case .ended:
            // Audio session interruption ended
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    DispatchQueue.main.async {
                        self.setupAudioSession()
                    }
                    print("Branchr: Audio session interruption ended, resuming...")
                }
            }
            
        @unknown default:
            print("Branchr: Unknown audio session interruption type")
        }
    }
    
    /// Handle audio session route changes
    func handleAudioSessionRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            // Audio device changed (e.g., headphones connected/disconnected)
            DispatchQueue.main.async {
                self.setupAudioSession()
            }
            print("Branchr: Audio route changed, reconfiguring...")
            
        default:
            break
        }
    }
}
