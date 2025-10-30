//
//  PandoraIntegrationService.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Service for integrating with various music apps through deep linking
/// Provides seamless navigation from Branchr to the appropriate music app
final class PandoraIntegrationService: ObservableObject {
    
    /// Build a Pandora deep link URL for the given track
    func buildPandoraURL(for track: NowPlayingInfo) -> URL? {
        // Pandora deep link format: pandora://www.pandora.com/search/<query>
        let query = "\(track.artist) \(track.title)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "pandora://www.pandora.com/search/\(encodedQuery)"
        return URL(string: urlString)
    }
    
    /// Build an Apple Music deep link URL for the given track
    func buildAppleMusicURL(for track: NowPlayingInfo) -> URL? {
        // Apple Music deep link format: music://search?term=<query>
        let query = "\(track.artist) \(track.title)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "music://search?term=\(encodedQuery)"
        return URL(string: urlString)
    }
    
    /// Build a YouTube Music deep link URL for the given track
    func buildYouTubeMusicURL(for track: NowPlayingInfo) -> URL? {
        // YouTube Music deep link format: youtubemusic://search/<query>
        let query = "\(track.artist) \(track.title)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "youtubemusic://search/\(encodedQuery)"
        return URL(string: urlString)
    }
    
    /// Build a Spotify deep link URL for the given track
    func buildSpotifyURL(for track: NowPlayingInfo) -> URL? {
        // Spotify deep link format: spotify:search:<query>
        let query = "\(track.artist) \(track.title)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "spotify:search:\(encodedQuery)"
        return URL(string: urlString)
    }
    
    /// Open the track in Pandora
    func openInPandora(_ track: NowPlayingInfo) {
        guard let url = buildPandoraURL(for: track) else {
            print("Branchr: Failed to build Pandora URL for track: \(track.title)")
            return
        }
        
        openURL(url, appName: "Pandora")
    }
    
    /// Open the track in Apple Music
    func openInAppleMusic(_ track: NowPlayingInfo) {
        guard let url = buildAppleMusicURL(for: track) else {
            print("Branchr: Failed to build Apple Music URL for track: \(track.title)")
            return
        }
        
        openURL(url, appName: "Apple Music")
    }
    
    /// Open the track in YouTube Music
    func openInYouTubeMusic(_ track: NowPlayingInfo) {
        guard let url = buildYouTubeMusicURL(for: track) else {
            print("Branchr: Failed to build YouTube Music URL for track: \(track.title)")
            return
        }
        
        openURL(url, appName: "YouTube Music")
    }
    
    /// Open the track in Spotify
    func openInSpotify(_ track: NowPlayingInfo) {
        guard let url = buildSpotifyURL(for: track) else {
            print("Branchr: Failed to build Spotify URL for track: \(track.title)")
            return
        }
        
        openURL(url, appName: "Spotify")
    }
    
    /// Open the track in the appropriate app based on source
    func openInApp(_ track: NowPlayingInfo) {
        switch track.sourceApp {
        case .appleMusic:
            openInAppleMusic(track)
        case .pandora:
            openInPandora(track)
        case .youtubeMusic:
            openInYouTubeMusic(track)
        case .spotify:
            openInSpotify(track)
        case .unknown:
            // Try Apple Music as fallback
            openInAppleMusic(track)
        }
    }
    
    /// Generic URL opening method with fallback handling
    private func openURL(_ url: URL, appName: String) {
        #if canImport(UIKit)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if success {
                    print("Branchr: Successfully opened \(appName) for track")
                } else {
                    print("Branchr: Failed to open \(appName)")
                    self.showFallbackAlert(appName: appName)
                }
            }
        } else {
            print("Branchr: Cannot open \(appName) - app not installed")
            showFallbackAlert(appName: appName)
        }
        #else
        print("Branchr: URL opening not available on this platform")
        #endif
    }
    
    /// Show fallback alert when app is not installed
    private func showFallbackAlert(appName: String) {
        DispatchQueue.main.async {
            // In a real app, you'd show an alert or navigate to App Store
            print("Branchr: \(appName) is not installed. Consider showing App Store link.")
        }
    }
    
    /// Check if a specific music app is installed
    func isAppInstalled(_ source: MusicSource) -> Bool {
        #if canImport(UIKit)
        let url: URL?
        
        switch source {
        case .appleMusic:
            url = URL(string: "music://")
        case .pandora:
            url = URL(string: "pandora://")
        case .youtubeMusic:
            url = URL(string: "youtubemusic://")
        case .spotify:
            url = URL(string: "spotify://")
        case .unknown:
            return false
        }
        
        guard let testURL = url else { return false }
        return UIApplication.shared.canOpenURL(testURL)
        #else
        return false
        #endif
    }
    
    /// Get available music apps on this device
    func getAvailableApps() -> [MusicSource] {
        return MusicSource.allCases.filter { source in
            source != .unknown && isAppInstalled(source)
        }
    }
    
    /// Get the best fallback app for opening music
    func getBestFallbackApp() -> MusicSource {
        let availableApps = getAvailableApps()
        
        // Priority order: Apple Music, Spotify, YouTube Music, Pandora
        let priorityOrder: [MusicSource] = [.appleMusic, .spotify, .youtubeMusic, .pandora]
        
        for app in priorityOrder {
            if availableApps.contains(app) {
                return app
            }
        }
        
        return .unknown
    }
}
