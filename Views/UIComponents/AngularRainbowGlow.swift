//
//  AngularRainbowGlow.swift
//  branchr
//
//  Premium neon rainbow ring for center tab button
//

import SwiftUI

struct AngularRainbowGlow: View {
    var body: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .red,
                        .orange,
                        .yellow,
                        .green,
                        .cyan,
                        .blue,
                        .purple,
                        .red
                    ]),
                    center: .center
                ),
                lineWidth: 3.5
            )
            .shadow(color: .red.opacity(0.25), radius: 12)
            .shadow(color: .orange.opacity(0.20), radius: 12)
            .shadow(color: .yellow.opacity(0.20), radius: 12)
            .shadow(color: .green.opacity(0.20), radius: 12)
            .shadow(color: .blue.opacity(0.25), radius: 12)
            .shadow(color: .purple.opacity(0.30), radius: 18)
    }
}

