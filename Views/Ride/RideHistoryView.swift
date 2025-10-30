//
//  RideHistoryView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI

/// History view showing all saved rides
struct RideHistoryView: View {
    
    // MARK: - Properties
    @ObservedObject var rideDataManager: RideDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRide: RideRecord?
    @State private var showingSummary = false
    @State private var showingClearAlert = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if rideDataManager.rides.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "bicycle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Rides Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Start tracking your first ride!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    // Rides list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(rideDataManager.rides) { ride in
                                RideCard(ride: ride) {
                                    selectedRide = ride
                                    showingSummary = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Ride History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !rideDataManager.rides.isEmpty {
                        Button(action: {
                            showingClearAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSummary) {
            if let ride = selectedRide {
                RideSummaryView(
                    ride: ride,
                    rideDataManager: rideDataManager,
                    onDismiss: {
                        showingSummary = false
                        selectedRide = nil
                    }
                )
            }
        }
        .alert("Clear All Rides", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                rideDataManager.clearAll()
            }
        } message: {
            Text("This will permanently delete all saved rides. This action cannot be undone.")
        }
    }
}

// MARK: - RideCard Component
struct RideCard: View {
    let ride: RideRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Ride icon
                VStack {
                    Image(systemName: "bicycle")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("\(ride.coordinateRoute.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 50)
                
                // Ride details
                VStack(alignment: .leading, spacing: 4) {
                    Text(ride.displayTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(ride.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 16) {
                        Label(ride.formattedDistance, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Label(ride.formattedDuration, systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Label(ride.formattedAverageSpeed, systemImage: "speedometer")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Summary Stats View
struct SummaryStatsView: View {
    let rideDataManager: RideDataManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Total Stats")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(rideDataManager.rideCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Rides")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text(formatTotalDistance(rideDataManager.totalDistance))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text(formatTotalDuration(rideDataManager.totalDuration))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatTotalDistance(_ distance: Double) -> String {
        let locale = Locale.current
        let isMetric = locale.usesMetricSystem
        
        if isMetric {
            return String(format: "%.1f km", distance / 1000.0)
        } else {
            return String(format: "%.1f mi", distance * 0.000621371)
        }
    }
    
    private func formatTotalDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
}

#Preview {
    RideHistoryView(rideDataManager: RideDataManager())
}
