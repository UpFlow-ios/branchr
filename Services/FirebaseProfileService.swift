//
//  FirebaseProfileService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-05
//  Phase 31 - Firebase Profile Sync Service
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

/**
 * 👤 Firebase Profile Service
 *
 * Handles:
 * - Real-time profile sync with Firestore
 * - Profile photo uploads to Firebase Storage
 * - Profile data fetching and updates
 */
@MainActor
final class FirebaseProfileService: ObservableObject {
    static let shared = FirebaseProfileService()
    
    @Published var currentProfile: UserProfile = .placeholder
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    private init() {
        print("👤 FirebaseProfileService initialized")
    }
    
    // MARK: - Fetch Profile
    
    /// Fetch user profile from Firestore
    func fetchProfile(uid: String) {
        db.collection("profiles").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ FirebaseProfileService: Failed to fetch profile: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("⚠️ FirebaseProfileService: Profile not found for user: \(uid)")
                // Create default profile if doesn't exist
                self.createDefaultProfile(uid: uid)
                return
            }
            
            let profile = UserProfile(
                id: snapshot?.documentID,
                name: data["name"] as? String ?? "New Rider",
                bio: data["bio"] as? String ?? "Tap to customize your profile",
                photoURL: data["photoURL"] as? String,
                isOnline: data["isOnline"] as? Bool ?? false,
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue(),
                uid: uid
            )
            self.currentProfile = profile
            print("✅ FirebaseProfileService: Profile loaded for \(uid)")
        }
    }
    
    /// Create default profile for new user (Phase 34: Made public for app initialization)
    func createDefaultProfile(uid: String) {
        let defaultProfile = UserProfile(
            id: uid,
            name: "New Rider",
            bio: "Tap to customize your profile",
            photoURL: nil,
            isOnline: false,
            updatedAt: Date(),
            uid: uid
        )
        updateProfile(defaultProfile, image: nil)
    }
    
    // MARK: - Update Profile
    
    /// Update profile in Firestore and upload photo if provided
    func updateProfile(_ profile: UserProfile, image: UIImage?) {
        guard let uid = profile.uid else {
            print("⚠️ FirebaseProfileService: Cannot update profile - no uid")
            return
        }
        
        var data: [String: Any] = [
            "name": profile.name,
            "bio": profile.bio,
            "uid": uid,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Upload image if provided
        if let image = image {
            uploadProfilePhoto(image, uid: uid) { [weak self] photoURL in
                guard let self = self else { return }
                if let photoURL = photoURL {
                    data["photoURL"] = photoURL
                    let updatedProfile = UserProfile(
                        id: profile.id,
                        name: profile.name,
                        bio: profile.bio,
                        photoURL: photoURL,
                        isOnline: profile.isOnline,
                        updatedAt: Date(),
                        uid: uid
                    )
                    self.currentProfile = updatedProfile
                }
                self.saveProfileData(uid: uid, data: data)
            }
        } else {
            // Keep existing photoURL if no new image
            if let existingPhotoURL = profile.photoURL {
                data["photoURL"] = existingPhotoURL
            }
            if let uid = profile.uid {
                saveProfileData(uid: uid, data: data)
                currentProfile = profile
            }
        }
    }
    
    // MARK: - Upload Photo
    
    /// Upload profile photo to Firebase Storage
    private func uploadProfilePhoto(_ image: UIImage, uid: String, completion: @escaping (String?) -> Void) {
        guard !uid.isEmpty else {
            completion(nil)
            return
        }
        guard let imageData = image.pngData() else {
            print("❌ FirebaseProfileService: Failed to convert image to PNG")
            completion(nil)
            return
        }
        
        let ref = storage.child("profiles/\(uid).png")
        
        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ FirebaseProfileService: Upload failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            ref.downloadURL { url, error in
                if let url = url {
                    print("✅ FirebaseProfileService: Photo uploaded: \(url.absoluteString)")
                    completion(url.absoluteString)
                } else {
                    print("❌ FirebaseProfileService: Failed to get download URL: \(error?.localizedDescription ?? "unknown")")
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Save Profile Data
    
    /// Save profile data to Firestore
    private func saveProfileData(uid: String, data: [String: Any]) {
        db.collection("profiles").document(uid).setData(data, merge: true) { error in
            if let error = error {
                print("❌ FirebaseProfileService: Failed to save profile: \(error.localizedDescription)")
            } else {
                print("✅ FirebaseProfileService: Profile synced with Firestore")
            }
        }
    }
    
    var currentProfileOptional: UserProfile? {
        currentProfile.uid == nil ? nil : currentProfile
    }
}

