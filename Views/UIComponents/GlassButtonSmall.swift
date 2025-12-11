//
//  GlassButtonSmall.swift
//  branchr
//
//  Created for Phase 76 - Small Glass Control Buttons
//

import SwiftUI

/**
 * 💎 Small Glass Button
 *
 * Used for audio controls: Unmuted, DJ Controls, Music On.
 * Compact tile design with icon and label.
 */
struct GlassButtonSmall: View {
    let icon: String
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(icon: String, title: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticsService.shared.lightTap()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(isActive ? 0.40 : 0.15), lineWidth: isActive ? 1.2 : 0.8)
                            )
                    )
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .rainbowGlow(active: isPressed)
        .scaleEffect(isPressed ? 0.95 : 1.0)
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

