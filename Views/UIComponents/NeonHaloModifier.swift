//
//  NeonHaloModifier.swift
//  branchr
//
//  Sharp, bright rainbow halo - appears on press only
//

import SwiftUI

struct NeonHaloModifier: ViewModifier {
    @State private var isGlowing = false
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isGlowing {
                        // Sharp, vivid rainbow border
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .red
                                    ]),
                                    center: .center
                                ),
                                lineWidth: 3.0
                            )
                            .shadow(color: Color.red.opacity(0.8), radius: 6)
                            .shadow(color: Color.purple.opacity(0.8), radius: 12)
                            .shadow(color: Color.blue.opacity(0.8), radius: 18)
                            .shadow(color: Color.green.opacity(0.8), radius: 24)
                            .allowsHitTesting(false)
                    }
                }
            )
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.25)) {
                    isGlowing = pressing
                }
            }) {}
    }
}

extension View {
    func neonHalo(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(NeonHaloModifier(cornerRadius: cornerRadius))
    }
}

