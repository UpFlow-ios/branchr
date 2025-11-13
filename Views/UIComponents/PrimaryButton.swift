//
//  PrimaryButton.swift
//  branchr
//
//  Created for Phase 1 - UI Foundation Cleanup
//

import SwiftUI

/**
 * 🎨 Primary Button Component
 *
 * Reusable button with permanent rainbow glow animation.
 * Always yellow background with black text.
 */
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false
    
    @State private var glow = false
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.black)
            .padding()
            .frame(maxWidth: .infinity)
            .background(theme.primaryYellow)
            .cornerRadius(16)
            .shadow(
                color: theme.primaryGlow.opacity(glow ? 0.7 : 0.3),
                radius: glow ? 20 : 6
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onAppear {
            glow = true
        }
        .animation(
            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
            value: glow
        )
    }
}

