//
//  RidePromptView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI

/// View for prompting the user to start ride tracking when motion is detected
struct RidePromptView: View {
    
    // MARK: - Properties
    @ObservedObject var motionService: MotionDetectionService
    @ObservedObject var locationService: LocationTrackingService
    @Binding var isPresented: Bool
    
    // MARK: - Animation Properties
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPrompt()
                }
            
            // Prompt card
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "bicycle")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                // Title
                Text("Looks like you're on a ride!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Subtitle
                Text("Would you like to start tracking this session?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                // Activity info (if available)
                if let activity = motionService.currentActivity {
                    HStack {
                        Image(systemName: activity.cycling ? "bicycle" : "figure.run")
                            .foregroundColor(.blue)
                        
                        Text(motionService.currentActivityDescription)
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(activity.confidence.description.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    // No Thanks button
                    Button(action: {
                        dismissPrompt()
                    }) {
                        Text("No Thanks")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                    
                    // Start Tracking button
                    Button(action: {
                        startTracking()
                    }) {
                        Text("Start Tracking")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            animateIn()
        }
    }
    
    // MARK: - Private Methods
    
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scale = 1.0
            opacity = 1.0
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion()
        }
    }
    
    private func startTracking() {
        // Reset motion detection state
        motionService.resetRideDetection()
        
        // Start location tracking
        locationService.startTracking()
        
        // Dismiss prompt
        animateOut {
            isPresented = false
        }
        
        print("Branchr: User accepted ride tracking prompt")
    }
    
    private func dismissPrompt() {
        // Reset motion detection state
        motionService.resetRideDetection()
        
        // Dismiss prompt
        animateOut {
            isPresented = false
        }
        
        print("Branchr: User declined ride tracking prompt")
    }
}

// MARK: - Preview
#Preview {
    RidePromptView(
        motionService: MotionDetectionService(),
        locationService: LocationTrackingService(),
        isPresented: .constant(true)
    )
    .preferredColorScheme(.dark)
}
