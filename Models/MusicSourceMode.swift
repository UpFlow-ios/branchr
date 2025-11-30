//
//  MusicSourceMode.swift
//  branchr
//
//  Created for Phase 51 - Music Source Selector + Simultaneous Music & Voice
//

import Foundation
import SwiftUI

/// User's choice for how to handle music during rides
/// Phase 51: Allows users to choose between Apple Music (Synced) or Other Music App
enum MusicSourceMode: String, Codable, CaseIterable, Identifiable {
    case appleMusicSynced = "apple_music_synced"
    case externalPlayer = "external_player"
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .appleMusicSynced:
            return "Apple Music (Synced)"
        case .externalPlayer:
            return "Other Music App"
        }
    }
    
    var subtitle: String {
        switch self {
        case .appleMusicSynced:
            return "Branchr controls playback"
        case .externalPlayer:
            return "Play from any app"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .appleMusicSynced:
            return "music.note.list"
        case .externalPlayer:
            return "apps.iphone"
        }
    }
    
    // Phase 55: Short title for compact display (without "(Synced)" suffix)
    var shortTitle: String {
        switch self {
        case .appleMusicSynced:
            return "Apple Music"
        case .externalPlayer:
            return "Other App"
        }
    }
    
    // Phase 57: System icon name for DJ Controls header pill
    var systemIconName: String {
        switch self {
        case .appleMusicSynced:
            return "apple.logo"
        case .externalPlayer:
            return "music.note.list"
        }
    }
    
    // Phase 58: Asset name for branded logo images
    var assetName: String {
        switch self {
        case .appleMusicSynced:
            return "appleMusicLogo"
        case .externalPlayer:
            return "otherMusicLogo"
        }
    }
}

