//
//  RainbowPulseGlowModifier.swift
//  branchr
//
//  Created for Smart Group Ride System - Enhanced Rainbow Pulse Glow
//

import SwiftUI

/**
 * 🌈 Rainbow Pulse Glow Modifier
 *
 * Cinematic, multi-layer depth glow with smooth gradient diffusion.
 * Supports network-synced pulses via PulseSyncService.
 */
struct RainbowPulseGlowModifier: ViewModifier {
    @ObservedObject private var syncService = PulseSyncService.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var localPhase: Double = 0
    
    private let pulseDuration: TimeInterval = 1.6
    private let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .red]
    
    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let timelinePhase = timelinePhase(for: timeline.date)
            let phase = syncService.isSynced ? syncService.syncPhase : timelinePhase
            let angle = Angle(degrees: phase * 360)
            
            ZStack {
                content
                    .shadow(color: Color.white.opacity(0.18), radius: 3, x: 0, y: 0)
                    .overlay(innerHalo(angle: angle, phase: phase))
                    .overlay(midHalo(phase: phase))
                    .overlay(outerWave(phase: phase))
            }
            .onAppear {
                localPhase = Double.random(in: 0..<1)
            }
        }
    }
    
    private func timelinePhase(for date: Date) -> Double {
        let elapsed = date.timeIntervalSince1970
        let phase = (elapsed.truncatingRemainder(dividingBy: pulseDuration)) / pulseDuration
        return phase
    }
    
    private func innerHalo(angle: Angle, phase: Double) -> some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: rainbowColors),
                    center: .center,
                    angle: angle
                ),
                lineWidth: 3.0
            )
            .blur(radius: 1.5)
            .opacity(0.55 + 0.35 * sin(phase * .pi))
            .scaleEffect(1.02 + 0.04 * sin(phase * 2 * .pi))
    }
    
    private func midHalo(phase: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.28 : 0.34),
                        Color.white.opacity(0.05),
                        .clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 140
                )
            )
            .blur(radius: 18)
            .opacity(0.35 + 0.25 * sin(phase * .pi))
            .scaleEffect(1.2 + 0.15 * sin(phase * 2 * .pi))
    }
    
    private func outerWave(phase: Double) -> some View {
        Circle()
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: rainbowColors.map { $0.opacity(0.45) }),
                    center: .center
                ),
                lineWidth: 6
            )
            .blur(radius: 22)
            .opacity(max(0, 0.55 - 0.55 * phase))
            .scaleEffect(1.0 + 0.5 * CGFloat(phase))
            .blendMode(.plusLighter)
    }
}

extension View {
    func rainbowPulseGlow() -> some View {
        modifier(RainbowPulseGlowModifier())
    }
}

