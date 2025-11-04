//
//  FirebaseService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 22 - Firebase Integration (Firestore + Storage + Auth)
//

import Foundation
// Phase 22: Uncomment after adding Firebase Swift Packages
// import FirebaseCore
// import FirebaseFirestore
// import FirebaseStorage
import UIKit

/**
 * ☁️ Firebase Service
 *
 * Handles:
 * - Profile photo uploads to Firebase Storage
 * - User profile data in Firestore
 * - Fetching profiles for connected riders
 */
@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    // Phase 22: Uncomment after adding Firebase packages
    // private let db = Firestore.firestore()
    // private let storage = Storage.storage().reference()
    
    private init() {
        print("☁️ FirebaseService initialized (packages not yet added)")
    }
    
    // MARK: - Upload Profile Photo
    
    /// Upload profile photo to Firebase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - userID: Firebase user ID
    ///   - completion: Callback with photo URL string or nil on error
    func uploadProfilePhoto(_ image: UIImage, userID: String, completion: @escaping (String?) -> Void) {
        // Phase 22: Uncomment after adding Firebase packages
        print("⚠️ Firebase: Packages not yet added - upload skipped")
        completion(nil)
        
        /*
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Firebase: Failed to convert image to JPEG")
            completion(nil)
            return
        }
        
        let path = "profilePhotos/\(userID).jpg"
        let ref = storage.child(path)
        
        ref.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ Firebase: Upload failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Get download URL
            ref.downloadURL { url, error in
                if let url = url {
                    print("✅ Firebase: Photo uploaded successfully: \(url.absoluteString)")
                    completion(url.absoluteString)
                } else {
                    print("❌ Firebase: Failed to get download URL: \(error?.localizedDescription ?? "unknown")")
                    completion(nil)
                }
            }
        }
        */
    }
    
    // MARK: - Save Profile Data
    
    /// Save user profile to Firestore
    /// - Parameters:
    ///   - userID: Firebase user ID
    ///   - name: User's display name
    ///   - bio: User's bio
    ///   - photoURL: Optional photo URL from Storage
    func saveUserProfile(userID: String, name: String, bio: String, photoURL: String?) {
        // Phase 22: Uncomment after adding Firebase packages
        print("⚠️ Firebase: Packages not yet added - save skipped")
        
        /*
        let data: [String: Any] = [
            "name": name,
            "bio": bio,
            "photoURL": photoURL ?? "",
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userID).setData(data, merge: true) { error in
            if let error = error {
                print("❌ Firebase: Failed to save profile: \(error.localizedDescription)")
            } else {
                print("✅ Firebase: Profile saved successfully for user: \(userID)")
            }
        }
        */
    }
    
    // MARK: - Fetch Profiles
    
    /// Fetch all user profiles from Firestore
    /// - Parameter completion: Callback with array of UserProfile objects
    func fetchAllProfiles(completion: @escaping ([UserProfile]) -> Void) {
        // Phase 22: Uncomment after adding Firebase packages
        print("⚠️ Firebase: Packages not yet added - fetch skipped")
        completion([])
        
        /*
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Firebase: Failed to fetch profiles: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("⚠️ Firebase: No profiles found")
                completion([])
                return
            }
            
            let profiles = documents.compactMap { doc -> UserProfile? in
                try? doc.data(as: UserProfile.self)
            }
            
            print("✅ Firebase: Fetched \(profiles.count) profiles")
            completion(profiles)
        }
        */
    }
    
    /// Fetch a specific user's profile
    /// - Parameters:
    ///   - userID: Firebase user ID
    ///   - completion: Callback with UserProfile or nil
    func fetchUserProfile(userID: String, completion: @escaping (UserProfile?) -> Void) {
        // Phase 22: Uncomment after adding Firebase packages
        print("⚠️ Firebase: Packages not yet added - fetch skipped")
        completion(nil)
        
        /*
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Firebase: Failed to fetch profile for \(userID): \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("⚠️ Firebase: Profile not found for user: \(userID)")
                completion(nil)
                return
            }
            
            do {
                let profile = try snapshot.data(as: UserProfile.self)
                completion(profile)
            } catch {
                print("❌ Firebase: Failed to decode profile: \(error.localizedDescription)")
                completion(nil)
            }
        }
        */
    }
}

// MARK: - User Profile Model

struct UserProfile: Codable, Identifiable {
    // Phase 22: Uncomment @DocumentID after adding Firebase packages
    // @DocumentID var id: String?
    var id: String?
    let name: String
    let bio: String
    let photoURL: String
    // Phase 22: Uncomment Timestamp after adding Firebase packages
    // let updatedAt: Timestamp?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bio
        case photoURL
        case updatedAt
    }
}

