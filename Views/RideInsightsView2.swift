//
//  RideInsightsView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI

/// View displaying AI-powered ride insights and goal recommendations
struct LegacyRideInsightsView: View {
    
    // MARK: - Properties
    let ride: RideRecord
    let insight: AIInsightService.RideInsight
    let achievementTracker: AchievementTracker
    let onDismiss: () -> Void
    
    // MARK: - Animation Properties
    @State private var showContent = false
    @State private var animatedStreak = 0
    @State private var animatedImprovement = 0.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Ride Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Here's how you did")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    
                    // Ride Summary Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "bicycle")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Text("Ride Summary")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Distance")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(ride.formattedDistance)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Duration")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(ride.formattedDuration)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Average Speed")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(ride.formattedAverageSpeed)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Date")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(ride.formattedDate)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // AI Insights Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("AI Insights")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            Text(insight.summary)
                                .font(.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(insight.comparison)
                                .font(.body)
                                .foregroundColor(.green)
                                .multilineTextAlignment(.center)
                            
                            if insight.improvementPercent > 0 {
                                HStack {
                                    Text("Improvement:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("+\(String(format: "%.1f", animatedImprovement))%")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Next Goal Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "target")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            Text("Next Goal")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        Text(insight.nextGoal)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Streak Card
                    if let streakMessage = insight.streakMessage {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                
                                Text("Streak")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            Text(streakMessage)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Achievement Badge
                    if let achievementBadge = insight.achievementBadge {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                Text("Achievement")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            Text(achievementBadge)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Done Button
                    Button(action: onDismiss) {
                        Text("Done")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
        }
        .opacity(showContent ? 1 : 0)
        .onAppear {
            animateContent()
        }
    }
    
    // MARK: - Private Methods
    
    private func animateContent() {
        withAnimation(.easeInOut(duration: 0.6)) {
            showContent = true
        }
        
        // Animate streak counter
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            animatedStreak = achievementTracker.currentStreakDays
        }
        
        // Animate improvement percentage
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            animatedImprovement = insight.improvementPercent
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleRide = RideRecord(
        distance: 6400, // 6.4 km
        duration: 1920, // 32 minutes
        averageSpeed: 5.5, // ~20 km/h
        route: []
    )
    
    let sampleInsight = AIInsightService.RideInsight(
        summary: "You rode 6.4 km in 32 min — excellent pace!",
        comparison: "You went 0.8 km farther than your last ride!",
        nextGoal: "🚀 Goal: 6.9 km next ride",
        improvementPercent: 12.5,
        streakMessage: "🔥 3 days strong!",
        achievementBadge: "⭐ Distance Explorer"
    )
    
    return LegacyRideInsightsView(
        ride: sampleRide,
        insight: sampleInsight,
        achievementTracker: AchievementTracker(),
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
