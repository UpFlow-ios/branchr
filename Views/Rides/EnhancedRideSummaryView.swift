//
//  EnhancedRideSummaryView.swift
//  branchr
//
//  Created for Phase 35C - Enhanced Ride Summary with Mini Map and Charts
//

import SwiftUI
import MapKit

struct EnhancedRideSummaryView: View {
    let ride: RideRecord
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var rideDataManager = RideDataManager.shared
    @State private var isSaved = false
    @State private var showFadeIn = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {

                // 1. MINI MAP
                if rideHasRoute {
                    RideSummaryMapSection(locations: ride.route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.top, 8)
                } else {
                    noRoutePlaceholder
                }

                // 2. SNAPSHOT
                RideSnapshotRow(
                    distanceMiles: ride.distance / 1609.34, // Convert meters to miles
                    durationSeconds: ride.duration,
                    avgSpeed: ride.averageSpeed * 2.237 // Convert m/s to mph
                )

                // 3. CHARTS / SPARKLINES
                RideChartsSection(
                    speedSamples: [], // TODO: Extract speed samples from ride if available
                    distanceMiles: ride.distance / 1609.34
                )

                // 4. NOTES OR METADATA (optional)
                if let date = ride.date as Date? {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                // 5. ACTION BUTTONS (Phase 35: Liquid Glass with Save/Discard)
                VStack(spacing: 10) {
                    if !isSaved {
                        // Save Ride Button (Liquid Glass)
                        Button {
                            saveRide()
                        } label: {
                            Text("Save Ride")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(colorScheme == .light ? Color.black : Color.yellow)
                                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                                .foregroundStyle(
                                    colorScheme == .light ? Color.yellow : Color.black
                                )
                        }
                        
                        // Discard Ride Button (Liquid Glass)
                        Button {
                            discardRide()
                        } label: {
                            Text("Discard Ride")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                                .foregroundStyle(colorScheme == .light ? Color.primary : Color.white)
                        }
                    } else {
                        // Already saved - show Done button
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(colorScheme == .light ? Color.black : Color.yellow)
                                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                                .foregroundStyle(
                                    colorScheme == .light ? Color.yellow : Color.black
                                )
                        }
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .presentationDetents([.large])
        .opacity(showFadeIn ? 1.0 : 0.0)
        .onAppear {
            // Phase 35: Check if ride is already saved
            isSaved = rideDataManager.rides.contains { $0.id == ride.id }
            
            // Phase 35: Auto-save only rides longer than 5 minutes
            if !isSaved && ride.duration >= 300 {
                saveRide(silent: true)
            }
            
            // Fade-in animation
            withAnimation(.easeIn(duration: 0.4)) {
                showFadeIn = true
            }
        }
    }

    private var rideHasRoute: Bool {
        !ride.route.isEmpty
    }

    @ViewBuilder
    private var noRoutePlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6))
            .frame(height: 160)
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No route recorded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Try on device, not simulator.")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.6))
                }
            )
            .padding(.top, 8)
    }
    
    // MARK: - Phase 35: Save/Discard Actions
    
    private func saveRide(silent: Bool = false) {
        // Check if already saved to avoid duplicates
        guard !rideDataManager.rides.contains(where: { $0.id == ride.id }) else {
            isSaved = true
            return
        }
        
        rideDataManager.saveRide(ride)
        isSaved = true
        
        if !silent {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            VoiceFeedbackService.shared.speak("Ride saved")
        }
        
        // Upload to Firebase
        FirebaseRideService.shared.uploadRide(ride) { error in
            if let error = error {
                print("❌ Failed to upload ride: \(error.localizedDescription)")
            } else {
                print("☁️ Ride synced to Firebase successfully")
            }
        }
        
        // Post notification for calendar refresh
        NotificationCenter.default.post(name: .branchrRidesDidChange, object: nil)
    }
    
    private func discardRide() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        VoiceFeedbackService.shared.speak("Ride discarded")
        dismiss()
    }
}

