//
//  EditProfileView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-05
//  Phase 31 - Edit Profile Sheet
//

import SwiftUI
import FirebaseAuth

/**
 * ✏️ Edit Profile View
 *
 * Sheet view for editing user profile:
 * - Change profile photo
 * - Edit name and bio
 * - Save to Firebase Firestore + Storage
 */
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var service = FirebaseProfileService.shared
    @ObservedObject var profileManager = ProfileManager.shared // Phase 33: Local persistence
    @State private var name: String
    @State private var bio: String
    @State private var photoURL: String?
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @ObservedObject private var theme = ThemeManager.shared
    
    init(profile: UserProfile) {
        // Phase 33: Initialize from ProfileManager if available, otherwise from profile
        let manager = ProfileManager.shared
        _name = State(initialValue: manager.name.isEmpty ? profile.name : manager.name)
        _bio = State(initialValue: manager.bio.isEmpty ? profile.bio : manager.bio)
        _photoURL = State(initialValue: profile.photoURL)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Photo Section
                Section(header: Text("Profile Photo")) {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            if let img = selectedImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else if let photoURL = photoURL, let url = URL(string: photoURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(theme.secondaryText)
                                }
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(theme.secondaryText)
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(theme.accentColor, lineWidth: 2))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Details Section
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(theme.accentColor)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, imageData: .constant(nil))
            }
        }
    }
    
    // MARK: - Save Profile
    
    private func saveProfile() {
        // Phase 33: Save to ProfileManager for local persistence
        profileManager.save(name: name, bio: bio, image: selectedImage)
        
        // Also sync to Firebase if signed in
        if let uid = Auth.auth().currentUser?.uid {
            let updatedProfile = UserProfile(
                id: service.currentProfile.id ?? uid,
                name: name,
                bio: bio,
                photoURL: photoURL,
                isOnline: service.currentProfile.isOnline,
                updatedAt: Date(),
                uid: uid
            )
            
            service.updateProfile(updatedProfile, image: selectedImage)
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    EditProfileView(profile: UserProfile.placeholder)
        .preferredColorScheme(.dark)
}

