import Foundation
import Speech
import AVFoundation
import Combine

/// Service for handling voice-based song requests with wake word detection
final class VoiceSongRequestService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isListening = false
    @Published var isWakeWordListening = false
    @Published var recognizedText = ""
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var wakeWordDetected = false
    
    // MARK: - Private Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Wake word detection
    private var isWaitingForWakeWord = true
    private let wakeWords = ["hey branchr", "hey branch", "branchr", "branch"]
    
    // MARK: - Dependencies
    private weak var songRequestManager: SongRequestManager?
    private weak var groupSessionManager: GroupSessionManager?
    
    // MARK: - Initialization
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        
        // Don't request permission immediately - wait until user actually wants to use voice features
        print("Branchr: VoiceSongRequestService initialized - permission will be requested when needed")
    }
    
    func setDependencies(songRequestManager: SongRequestManager, groupSessionManager: GroupSessionManager) {
        self.songRequestManager = songRequestManager
        self.groupSessionManager = groupSessionManager
    }
    
    // MARK: - Speech Recognition Permission
    private func requestSpeechRecognitionPermission() {
        // Check if speech recognition is available before requesting
        guard SFSpeechRecognizer.authorizationStatus() != .denied else {
            print("Branchr: Speech recognition already denied")
            lastError = "Speech recognition denied"
            return
        }
        
        // Add additional safety check
        guard SFSpeechRecognizer.authorizationStatus() == .notDetermined else {
            print("Branchr: Speech recognition already has status: \(SFSpeechRecognizer.authorizationStatus().rawValue)")
            return
        }
        
        print("Branchr: Requesting speech recognition permission...")
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Branchr: Speech recognition authorized")
                case .denied:
                    print("Branchr: Speech recognition denied")
                    self?.lastError = "Speech recognition permission denied"
                case .restricted:
                    print("Branchr: Speech recognition restricted")
                    self?.lastError = "Speech recognition restricted"
                case .notDetermined:
                    print("Branchr: Speech recognition not determined")
                    self?.lastError = "Speech recognition permission not determined"
                @unknown default:
                    print("Branchr: Speech recognition unknown status")
                    self?.lastError = "Speech recognition unknown status"
                }
            }
        }
    }
    
    // MARK: - Voice Recognition
    func startListening() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            lastError = "Speech recognition not available"
            return
        }
        
        // Request permission if not already authorized
        if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
            requestSpeechRecognitionPermission()
            return
        }
        
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            lastError = "Speech recognition not authorized"
            return
        }
        
        // Stop any existing recognition
        stopListening()
        
        // Start with wake word listening
        startWakeWordListening()
    }
    
    func startWakeWordListening() {
        guard let speechRecognizer = speechRecognizer else { return }
        
        // Create recognition request for wake word detection
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            lastError = "Unable to create recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            lastError = "Audio session setup failed: \(error.localizedDescription)"
            return
        }
        
        // Start recognition task for wake word detection
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let text = result.bestTranscription.formattedString.lowercased()
                    self?.recognizedText = text
                    
                    // Check for wake words
                    if self?.isWaitingForWakeWord == true {
                        if self?.containsWakeWord(text) == true {
                            self?.wakeWordDetected = true
                            self?.isWaitingForWakeWord = false
                            self?.startCommandListening()
                        }
                    }
                }
                
                if let error = error {
                    self?.lastError = "Recognition error: \(error.localizedDescription)"
                    self?.stopListening()
                }
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
            isWakeWordListening = true
            isListening = true
            recognizedText = ""
            print("Branchr: Started wake word listening - say 'Hey Branchr'")
        } catch {
            lastError = "Audio engine start failed: \(error.localizedDescription)"
        }
    }
    
    private func startCommandListening() {
        guard let speechRecognizer = speechRecognizer else { return }
        
        // Stop current recognition
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create new recognition request for command
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            lastError = "Unable to create command recognition request"
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start recognition task for command
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self?.recognizedText = text
                    
                    // Process command when final
                    if result.isFinal {
                        self?.processSongRequest(text)
                        self?.resetToWakeWordListening()
                    }
                }
                
                if let error = error {
                    self?.lastError = "Command recognition error: \(error.localizedDescription)"
                    self?.resetToWakeWordListening()
                }
            }
        }
        
        // Configure audio engine for command listening
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        print("Branchr: Wake word detected! Listening for command...")
    }
    
    private func resetToWakeWordListening() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isWaitingForWakeWord = true
            self.wakeWordDetected = false
            self.startWakeWordListening()
        }
    }
    
    private func containsWakeWord(_ text: String) -> Bool {
        return wakeWords.contains { text.contains($0) }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Reset audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Branchr: Failed to deactivate audio session: \(error)")
        }
        
        isListening = false
        isWakeWordListening = false
        isWaitingForWakeWord = true
        wakeWordDetected = false
        recognizedText = ""
        
        print("Branchr: Stopped voice song request listening")
    }
    
    // MARK: - Continuous Listening Mode
    func startContinuousListening() {
        print("Branchr: Starting continuous voice song request listening...")
        print("Branchr: Say 'Hey Branchr' followed by your request")
        print("Branchr: Examples:")
        print("Branchr: - 'Hey Branchr play Calvin Harris'")
        print("Branchr: - 'Hey Branchr play Summer by Calvin Harris'")
        print("Branchr: - 'Hey Branchr play Shape of You by Ed Sheeran'")
        
        startListening()
    }
    
    func stopContinuousListening() {
        stopListening()
        print("Branchr: Stopped continuous voice song request listening")
    }
    
    // MARK: - Song Request Processing
    private func processSongRequest(_ text: String) {
        isProcessing = true
        
        // Parse the voice input for song title and artist
        let parsedRequest = parseSongRequest(text)
        
        if let title = parsedRequest.title, !title.isEmpty {
            Task {
                await songRequestManager?.sendRequest(title: title, artist: parsedRequest.artist, requestedBy: "Voice Request")
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.recognizedText = ""
                }
            }
        } else {
            lastError = "Could not identify song from: \(text)"
            isProcessing = false
        }
    }
    
    private func parseSongRequest(_ text: String) -> (title: String?, artist: String?) {
        let lowercaseText = text.lowercased()
        
        // Remove wake words from the beginning
        let cleanedText = removeWakeWords(from: lowercaseText)
        
        // Enhanced patterns for natural language commands
        let patterns = [
            // "play [artist]" - most common case
            "play (.+)",
            "play song (.+)",
            "play music (.+)",
            
            // "play [song] by [artist]"
            "play (.+) by (.+)",
            "play song (.+) by (.+)",
            "play music (.+) by (.+)",
            
            // "request [song] by [artist]"
            "request (.+) by (.+)",
            "request song (.+) by (.+)",
            "can you play (.+) by (.+)",
            
            // "play [artist] [song]"
            "play (.+) (.+)",
            
            // Just artist name
            "(.+)",
            
            // Song title only
            "song (.+)",
            "music (.+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: cleanedText.count)
                if let match = regex.firstMatch(in: cleanedText, options: [], range: range) {
                    if match.numberOfRanges >= 3 {
                        // Has both title and artist
                        let titleRange = match.range(at: 1)
                        let artistRange = match.range(at: 2)
                        
                        if let titleSwiftRange = Range(titleRange, in: cleanedText),
                           let artistSwiftRange = Range(artistRange, in: cleanedText) {
                            let title = String(cleanedText[titleSwiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            let artist = String(cleanedText[artistSwiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            return (title, artist)
                        }
                    } else if match.numberOfRanges >= 2 {
                        // Has only one parameter - could be artist or song
                        let paramRange = match.range(at: 1)
                        if let paramSwiftRange = Range(paramRange, in: cleanedText) {
                            let param = String(cleanedText[paramSwiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // Smart detection: if it's a common artist name pattern, treat as artist
                            if isLikelyArtist(param) {
                                return (nil, param)
                            } else {
                                // Otherwise treat as song title
                                return (param, nil)
                            }
                        }
                    }
                }
            }
        }
        
        // Fallback: treat the whole cleaned text as song title
        return (cleanedText.trimmingCharacters(in: .whitespacesAndNewlines), nil)
    }
    
    private func removeWakeWords(from text: String) -> String {
        var cleanedText = text
        for wakeWord in wakeWords {
            if cleanedText.hasPrefix(wakeWord) {
                cleanedText = String(cleanedText.dropFirst(wakeWord.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        return cleanedText
    }
    
    private func isLikelyArtist(_ text: String) -> Bool {
        // Common patterns that suggest this is an artist name
        let artistPatterns = [
            // Single word names (common for artists)
            "^[a-z]+$",
            // Two word names
            "^[a-z]+ [a-z]+$",
            // Names with common artist suffixes
            ".*\\b(feat|featuring|ft|&|and)\\b.*"
        ]
        
        for pattern in artistPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.count)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Dependency Injection
    func setSongRequestManager(_ manager: SongRequestManager) {
        self.songRequestManager = manager
    }
    
    func setGroupSessionManager(_ manager: GroupSessionManager) {
        self.groupSessionManager = manager
    }
    
    var isAvailable: Bool {
        return speechRecognizer?.isAvailable ?? false
    }
}
