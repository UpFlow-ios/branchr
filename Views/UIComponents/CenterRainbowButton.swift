//
//  CenterRainbowButton.swift
//  branchr
//
//  Premium floating center tab button with rainbow glow
//

import SwiftUI

struct CenterRainbowButton: View {
    @Binding var selectedTab: Int
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            // Rainbow glow ring
            AngularRainbowGlow()
                .frame(width: 72, height: 72)
            
            // Glass center
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 62, height: 62)
                .shadow(color: .white.opacity(0.15), radius: 4, y: 2)
            
            // Icon
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
        }
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                isPressed = true
                action()
                HapticsService.shared.mediumTap()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.65)) {
                    isPressed = false
                }
            }
        }
    }
}

