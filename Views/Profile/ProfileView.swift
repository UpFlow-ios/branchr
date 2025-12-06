//
//  ProfileView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 21 - User Profile with Editable Image, Name, and Bio
//  Phase 34 - Non-scrollable layout, stats above Edit button, green online ring
//

import SwiftUI
import PhotosUI
import FirebaseAuth

/**
 * 👤 Profile View
 *
 * Phase 34: Non-scrollable layout with:
 * - Stats moved above Edit Profile button
 * - Edit Profile button at bottom
 * - Green online ring around profile photo
 */
struct ProfileView: View {
    
    @ObservedObject private var profileService = FirebaseProfileService.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var presence = PresenceManager.shared // Phase 34: Online presence
    @ObservedObject private var rideDataManager = RideDataManager.shared // Phase 75: Ride stats
    @ObservedObject private var theme = ThemeManager.shared
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Phase 34: Profile Image with Green Online Ring
                    ZStack {
                        // Green ring when online
                        if presence.isOnline {
                            Circle()
                                .stroke(Color.green, lineWidth: 4)
                                .frame(width: 130, height: 130)
                        }
                        
                        // Profile image
                        if let imageData = profileManager.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(theme.accentColor, lineWidth: 2))
                        } else if let photoURL = profileService.currentProfile.photoURL, let url = URL(string: photoURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                                    .tint(theme.accentColor)
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(theme.accentColor, lineWidth: 2))
                        } else {
                            Circle()
                                .fill(theme.cardBackground)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(theme.accentColor)
                                )
                                .overlay(Circle().stroke(theme.accentColor.opacity(0.3), lineWidth: 2))
                        }
                    }
                    .padding(.top, 40) // Phase 75: Reduced from 60 for tighter layout
                    
                    // Name
                    Text(profileManager.name.isEmpty ? profileService.currentProfile.name : profileManager.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.branchrTextPrimary)
                    
                    // Phase 75: Rider tagline
                    Text("\(rideDataManager.totalRideCount) rides • \(String(format: "%.1f mi", rideDataManager.totalDistanceMiles)) total")
                        .font(.footnote)
                        .foregroundColor(Color.branchrTextPrimary.opacity(0.7))
                    
                    // Bio
                    Text(profileManager.bio.isEmpty ? profileService.currentProfile.bio : profileManager.bio)
                        .font(.body)
                        .foregroundColor(Color.branchrTextPrimary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16) // Phase 75: Reduced from 20
                    
                    // Phase 75: Lifetime stats row
                    HStack(spacing: 20) {
                        StatItem(title: "Rides", value: "\(rideDataManager.totalRideCount)")
                        StatItem(title: "Distance", value: String(format: "%.1f mi", rideDataManager.totalDistanceMiles))
                        StatItem(title: "Time", value: rideDataManager.formattedTotalRideTime)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Phase 75: Weekly/Streak stats row
                    HStack(spacing: 20) {
                        StatItem(title: "This Week", value: String(format: "%.1f mi", rideDataManager.totalDistanceThisWeek()))
                        StatItem(title: "Current Streak", value: "\(rideDataManager.currentStreakDays())d")
                        StatItem(title: "Best Streak", value: "\(rideDataManager.bestStreakDays())d")
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Phase 34: Edit Profile button at bottom
                    Button(action: {
                        showEditProfile = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(Color.branchrButtonText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.branchrButtonBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28) // Phase 75: Increased from 20 to match Home button offsets
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profile: profileService.currentProfile)
            }
            .onAppear {
                // Fetch profile when view appears
                if let uid = Auth.auth().currentUser?.uid {
                    profileService.fetchProfile(uid: uid)
                }
                // Phase 34: Update online status
                presence.setOnline(true)
                // Phase 34: Sync profile with GroupSessionManager
                let profileName = profileManager.name.isEmpty ? profileService.currentProfile.name : profileManager.name
                let profileBio = profileManager.bio.isEmpty ? profileService.currentProfile.bio : profileManager.bio
                let profileImage = profileManager.imageData.flatMap { UIImage(data: $0) }
                
                let currentProfile = RiderProfile(
                    name: profileName,
                    bio: profileBio,
                    image: profileImage
                )
                GroupSessionManager.shared.updateProfile(profile: currentProfile)
            }
        }
    }
}

// MARK: - Stat Item Component

// Phase 75: StatItem visual refresh with pro styling
// Fixed: Light mode stats now use black text for high contrast
struct StatItem: View {
    let title: String
    let value: String
    @ObservedObject private var theme = ThemeManager.shared
    
    // Computed colors that adapt to light/dark mode
    private var statValueColor: Color {
        theme.isDarkMode ? theme.branchrYellow : .black
    }
    
    private var statLabelColor: Color {
        theme.isDarkMode ? theme.branchrYellow.opacity(0.7) : Color.black.opacity(0.7)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(statValueColor)
            
            Text(title.uppercased())
                .font(.caption2)
                .tracking(0.8)
                .foregroundColor(statLabelColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.cardBackground)
                .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
        )
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
