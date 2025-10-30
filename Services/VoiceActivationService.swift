//
//  VoiceActivationService.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Service for detecting "Hey Branchr" wake word and processing voice commands
final class VoiceActivationService: ObservableObject {
    
    static let shared = VoiceActivationService()
    
    // MARK: - Published Properties
    @Published var isActivated = false
    @Published var isListening = false
    @Published var lastCommand: String?
    @Published var hasPermission: Bool = false
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    
    private let wakeWord = "hey branchr"
    private var isWaitingForWakeWord = true
    private var lastHeardRaw: String = ""
    
    private weak var commandProcessor: CommandProcessor?
    private weak var voiceResponse: VoiceResponseManager?
    
    // MARK: - Initialization
    private init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.inputNode = audioEngine.inputNode
        
        checkPermissions()
        
        print("Branchr: VoiceActivationService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Start listening for wake word
    func start() {
        guard !isListening else { return }
        guard hasPermission else {
            requestPermissions()
            return
        }
        
        startListening()
    }
    
    /// Stop listening
    func stop() {
        stopListening()
        isActivated = false
    }
    
    /// Set dependencies
    func setDependencies(processor: CommandProcessor, response: VoiceResponseManager) {
        self.commandProcessor = processor
        self.voiceResponse = response
    }
    
    // MARK: - Private Methods
    
    private func checkPermissions() {
        let microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        hasPermission = (microphoneStatus == .granted) && (speechStatus == .authorized)
    }
    
    private func requestPermissions() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            if granted {
                print("Branchr: Microphone permission granted")
            } else {
                print("Branchr: Microphone permission denied")
            }
        }
        
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Branchr: Speech recognition authorized")
                    self?.hasPermission = true
                    self?.startListening()
                case .denied, .restricted, .notDetermined:
                    print("Branchr: Speech recognition permission not granted")
                    self?.hasPermission = false
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func startListening() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Branchr: Speech recognition not available")
            return
        }
        
        // Stop any existing task
        stopListening()
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Branchr: Could not create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Branchr: Audio session setup failed: \(error)")
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Branchr: Recognition error: \(error)")
                    self?.stopListening()
                    return
                }
                
                if let result = result {
                    let text = result.bestTranscription.formattedString.lowercased()
                    
                    // Detect speech start/stop for audio ducking
                    if let `self` = self, text != self.lastHeardRaw, !text.isEmpty {
                        self.lastHeardRaw = text
                        AudioManager.shared.toggleVoiceActivity(active: true)
                        self.debounceSilenceReset()
                    }
                    
                    if self?.isWaitingForWakeWord == true {
                        if text.contains(self?.wakeWord ?? "") {
                            print("Branchr: Wake word detected!")
                            self?.isWaitingForWakeWord = false
                            self?.isActivated = true
                            self?.voiceResponse?.sayWakeWordActivated()
                        }
                    } else {
                        // Process command after wake word
                        self?.processCommand(text)
                    }
                }
                
                if result?.isFinal ?? false {
                    self?.resetForNextCommand()
                }
            }
        }
        
        // Install audio tap
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            isWaitingForWakeWord = true
            print("Branchr: Started listening for 'Hey Branchr'")
        } catch {
            print("Branchr: Audio engine start failed: \(error)")
        }
    }
    
    private func stopListening() {
        audioEngine.stop()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        inputNode.removeTap(onBus: 0)
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        isListening = false
        isActivated = false
        
        print("Branchr: Stopped listening")
    }
    
    private func processCommand(_ text: String) {
        guard isActivated else { return }
        
        print("Branchr: Processing command: \(text)")
        
        // Process through command processor
        if let processor = commandProcessor {
            let response = processor.process(text)
            lastCommand = response
            
            // Speak response
            voiceResponse?.say(response)
        }
        
        // Reset after processing
        resetForNextCommand()
    }
    
    private func resetForNextCommand() {
        isActivated = false
        isWaitingForWakeWord = true
    }
    
    // MARK: - Audio Ducking Helpers
    
    private var silenceTimer: Timer?
    
    private func debounceSilenceReset() {
        // Cancel existing timer
        silenceTimer?.invalidate()
        
        // Start new timer for 2 seconds
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.resetVoiceState()
        }
    }
    
    private func resetVoiceState() {
        AudioManager.shared.toggleVoiceActivity(active: false)
    }
}

