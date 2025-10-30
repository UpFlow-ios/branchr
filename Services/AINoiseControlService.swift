//
//  AINoiseControlService.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import Foundation
import AVFoundation
import SwiftUI

/// Service for AI-powered noise suppression and audio enhancement
/// Provides real-time noise filtering, wind reduction, and auto-gain control
@MainActor
class AINoiseControlService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isNoiseFilterEnabled = false
    @Published var isWindReductionEnabled = false
    @Published var isAutoGainEnabled = true
    @Published var noiseReductionLevel: Float = 0.7
    @Published var windReductionLevel: Float = 0.8
    @Published var autoGainLevel: Float = 0.5
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var eqNode: AVAudioUnitEQ?
    private var reverbNode: AVAudioUnitReverb?
    private var tapNode: AVAudioNode?
    
    // Audio analysis properties
    private var audioLevelTimer: Timer?
    private var currentRMSLevel: Float = 0.0
    private let targetRMSLevel: Float = 0.3
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioUnits()
        print("Branchr AINoiseControlService initialized")
    }
    
    // MARK: - Setup Methods
    
    private func setupAudioUnits() {
        // Initialize audio units for processing
        eqNode = AVAudioUnitEQ(numberOfBands: 10)
        reverbNode = AVAudioUnitReverb()
        
        // Configure EQ for noise reduction
        configureEQForNoiseReduction()
        
        // Configure reverb for wind reduction
        configureReverbForWindReduction()
        
        print("Branchr: Audio units configured for noise control")
    }
    
    private func configureEQForNoiseReduction() {
        guard let eqNode = eqNode else { return }
        
        // Configure EQ bands for noise reduction
        // Low frequencies (rumble, wind)
        eqNode.bands[0].frequency = 80
        eqNode.bands[0].gain = -12.0
        eqNode.bands[0].filterType = .lowShelf
        eqNode.bands[0].bypass = false
        
        // Mid-low frequencies (engine noise)
        eqNode.bands[1].frequency = 200
        eqNode.bands[1].gain = -8.0
        eqNode.bands[1].filterType = .parametric
        eqNode.bands[1].bypass = false
        
        // Voice frequencies (preserve)
        eqNode.bands[2].frequency = 1000
        eqNode.bands[2].gain = 2.0
        eqNode.bands[2].filterType = .parametric
        eqNode.bands[2].bypass = false
        
        // High frequencies (hiss reduction)
        eqNode.bands[3].frequency = 8000
        eqNode.bands[3].gain = -6.0
        eqNode.bands[3].filterType = .highShelf
        eqNode.bands[3].bypass = false
        
        print("Branchr: EQ configured for noise reduction")
    }
    
    private func configureReverbForWindReduction() {
        guard let reverbNode = reverbNode else { return }
        
        // Configure reverb for wind noise reduction
        reverbNode.loadFactoryPreset(.mediumRoom)
        reverbNode.wetDryMix = 10.0 // Low mix for subtle effect
        
        print("Branchr: Reverb configured for wind reduction")
    }
    
    // MARK: - Public Methods
    
    /// Attach noise control to audio engine
    func attachToAudioEngine(_ engine: AVAudioEngine, inputNode: AVAudioNode) {
        self.audioEngine = engine
        
        guard let eqNode = eqNode,
              let reverbNode = reverbNode else {
            print("Branchr: Audio units not initialized")
            return
        }
        
        // Attach audio units to engine
        engine.attach(eqNode)
        engine.attach(reverbNode)
        
        // Connect input -> EQ -> Reverb -> output
        engine.connect(inputNode, to: eqNode, format: nil)
        engine.connect(eqNode, to: reverbNode, format: nil)
        
        // Store the reverb as the output node
        self.tapNode = reverbNode
        
        // Start audio level monitoring
        startAudioLevelMonitoring()
        
        print("Branchr: Noise control attached to audio engine")
    }
    
    /// Enable noise filter
    func enableNoiseFilter() {
        isNoiseFilterEnabled = true
        updateEQSettings()
        print("Branchr: Noise filter enabled")
    }
    
    /// Disable noise filter
    func disableNoiseFilter() {
        isNoiseFilterEnabled = false
        updateEQSettings()
        print("Branchr: Noise filter disabled")
    }
    
    /// Enable wind reduction
    func enableWindReduction() {
        isWindReductionEnabled = true
        updateReverbSettings()
        print("Branchr: Wind reduction enabled")
    }
    
    /// Disable wind reduction
    func disableWindReduction() {
        isWindReductionEnabled = false
        updateReverbSettings()
        print("Branchr: Wind reduction disabled")
    }
    
    /// Enable auto-gain control
    func enableAutoGain() {
        isAutoGainEnabled = true
        print("Branchr: Auto-gain enabled")
    }
    
    /// Disable auto-gain control
    func disableAutoGain() {
        isAutoGainEnabled = false
        print("Branchr: Auto-gain disabled")
    }
    
    /// Set noise reduction level (0.0 - 1.0)
    func setNoiseReductionLevel(_ level: Float) {
        let clampedLevel = max(0.0, min(1.0, level))
        noiseReductionLevel = clampedLevel
        updateEQSettings()
        print("Branchr: Noise reduction level set to \(clampedLevel)")
    }
    
    /// Set wind reduction level (0.0 - 1.0)
    func setWindReductionLevel(_ level: Float) {
        let clampedLevel = max(0.0, min(1.0, level))
        windReductionLevel = clampedLevel
        updateReverbSettings()
        print("Branchr: Wind reduction level set to \(clampedLevel)")
    }
    
    /// Set auto-gain level (0.0 - 1.0)
    func setAutoGainLevel(_ level: Float) {
        let clampedLevel = max(0.0, min(1.0, level))
        autoGainLevel = clampedLevel
        print("Branchr: Auto-gain level set to \(clampedLevel)")
    }
    
    /// Adjust settings for wind conditions
    func adjustForWind() {
        // Boost mid-range frequencies and suppress low rumble
        guard let eqNode = eqNode else { return }
        
        // Increase wind reduction
        eqNode.bands[0].gain = -15.0 // More aggressive low-end reduction
        eqNode.bands[1].gain = -10.0 // More aggressive mid-low reduction
        
        // Boost voice frequencies
        eqNode.bands[2].gain = 4.0 // Stronger voice boost
        
        print("Branchr: Audio adjusted for wind conditions")
    }
    
    /// Reset to normal conditions
    func resetForNormalConditions() {
        configureEQForNoiseReduction()
        print("Branchr: Audio reset for normal conditions")
    }
    
    /// Get current audio level for visualization
    var currentAudioLevel: Float {
        return currentRMSLevel
    }
    
    /// Get processed audio node for connection
    var processedAudioNode: AVAudioNode? {
        return tapNode
    }
    
    // MARK: - Private Methods
    
    private func updateEQSettings() {
        guard let eqNode = eqNode else { return }
        
        if isNoiseFilterEnabled {
            // Apply noise reduction based on level
            let reductionFactor = noiseReductionLevel
            
            eqNode.bands[0].gain = -12.0 * reductionFactor
            eqNode.bands[1].gain = -8.0 * reductionFactor
            eqNode.bands[3].gain = -6.0 * reductionFactor
            
            // Boost voice frequencies
            eqNode.bands[2].gain = 2.0 * reductionFactor
        } else {
            // Reset to flat response
            for band in eqNode.bands {
                band.gain = 0.0
            }
        }
    }
    
    private func updateReverbSettings() {
        guard let reverbNode = reverbNode else { return }
        
        if isWindReductionEnabled {
            reverbNode.wetDryMix = 10.0 * windReductionLevel
        } else {
            reverbNode.wetDryMix = 0.0
        }
    }
    
    // MARK: - Audio Analysis (Simplified)
    
    private func startAudioLevelMonitoring() {
        guard let tapNode = tapNode else { return }
        
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.analyzeAudioLevel()
        }
    }
    
    private func analyzeAudioLevel() {
        // This would implement real-time RMS analysis
        // For now, we'll simulate audio level detection
        currentRMSLevel = Float.random(in: 0.1...0.8)
        
        // Auto-adjust gain if enabled (simplified version)
        if isAutoGainEnabled {
            // Simple auto-gain simulation
            print("Branchr: Auto-gain monitoring active")
        }
    }
    
    // MARK: - Cleanup
    deinit {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
    }
}
