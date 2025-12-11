//
//  GlassSOSButton.swift
//  branchr
//
//  Created for Phase 76 - Glass SOS Emergency Button
//

import SwiftUI

/**
 * 🚨 Glass SOS Button
 *
 * Large, glowing red-glass emergency button.
 * Features red accent with translucent material for safety visibility.
 */
struct GlassSOSButton: View {
    let isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(isActive: Bool = false, action: @escaping () -> Void) {
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticsService.shared.heavyTap()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("SOS")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.35),
                            Color.red.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.red.opacity(0.50), lineWidth: 1.5)
            )
            .shadow(color: .red.opacity(0.35), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .rainbowGlow(active: isActive || isPressed)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

