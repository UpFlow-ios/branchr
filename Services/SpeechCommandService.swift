//
//  SpeechCommandService.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import Foundation
import Speech
import SwiftUI

/// Service for recognizing voice commands during rides
/// Uses Speech Framework to listen for simple ride commands
@MainActor
class SpeechCommandService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var detectedCommand: RideVoiceCommand?
    @Published var isListening = false
    @Published var hasPermission = false
    @Published var isEnabled = false
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Voice Commands Enum
    enum RideVoiceCommand: String, CaseIterable {
        case pause = "pause tracking"
        case resume = "resume ride"
        case stop = "stop ride"
        case status = "status update"
        
        var displayName: String {
            switch self {
            case .pause: return "Pause Tracking"
            case .resume: return "Resume Ride"
            case .stop: return "Stop Ride"
            case .status: return "Status Update"
            }
        }
        
        var keywords: [String] {
            switch self {
            case .pause: return ["pause", "pause tracking", "stop tracking"]
            case .resume: return ["resume", "resume ride", "continue", "start tracking"]
            case .stop: return ["stop", "stop ride", "end ride", "finish ride"]
            case .status: return ["status", "status update", "how am i doing", "distance"]
            }
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        // Don't request permission immediately - wait until user actually wants to use voice features
        print("Branchr SpeechCommandService initialized - permission will be requested when needed")
    }
    
    // MARK: - Public Methods
    
    /// Enable or disable voice command recognition
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopListening()
        }
        print("Branchr: Voice commands \(enabled ? "enabled" : "disabled")")
    }
    
    /// Start listening for voice commands
    func startListening() {
        guard isEnabled else { return }
        
        // Request permission if not already authorized
        if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
            requestPermissions()
            return
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("Branchr: Speech recognition not authorized")
            return
        }
        
        hasPermission = true
        
        // Cancel any existing recognition task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Branchr: Failed to configure audio session: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Branchr: Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if let result = result {
                self?.processRecognitionResult(result)
            }
            
            if let error = error {
                print("Branchr: Speech recognition error: \(error)")
                self?.stopListening()
            }
        }
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            print("Branchr: Started listening for voice commands")
        } catch {
            print("Branchr: Failed to start audio engine: \(error)")
        }
    }
    
    /// Stop listening for voice commands
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        
        print("Branchr: Stopped listening for voice commands")
    }
    
    /// Clear the last detected command
    func clearCommand() {
        detectedCommand = nil
    }
    
    // MARK: - Private Methods
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.hasPermission = true
                    print("Branchr: Speech recognition permission granted")
                case .denied, .restricted, .notDetermined:
                    self?.hasPermission = false
                    print("Branchr: Speech recognition permission denied")
                @unknown default:
                    self?.hasPermission = false
                    print("Branchr: Speech recognition permission unknown")
                }
            }
        }
    }
    
    private func processRecognitionResult(_ result: SFSpeechRecognitionResult) {
        let spokenText = result.bestTranscription.formattedString
        let lowerText = spokenText.lowercased()
        print("Branchr: Recognized speech: \(spokenText)")
        
        // Phase 34H: Route all recognized speech through VoiceCommandRouter
        VoiceCommandRouter.shared.handleCommand(spokenText)
        
        // Check for ride tracking voice commands
        for command in RideVoiceCommand.allCases {
            for keyword in command.keywords {
                if lowerText.contains(keyword) {
                    detectedCommand = command
                    print("Branchr: Detected command: \(command.displayName)")
                    stopListening() // Stop listening after command detection
                    return
                }
            }
        }
    }
}
