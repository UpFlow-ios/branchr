//
//  FirebaseService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 22 - Firebase Integration (Firestore + Storage + Auth)
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
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
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    private init() {
        print("☁️ FirebaseService initialized")
    }
    
    // MARK: - Upload Profile Photo
    
    /// Upload profile photo to Firebase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - userID: Firebase user ID
    ///   - completion: Callback with photo URL string or nil on error
    func uploadProfilePhoto(_ image: UIImage, userID: String, completion: @escaping (String?) -> Void) {
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
    }
    
    // MARK: - Save Profile Data
    
    /// Save user profile to Firestore
    /// - Parameters:
    ///   - userID: Firebase user ID
    ///   - name: User's display name
    ///   - bio: User's bio
    ///   - photoURL: Optional photo URL from Storage
    func saveUserProfile(userID: String, name: String, bio: String, photoURL: String?) {
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
    }
    
    // MARK: - Fetch Profiles
    
    /// Fetch all user profiles from Firestore
    /// - Parameter completion: Callback with array of UserProfile objects
    func fetchAllProfiles(completion: @escaping ([UserProfile]) -> Void) {
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
                let data = doc.data()
                return UserProfile(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    photoURL: data["photoURL"] as? String ?? "",
                    isOnline: data["isOnline"] as? Bool ?? false,
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
                )
            }
            
            print("✅ Firebase: Fetched \(profiles.count) profiles")
            completion(profiles)
        }
    }
    
    /// Fetch a specific user's profile
    /// - Parameters:
    ///   - userID: Firebase user ID
    ///   - completion: Callback with UserProfile or nil
    func fetchUserProfile(userID: String, completion: @escaping (UserProfile?) -> Void) {
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
            
            let data = snapshot.data() ?? [:]
            let profile = UserProfile(
                id: snapshot.documentID,
                name: data["name"] as? String ?? "",
                bio: data["bio"] as? String ?? "",
                photoURL: data["photoURL"] as? String ?? "",
                isOnline: data["isOnline"] as? Bool ?? false,
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
            )
            completion(profile)
        }
    }
    
    // MARK: - Phase 23: Online Presence
    
    /// Set user's online/offline status
    func setUserOnlineStatus(isOnline: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ Firebase: Cannot set online status - no user signed in")
            return
        }
        
        let data: [String: Any] = [
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: Date())
        ]
        
        db.collection("users").document(uid).setData(data, merge: true) { error in
            if let error = error {
                print("❌ Firebase: Failed to set online status: \(error.localizedDescription)")
            } else {
                print("\(isOnline ? "🟢" : "⚫") Firebase: User \(isOnline ? "is online" : "went offline")")
            }
        }
    }
    
    /// Listen for real-time presence updates from all users
    /// - Parameter completion: Callback with array of online/offline user profiles
    /// - Returns: ListenerRegistration to stop listening when needed
    func observeOnlineUsers(completion: @escaping ([UserProfile]) -> Void) -> ListenerRegistration {
        print("☁️ Firebase: Presence listener active")
        
        return db.collection("users").addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Firebase: Presence listener error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let docs = snapshot?.documents else {
                completion([])
                return
            }
            
            let users = docs.compactMap { doc -> UserProfile? in
                let data = doc.data()
                return UserProfile(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    photoURL: data["photoURL"] as? String ?? "",
                    isOnline: data["isOnline"] as? Bool ?? false,
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
                )
            }
            
            completion(users)
        }
    }
}

// MARK: - User Profile Model

struct UserProfile: Codable, Identifiable {
    var id: String?
    let name: String
    let bio: String
    let photoURL: String?
    var isOnline: Bool = false // Phase 23: Online presence
    let updatedAt: Date?
    let uid: String? // Phase 31: Firebase user ID
    
    // Phase 31: Placeholder for new users
    static var placeholder: UserProfile {
        UserProfile(
            id: nil,
            name: "New Rider",
            bio: "Tap to customize your profile",
            photoURL: nil,
            isOnline: false,
            updatedAt: nil,
            uid: nil
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bio
        case photoURL
        case isOnline
        case updatedAt
        case uid
    }
    
    // Phase 31: Convenience initializer
    init(id: String? = nil, name: String, bio: String, photoURL: String?, isOnline: Bool = false, updatedAt: Date? = nil, uid: String? = nil) {
        self.id = id
        self.name = name
        self.bio = bio
        self.photoURL = photoURL
        self.isOnline = isOnline
        self.updatedAt = updatedAt
        self.uid = uid
    }
}

