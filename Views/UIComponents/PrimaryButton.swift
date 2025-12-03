//
//  PrimaryButton.swift
//  branchr
//
//  Phase 3A: Non-floating button with rainbow press glow effect
//

import SwiftUI

/**
 * 🎨 Primary Button Component
 *
 * Reusable button that adapts to light/dark mode.
 * Shows rainbow gradient flash on press (0.25s).
 * No floating animations - only subtle press-down effect.
 */
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let isHero: Bool
    let isNeonHalo: Bool  // Phase 3B: Enable sharp neon rainbow halo (on press only)
    let disableOuterGlow: Bool  // Phase 67: Disable outer glow shadow
    let action: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isPressed: Bool = false
    
    init(_ title: String,
         systemImage: String? = nil,
         isHero: Bool = false,
         isNeonHalo: Bool = false,
         disableOuterGlow: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isHero = isHero
        self.isNeonHalo = isNeonHalo
        self.disableOuterGlow = disableOuterGlow
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                
                // MARK: Neon Halo — thin, bright, Apple Home style (on press only)
                if isNeonHalo && isPressed {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .green, .yellow, .orange, .red, .pink, .purple, .blue, .green
                                ]),
                                center: .center
                            ),
                            lineWidth: 3 // THIN neon line
                        )
                        .padding(-3) // edge clamp
                        .shadow(color: .white.opacity(0.9), radius: 6)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.15), value: isPressed)
                }
                
                // Normal button background
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.primaryButtonBackground)
                    .shadow(
                        color: disableOuterGlow ? .clear : theme.glowColor.opacity(isHero ? 0.8 : 0.4),
                        radius: disableOuterGlow ? 0 : (isHero ? 18 : 10),
                        x: 0,
                        y: disableOuterGlow ? 0 : (isHero ? 8 : 4)
                    )
                
                // Button content
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
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { down in
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = down
            }
        }, perform: {})
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel(Text(title))
    }
}
