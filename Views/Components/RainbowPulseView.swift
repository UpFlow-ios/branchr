//
//  RainbowPulseView.swift
//  branchr
//
//  Created for Phase 35B - Rainbow Pulse Countdown
//

import SwiftUI

/// Expanding rainbow pulse used during ride-stop countdown
struct RainbowPulseView: View {
    @Binding var progress: Double
    var maxRadius: CGFloat = 180

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: rainbowColors),
                            center: .center
                        ),
                        lineWidth: 5
                    )
                    .frame(width: radius(for: i), height: radius(for: i))
                    .opacity(opacity(for: i))
                    .scaleEffect(scale(for: i))
                    .animation(.easeOut(duration: 0.5).delay(Double(i) * 0.1), value: progress)
            }
        }
        .blur(radius: 1.5)
        .allowsHitTesting(false)
    }

    private var rainbowColors: [Color] {
        [.red, .orange, .yellow, .green, .blue, .indigo, .purple]
    }

    private func radius(for i: Int) -> CGFloat {
        maxRadius * CGFloat(progress) * CGFloat(1 + (Double(i) * 0.15))
    }

    private func opacity(for i: Int) -> Double {
        1.0 - (Double(i) * 0.15)
    }

    private func scale(for i: Int) -> CGFloat {
        1.0 + CGFloat(progress) * 0.2 * CGFloat(i)
    }
}

