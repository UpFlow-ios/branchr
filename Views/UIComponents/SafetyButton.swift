//
//  SafetyButton.swift
//  branchr
//
//  Created for Phase 1 - UI Foundation Cleanup
//

import SwiftUI

/**
 * ⚠️ Safety Button Component
 *
 * Special styling: Black background with yellow text.
 * Used for Safety & SOS actions.
 */
struct SafetyButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.headline)
                Text("Safety & SOS")
                    .font(.headline)
            }
            .foregroundColor(.yellow)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .cornerRadius(16)
            .shadow(radius: 8)
        }
        .buttonStyle(.plain)
    }
}

