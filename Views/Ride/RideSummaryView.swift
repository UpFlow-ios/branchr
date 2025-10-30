//
//  RideSummaryView.swift
//  branchr
//
//  Created by Joe Dormond on 10/23/25.
//

import SwiftUI
import MapKit

/// Summary view showing ride results after tracking stops
struct RideSummaryView: View {
    
    // MARK: - Properties
    let ride: RideRecord
    let rideDataManager: RideDataManager
    let onDismiss: () -> Void
    
    @State private var region: MKCoordinateRegion
    @State private var showingEditTitle = false
    @State private var customTitle = ""
    @State private var showingInsights = false
    @StateObject private var aiInsightService = AIInsightService()
    @StateObject private var achievementTracker = AchievementTracker()
    @StateObject private var calorieCalculator = CalorieCalculator()
    @StateObject private var voiceAssistant = VoiceAssistantService()
    @StateObject private var preferenceManager = UserPreferenceManager.shared
    
    // MARK: - Initialization
    init(ride: RideRecord, rideDataManager: RideDataManager, onDismiss: @escaping () -> Void) {
        self.ride = ride
        self.rideDataManager = rideDataManager
        self.onDismiss = onDismiss
        
        // Set up map region to show the entire route
        if let firstCoordinate = ride.coordinateRoute.first {
            let minLat = ride.coordinateRoute.map { $0.latitude }.min() ?? firstCoordinate.latitude
            let maxLat = ride.coordinateRoute.map { $0.latitude }.max() ?? firstCoordinate.latitude
            let minLon = ride.coordinateRoute.map { $0.longitude }.min() ?? firstCoordinate.longitude
            let maxLon = ride.coordinateRoute.map { $0.longitude }.max() ?? firstCoordinate.longitude
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: max(maxLat - minLat, 0.001) * 1.2,
                longitudeDelta: max(maxLon - minLon, 0.001) * 1.2
            )
            
            self._region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        } else {
            self._region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
        
        self._customTitle = State(initialValue: ride.title ?? "")
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Ride Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(ride.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    
                    // Route Map
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Route")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Map(coordinateRegion: $region, 
                            interactionModes: [.pan, .zoom],
                            annotationItems: ride.coordinateRoute.isEmpty ? [] : [MapAnnotation(coordinate: ride.coordinateRoute.first!)]) { location in
                            MapPin(coordinate: location.coordinate, tint: .green)
                        }
                        .overlay(
                            MapPolylineOverlay(coordinates: ride.coordinateRoute)
                        )
                        .frame(height: 200)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    // Stats Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(
                            title: "Distance",
                            value: ride.formattedDistance,
                            icon: "location.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Duration",
                            value: ride.formattedDuration,
                            icon: "clock.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Avg Speed",
                            value: ride.formattedAverageSpeed,
                            icon: "speedometer",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Points",
                            value: "\(ride.coordinateRoute.count)",
                            icon: "point.3.connected.trianglepath.dotted",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Title Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ride Title")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                showingEditTitle = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text(ride.displayTitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showingInsights = true
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text("View AI Insights")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: {
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Done")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: {
                            rideDataManager.deleteRide(ride)
                            onDismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Ride")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingEditTitle) {
            EditTitleSheet(
                title: $customTitle,
                onSave: {
                    // Update the ride title in the data manager
                    if let index = rideDataManager.rides.firstIndex(where: { $0.id == ride.id }) {
                        rideDataManager.rides[index].title = customTitle.isEmpty ? nil : customTitle
                    }
                }
            )
        }
        .sheet(isPresented: $showingInsights) {
            RideInsightsView(
                ride: ride,
                insight: aiInsightService.generateInsights(for: ride, history: rideDataManager.rides),
                achievementTracker: achievementTracker,
                onDismiss: {
                    showingInsights = false
                }
            )
        }
        .onAppear {
            // Update achievement tracker when view appears
            achievementTracker.updateAfterRide(ride)
            
            // Calculate calories if not already set
            if ride.calories == 0 {
                let calculatedCalories = calorieCalculator.calculateCalories(for: ride)
                // Update the ride record with calculated calories
                if let index = rideDataManager.rides.firstIndex(where: { $0.id == ride.id }) {
                    rideDataManager.rides[index].calories = calculatedCalories
                }
            }
            
            // Announce ride summary if voice assistant is enabled
            if preferenceManager.voiceAssistantEnabled {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    voiceAssistant.announceRideEnd(
                        distance: ride.distance,
                        duration: ride.duration,
                        averageSpeed: ride.averageSpeed
                    )
                }
            }
        }
    }
}

// MARK: - EditTitleSheet
struct EditTitleSheet: View {
    @Binding var title: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Ride Title")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextField("Enter ride title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}


#Preview {
    RideSummaryView(
        ride: RideRecord(
            distance: 5000, // 5km
            duration: 1800, // 30 minutes
            averageSpeed: 2.78, // ~10 km/h
            route: [
                CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
            ]
        ),
        rideDataManager: RideDataManager(),
        onDismiss: {}
    )
}
