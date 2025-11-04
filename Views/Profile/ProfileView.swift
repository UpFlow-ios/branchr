//
//  ProfileView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 21 - User Profile with Editable Image, Name, and Bio
//

import SwiftUI
import PhotosUI

/**
 * 👤 Profile View
 *
 * User profile management with:
 * - Editable profile image (photo picker)
 * - Editable name
 * - Editable bio
 * - Persistent storage using @AppStorage
 */
struct ProfileView: View {
    
    @AppStorage("userName") private var userName: String = "Rider"
    @AppStorage("userBio") private var userBio: String = "Let's ride together!"
    @AppStorage("profileImageData") private var profileImageData: Data?
    
    @State private var showingImagePicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section
                    VStack(spacing: 12) {
                        if let data = profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(theme.accentColor, lineWidth: 3)
                                )
                                .shadow(color: theme.accentColor.opacity(0.3), radius: 10, x: 0, y: 4)
                                .onTapGesture {
                                    showingImagePicker = true
                                }
                        } else {
                            Circle()
                                .fill(theme.cardBackground)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(theme.accentColor)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(theme.accentColor.opacity(0.3), lineWidth: 2)
                                )
                                .onTapGesture {
                                    showingImagePicker = true
                                }
                        }
                        
                        Text("Tap to change photo")
                            .font(.caption)
                            .foregroundColor(theme.primaryText.opacity(0.7))
                    }
                    .padding(.top, 40)
                    
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        
                        TextField("Enter your name", text: $userName)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(theme.primaryText)
                            .padding()
                            .background(theme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(theme.accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Bio Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        
                        ZStack(alignment: .topLeading) {
                            if userBio.isEmpty {
                                Text("Tell us about yourself...")
                                    .font(.body)
                                    .foregroundColor(theme.primaryText.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $userBio)
                                .font(.body)
                                .foregroundColor(theme.primaryText)
                                .frame(height: 120)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(theme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(theme.accentColor.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Stats Section (Optional - can be expanded later)
                    VStack(spacing: 16) {
                        Text("Stats")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        
                        HStack(spacing: 20) {
                            StatItem(title: "Rides", value: "0")
                            StatItem(title: "Distance", value: "0 mi")
                            StatItem(title: "Time", value: "0h")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(
                isPresented: $showingImagePicker,
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        profileImageData = data
                    }
                }
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
                .foregroundColor(theme.accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.primaryText.opacity(0.7))
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

