//
//  RideTrackingButton.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 19.1 - Enhanced Start Ride Tracking Button
//

import SwiftUI

/**
 * 🚴‍♂️ RideTrackingButton
 *
 * Enhanced button component for starting ride tracking with:
 * - Pulse/glow animation when idle
 * - Tap animation with haptic feedback
 * - Loading state with spinner
 * - Professional press/active effects
 */
struct RideTrackingButton: View {
    
    // MARK: - Properties
    
    let action: () -> Void
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isPressed = false
    @State private var isLoading = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    // MARK: - Body
    
    var body: some View {
        Button(action: handleButtonPress) {
            HStack(spacing: 12) {
                // Icon or Loading Spinner
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.isDarkMode ? .black : .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "location.fill")
                        .font(.headline)
                }
                
                // Button Text
                Text(isLoading ? "Starting..." : "Start Ride Tracking")
                    .font(.headline.bold())
                    .lineLimit(1)
            }
            .foregroundColor(theme.isDarkMode ? .black : .white)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.accentColor)
                    
                    // Glow effect (subtle pulse)
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.accentColor.opacity(glowOpacity))
                        .scaleEffect(pulseScale)
                }
            )
            .overlay(
                // Border glow
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.accentColor.opacity(glowOpacity * 0.5), lineWidth: 2)
                    .scaleEffect(pulseScale)
            )
            .shadow(color: theme.accentColor.opacity(glowOpacity * 0.4), radius: 12, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLoading)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .onAppear {
            startIdleAnimation()
        }
    }
    
    // MARK: - Actions
    
    private func handleButtonPress() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Press animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            isPressed = true
        }
        
        // Reset press state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
        
        // Show loading state
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isLoading = true
        }
        
        // Call action
        action()
        
        // Simulate loading (remove this in Phase 20 when real tracking starts)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isLoading = false
            }
        }
    }
    
    // MARK: - Animations
    
    private func startIdleAnimation() {
        // Subtle pulse animation when idle
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.02
            glowOpacity = 0.5
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RideTrackingButton {
            print("🚴‍♂️ Ride tracking started…")
        }
        .padding()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}

