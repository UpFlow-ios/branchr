//
//  LiquidGlass.swift
//  branchr
//
//  Premium Liquid Glass with Interactive Parallax Tilt
//  Created for Phase 76C - Apple Design Award Quality UI
//

import SwiftUI
import CoreMotion

/**
 * 💎 Liquid Glass Modifier (Premium Interactive Glass)
 *
 * Features:
 * - .ultraThinMaterial for authentic Apple glass aesthetic
 * - 3D parallax tilt using CoreMotion (matches Apple Music/VisionOS)
 * - Interactive press ripple with gesture recognition
 * - Dynamic shadows that follow device tilt
 * - Smooth animations for all interactions
 */
struct LiquidGlass: ViewModifier {
    let cornerRadius: CGFloat
    
    @GestureState private var isPressed = false
    @State private var tiltAmount: CGSize = .zero
    @State private var motionManager = CMMotionManager()
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(Double(tiltAmount.width / 40)),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(Double(-tiltAmount.height / 40)),
                axis: (x: 1, y: 0, z: 0)
            )
            .offset(
                x: tiltAmount.width / 6,
                y: tiltAmount.height / 6
            )
            .shadow(
                color: .black.opacity(0.2),
                radius: 20,
                x: tiltAmount.width / 10,
                y: tiltAmount.height / 10
            )
            .animation(.easeOut(duration: 0.2), value: tiltAmount)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, pressed, _ in
                        pressed = true
                    }
            )
            .onAppear { startMotion() }
            .onDisappear { stopMotion() }
    }
    
    // MARK: - Motion Handling
    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion, error == nil else { return }
            
            tiltAmount = CGSize(
                width: CGFloat(motion.attitude.roll * 15),
                height: CGFloat(motion.attitude.pitch * 15)
            )
        }
    }
    
    private func stopMotion() {
        motionManager.stopDeviceMotionUpdates()
    }
}

extension View {
    /// Apply interactive liquid glass effect with parallax tilt
    func liquidGlass(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(LiquidGlass(cornerRadius: cornerRadius))
    }
}

