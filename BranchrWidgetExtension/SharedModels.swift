//
//  SharedModels.swift
//  BranchrWidgetExtension
//
//  Created by Joe Dormond on 2025-10-24.
//

import SwiftUI

/// Defines different operational modes for Branchr.
/// This is a copy of the enum from the main app for widget access.
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
    
    var themeColor: Color {
        switch self {
        case .ride: return .blue
        case .camp: return .green
        case .study: return .purple
        case .caravan: return .orange
        }
    }
}
