//
//  ModeConfiguration.swift
//  Branchr
//
//  Created by Joe Dormond on 2025-10-24.
//

import SwiftUI

/// Defines different operational modes for Branchr.
enum BranchrMode: String, Codable, CaseIterable {
    case ride, camp, study, caravan
    
    var displayName: String {
        switch self {
        case .ride: return "Ride Mode"
        case .camp: return "Camp Mode"
        case .study: return "Study Mode"
        case .caravan: return "Caravan Mode"
        }
    }
    
    var icon: String {
        switch self {
        case .ride: return "🚴‍♂️"
        case .camp: return "🏕️"
        case .study: return "🎓"
        case .caravan: return "🚗"
        }
    }
}

/// Configuration values for each mode
struct ModeConfiguration {
    let name: String
    let description: String
    let themeColor: Color
    let aiPersonality: String
    let musicDuckingLevel: Float
    
    static func preset(for mode: BranchrMode) -> ModeConfiguration {
        switch mode {
        case .ride:
            return ModeConfiguration(name: "Ride Mode",
                                      description: "Perfect for cycling and jogging sessions.",
                                      themeColor: .blue,
                                      aiPersonality: "coach",
                                      musicDuckingLevel: 0.4)
        case .camp:
            return ModeConfiguration(name: "Camp Mode",
                                      description: "Offline communication for campers and hikers.",
                                      themeColor: .green,
                                      aiPersonality: "guide",
                                      musicDuckingLevel: 0.6)
        case .study:
            return ModeConfiguration(name: "Study Mode",
                                      description: "Focus quietly with AI tutor and muted chat.",
                                      themeColor: .purple,
                                      aiPersonality: "tutor",
                                      musicDuckingLevel: 0.2)
        case .caravan:
            return ModeConfiguration(name: "Caravan Mode",
                                      description: "Group travel with shared navigation & talk.",
                                      themeColor: .orange,
                                      aiPersonality: "navigator",
                                      musicDuckingLevel: 0.5)
        }
    }
}
