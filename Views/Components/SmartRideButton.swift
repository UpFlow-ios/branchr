//
//  SmartRideButton.swift
//  branchr
//
//  Created for Smart Group Ride System - Unified Adaptive Ride Button
//

import SwiftUI

/**
 * 🚴‍♂️ Smart Ride Button
 *
 * Unified adaptive button that handles both solo and group rides.
 * Changes appearance and behavior based on ride state.
 */
struct SmartRideButton: View {
    @ObservedObject private var rideManager = RideSessionManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var holdProgress: Double = 0.0
    @State private var isHolding = false
    @State private var holdTimer: Timer?
    
    let onStartSolo: () -> Void
    let onStartGroup: () -> Void
    
    var body: some View {
        buildButton()
            .buttonStyle(.plain)
            .rainbowGlow(active: shouldShowGlow)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 5.0)
                    .onEnded { _ in handleLongPress() }
                    .onChanged { _ in
                        if !isHolding { startHoldTimer() }
                    }
            )
    }
    
    @ViewBuilder
    private func buildButton() -> some View {
        Button(action: handleTap) {
            Text(buttonTitle)
                .font(.headline.weight(.semibold))
                .foregroundColor(buttonTextColor)
                .frame(maxWidth: .infinity)
                .padding()
                .background(buttonBackgroundColor)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if isHolding {
                            GeometryReader { geometry in
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.red.opacity(0.25))
                                    .frame(width: geometry.size.width * holdProgress)
                                    .animation(.linear(duration: 5.0), value: holdProgress)
                            }
                        }
                    }
                )
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Computed Properties
    
    private var buttonTitle: String {
        switch rideManager.rideState {
        case .idle, .ended:
            return "Start Ride Tracking"
        case .active:
            return "Pause Ride Tracking"
        case .paused:
            return "Resume Ride"
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch rideManager.rideState {
        case .idle, .ended:
            // Light mode: black bg, Dark mode: yellow bg
            return colorScheme == .light ? Color.black : Color.yellow
        case .active:
            // Orange for active state
            return Color.orange
        case .paused:
            // Green for paused/resume state
            return Color.green
        }
    }
    
    private var buttonTextColor: Color {
        switch rideManager.rideState {
        case .idle, .ended:
            // Light mode: yellow text, Dark mode: black text
            return colorScheme == .light ? Color.yellow : Color.black
        case .active:
            // White text on orange
            return Color.white
        case .paused:
            // White text on green
            return Color.white
        }
    }
    
    private var shouldShowGlow: Bool {
        rideManager.rideState == .active
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        switch rideManager.rideState {
        case .idle:
            if rideManager.isGroupRide {
                onStartGroup()
            } else {
                onStartSolo()
            }
        case .active:
            rideManager.pauseRide()
        case .paused:
            rideManager.resumeRide()
        case .ended:
            rideManager.resetRide()
            if rideManager.isGroupRide {
                onStartGroup()
            } else {
                onStartSolo()
            }
        }
    }
    
    private func startHoldTimer() {
        isHolding = true
        holdProgress = 0.0
        
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] timer in
            holdProgress += 0.02
            if holdProgress >= 1.0 {
                timer.invalidate()
                handleLongPress()
            }
        }
    }
    
    private func handleLongPress() {
        holdTimer?.invalidate()
        isHolding = false
        holdProgress = 0.0
        
        // Phase 35.3: Instant stop - no countdown
        if rideManager.rideState == .active || rideManager.rideState == .paused {
            rideManager.endRide()
            VoiceFeedbackService.shared.speak("Ride stopped, saved to calendar")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}


