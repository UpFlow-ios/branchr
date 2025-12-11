//
//  GlassButtonLarge.swift
//  branchr
//
//  Created for Phase 76 - Large Glass Action Buttons (Black Glass)
//

import SwiftUI

/**
 * 💎 Large Glass Button (Black Glass Style)
 *
 * Used for primary actions: Start Ride, Connection, Voice Chat.
 * Features black glass aesthetic with rainbow glow on press.
 */
struct GlassButtonLarge: View {
    let title: String
    let icon: String?
    let isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(title: String, icon: String? = nil, isActive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticsService.shared.mediumTap()
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.35))
            .liquidGlass(cornerRadius: 22) // iOS 26 Interactive Liquid Glass
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

