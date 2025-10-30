//
//  LaunchAnimationView.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import SwiftUI

/// Animated launch screen showing 3 cyclists riding across the screen
/// Mimics a traffic sign aesthetic with yellow background and black silhouettes
struct LaunchAnimationView: View {
    @State private var showHome = false
    @State private var ridersOffset: CGFloat = -200
    @State private var fadeInOpacity: Double = 0
    @State private var fadeOutOpacity: Double = 1
    
    let onAnimationComplete: () -> Void
    
    init(onAnimationComplete: @escaping () -> Void = {}) {
        self.onAnimationComplete = onAnimationComplete
    }
    
    var body: some View {
        ZStack {
            // Traffic sign yellow background
            Color(red: 1.0, green: 0.86, blue: 0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Branchr title
                Text("Branchr")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .opacity(fadeInOpacity)
                    .animation(.easeInOut(duration: 0.8).delay(0.5), value: fadeInOpacity)
                
                Spacer()
                
                // Animated riders container
                HStack(spacing: 40) {
                    ForEach(0..<3, id: \.self) { index in
                        LaunchBikeRiderView(index: index)
                            .offset(x: ridersOffset)
                            .animation(
                                .easeInOut(duration: 2.5)
                                .delay(Double(index) * 0.2),
                                value: ridersOffset
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Subtitle
                Text("Connect with your group")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black.opacity(0.8))
                    .opacity(fadeInOpacity)
                    .animation(.easeInOut(duration: 0.8).delay(1.0), value: fadeInOpacity)
                
                Spacer()
            }
            .opacity(fadeOutOpacity)
        }
        .onAppear {
            startLaunchSequence()
        }
    }
    
    private func startLaunchSequence() {
        // Start fade in animation
        withAnimation(.easeInOut(duration: 0.8)) {
            fadeInOpacity = 1.0
        }
        
        // Start riders animation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 2.5)) {
                ridersOffset = 200
            }
        }
        
        // Start fade out and transition after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                fadeOutOpacity = 0.0
            }
            
            // Complete animation and transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onAnimationComplete()
            }
        }
    }
}

#Preview {
    LaunchAnimationView()
}
