//
//  ApplePressAnimation.swift
//  branchr
//
//  Apple-style press animations and ripple effects
//

import SwiftUI

// MARK: - Apple Press Animation
extension View {
    func applePressable(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: isPressed)
    }
}

// MARK: - Ripple Tap Effect
struct RippleTapEffect: ViewModifier {
    @State private var ripple = false
    let onTap: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .scaleEffect(ripple ? 1.8 : 0.1)
                    .opacity(ripple ? 0 : 1)
                    .allowsHitTesting(false)
            )
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.25)) {
                    ripple = true
                }
                onTap()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    ripple = false
                }
            }
    }
}

extension View {
    func rippleEffect(action: @escaping () -> Void) -> some View {
        self.modifier(RippleTapEffect(onTap: action))
    }
}

