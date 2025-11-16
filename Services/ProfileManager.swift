//
//  ProfileManager.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-05
//  Phase 33 - Profile Persistence Manager
//

import Foundation
import SwiftUI
import UIKit
import FirebaseAuth

/**
 * 👤 Profile Manager
 *
 * Handles local persistence of profile data:
 * - Name
 * - Bio
 * - Profile photo (as Data)
 * - Syncs with Firebase when available
 */
final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var name: String = ""
    @Published var bio: String = ""
    @Published var imageData: Data?
    
    private init() {
        load()
        print("👤 ProfileManager initialized")
    }
    
    // MARK: - Load Profile
    
    /// Load profile data from UserDefaults
    func load() {
        let defaults = UserDefaults.standard
        name = defaults.string(forKey: "profile_name") ?? ""
        bio = defaults.string(forKey: "profile_bio") ?? ""
        imageData = defaults.data(forKey: "profile_image")
        
        print("👤 ProfileManager: Loaded profile - name: \(name.isEmpty ? "empty" : name)")
    }
    
    // MARK: - Save Profile
    
    /// Save profile data to UserDefaults and optionally sync to Firebase
    func save(name: String?, bio: String?, image: UIImage?) {
        let defaults = UserDefaults.standard
        
        if let name = name {
            self.name = name
            defaults.set(name, forKey: "profile_name")
        }
        
        if let bio = bio {
            self.bio = bio
            defaults.set(bio, forKey: "profile_bio")
        }
        
        if let image = image,
           let data = image.jpegData(compressionQuality: 0.8) {
            self.imageData = data
            defaults.set(data, forKey: "profile_image")
        }
        
        defaults.synchronize()
        
        // Phase 33: Sync to Firebase if user is signed in
        if let userID = Auth.auth().currentUser?.uid {
            Task { @MainActor in
                if let image = image {
                    FirebaseService.shared.uploadProfilePhoto(image, userID: userID) { url in
                        Task { @MainActor in
                            if let url = url {
                                FirebaseService.shared.saveUserProfile(
                                    userID: userID,
                                    name: self.name,
                                    bio: self.bio,
                                    photoURL: url
                                )
                            }
                        }
                    }
                } else {
                    FirebaseService.shared.saveUserProfile(
                        userID: userID,
                        name: self.name,
                        bio: self.bio,
                        photoURL: nil
                    )
                }
            }
        }
        
        print("✅ ProfileManager: Saved profile data")
    }
    
    // MARK: - Phase 4: Profile Image Helper
    
    /**
     * Get profile image for a user ID
     * Phase 4: Returns UIImage from stored imageData
     */
    func profileImageFor(id: String) -> UIImage? {
        // Phase 4: For now, return current user's profile image
        // In a full implementation, this would look up other users' profiles
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
    
    // MARK: - Phase 5: Current User Helpers
    
    /**
     * Get current user's display name
     * Phase 5: Returns name or fallback to "You"
     */
    var currentDisplayName: String {
        return name.isEmpty ? "You" : name
    }
    
    /**
     * Get current user's profile image
     * Phase 5: Returns UIImage from stored imageData
     */
    var currentProfileImage: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
}

