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
                    .padding(.top, 60)
                    
                    // Name
                    Text(profileManager.name.isEmpty ? profileService.currentProfile.name : profileManager.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.branchrTextPrimary)
                    
                    // Bio
                    Text(profileManager.bio.isEmpty ? profileService.currentProfile.bio : profileManager.bio)
                        .font(.body)
                        .foregroundColor(Color.branchrTextPrimary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Phase 34: Stats moved up (above Edit button)
                    HStack(spacing: 20) {
                        StatItem(title: "Rides", value: "0")
                        StatItem(title: "Distance", value: "0 mi")
                        StatItem(title: "Time", value: "0h")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
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
                    .padding(.bottom, 20)
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

struct StatItem: View {
    let title: String
    let value: String
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(Color.branchrAccent)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.branchrTextPrimary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
