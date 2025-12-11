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
    @State private var rotation: Double = 0  // Continuous rotation for rainbow glow
    
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
            ZStack {
                // MARK: Bright, Sharp Rainbow Glow (on press only with continuous rotation)
                if isPressed {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.0, blue: 0.0),      // Ultra bright red
                                    Color(red: 1.0, green: 0.3, blue: 0.0),     // Ultra bright orange
                                    Color(red: 1.0, green: 1.0, blue: 0.0),     // Ultra bright yellow
                                    Color(red: 0.0, green: 1.0, blue: 0.0),     // Ultra bright green
                                    Color(red: 0.0, green: 0.8, blue: 1.0),     // Ultra bright cyan-blue
                                    Color(red: 0.3, green: 0.0, blue: 1.0),     // Ultra bright blue
                                    Color(red: 0.8, green: 0.0, blue: 1.0),     // Ultra bright purple
                                    Color(red: 1.0, green: 0.0, blue: 0.8),     // Ultra bright magenta
                                    Color(red: 1.0, green: 0.0, blue: 0.0)      // Back to red
                                ]),
                                center: .center,
                                angle: .degrees(rotation)
                            ),
                            lineWidth: 6  // Thick, sharp stroke
                        )
                        .opacity(1.0)  // Full brightness
                        .shadow(color: .white.opacity(0.9), radius: 15, x: 0, y: 0)  // Brighter white glow
                        .transition(.opacity)
                }
                
                // Button background
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.isDarkMode ? theme.branchrYellow : Color.black)
                    .shadow(
                        color: theme.glowColor.opacity(0.5),
                        radius: 12,
                        x: 0,
                        y: 6
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
                .foregroundColor(theme.isDarkMode ? Color.black : theme.branchrYellow)
                .padding(.horizontal, 24)
                .padding(.vertical, 10) // Reduced height for better fit on smaller screens
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
            // Phase 34D: Apply rainbow glow using exact RainbowGlowModifier pattern (only when pressed)
            .overlay(
                Group {
                    if isPressed {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        .red, .orange, .yellow, .green, .blue, .purple, .pink, .red
                                    ]),
                                    center: .center,
                                    angle: .degrees(rotation)
                                ),
                                lineWidth: 5  // Phase 33: Same as RainbowGlowModifier
                            )
                            .blur(radius: 2)  // Phase 33: Same as RainbowGlowModifier
                            .opacity(0.9)  // Phase 33: Same as RainbowGlowModifier
                            .shadow(color: .yellow.opacity(0.9), radius: 35, x: 0, y: 0)  // Phase 33: Same
                            .shadow(color: .purple.opacity(0.6), radius: 70, x: 0, y: 0)  // Phase 33: Same
                    }
                }
            )
            .onAppear {
                // Phase 34D: Start continuous rotation animation immediately (exact same as RainbowGlowModifier)
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
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
