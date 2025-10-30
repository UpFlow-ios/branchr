//
//  LaunchBikeRiderView.swift
//  branchr
//
//  Created by Joe Dormond on 10/24/25.
//

import SwiftUI

/// Individual bike rider component for the launch animation
/// Displays a minimalist bike rider silhouette that can be animated
struct LaunchBikeRiderView: View {
    let index: Int
    @State private var wheelRotation: Double = 0
    @State private var isAnimating = false
    
    // Rider names
    private var riderName: String {
        switch index {
        case 0: return "Manny"
        case 1: return "Joe"
        case 2: return "Anthony"
        default: return "Rider \(index + 1)"
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Bike rider silhouette using SF Symbol
            Image(systemName: "bicycle.circle.fill")
                .font(.system(size: 60, weight: .black))
                .foregroundColor(.black)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                .rotationEffect(.degrees(wheelRotation))
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isAnimating)
            
            // Optional rider label
            Text(riderName)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.black.opacity(0.7))
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(0.2), value: isAnimating)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start wheel rotation animation
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            wheelRotation = 360
        }
        
        // Start scale animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 1.0, green: 0.86, blue: 0.2)
            .ignoresSafeArea()
        
        LaunchBikeRiderView(index: 0)
    }
}
