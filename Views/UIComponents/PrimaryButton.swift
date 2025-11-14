//
//  PrimaryButton.swift
//  branchr
//
//  Phase 2: Non-floating button with press effect and hero support
//

import SwiftUI

/**
 * 🎨 Primary Button Component
 *
 * Reusable button that adapts to light/dark mode.
 * No floating animations - only subtle press-down effect.
 */
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let isHero: Bool
    let action: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isPressed: Bool = false
    
    init(_ title: String,
         systemImage: String? = nil,
         isHero: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isHero = isHero
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
            .foregroundColor(theme.primaryButtonText)
            .padding(.horizontal, 24)
            .padding(.vertical, isHero ? 18 : 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.primaryButtonBackground)
                    .shadow(
                        color: theme.glowColor.opacity(isHero ? 0.8 : 0.4),
                        radius: isHero ? 18 : 10,
                        x: 0,
                        y: isHero ? 8 : 4
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
