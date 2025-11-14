//
//  SafetyButton.swift
//  branchr
//
//  Phase 2: Safety button - always black with yellow text
//

import SwiftUI

/**
 * ⚠️ Safety Button Component
 *
 * Special styling: Always black background with yellow text.
 * Used for Safety & SOS actions.
 */
struct SafetyButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isPressed: Bool = false
    
    init(_ title: String,
         systemImage: String? = nil,
         action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(theme.safetyButtonText)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.safetyButtonBackground)
                    .shadow(
                        color: theme.glowColor.opacity(0.5),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityLabel(Text(title))
    }
}
