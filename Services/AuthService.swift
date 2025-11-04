//
//  AuthService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 22 - Firebase Authentication (Apple ID Sign-In)
//

import Foundation
// Phase 22: Uncomment after adding Firebase Swift Packages
// import FirebaseAuth
import AuthenticationServices
import SwiftUI

/**
 * 🔐 Authentication Service
 *
 * Handles:
 * - Apple ID sign-in via Firebase Auth
 * - User session management
 * - Sign out functionality
 */
@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    // Phase 22: Uncomment after adding Firebase packages
    // @Published var user: User? = Auth.auth().currentUser
    @Published var user: Any? = nil // Placeholder until Firebase added
    @Published var isAuthenticated: Bool = false
    
    private override init() {
        super.init()
        
        // Phase 22: Uncomment after adding Firebase packages
        print("🔓 AuthService: Firebase packages not yet added")
        
        /*
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                if let user = user {
                    print("✅ AuthService: User signed in - \(user.uid)")
                } else {
                    print("🔓 AuthService: User signed out")
                }
            }
        }
        
        // Check initial state
        if let user = Auth.auth().currentUser {
            self.user = user
            self.isAuthenticated = true
            print("✅ AuthService: User already signed in - \(user.uid)")
        } else {
            print("🔓 AuthService: No user signed in")
        }
        */
    }
    
    // MARK: - Apple ID Sign-In
    
    /// Sign in with Apple ID
    /// - Parameter credential: ASAuthorizationAppleIDCredential from Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        // Phase 22: Uncomment after adding Firebase packages
        print("⚠️ AuthService: Firebase packages not yet added - sign-in skipped")
        
        /*
        guard let tokenData = credential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            print("❌ AuthService: Failed to get identity token")
            return
        }
        
        let firebaseCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: tokenString,
            rawNonce: nil
        )
        
        Auth.auth().signIn(with: firebaseCredential) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ AuthService: Sign-in error: \(error.localizedDescription)")
                    return
                }
                
                guard let user = result?.user else {
                    print("❌ AuthService: No user returned from sign-in")
                    return
                }
                
                self?.user = user
                self?.isAuthenticated = true
                print("✅ AuthService: Signed in successfully as: \(user.uid)")
                print("   Email: \(user.email ?? "no email")")
                print("   Display Name: \(user.displayName ?? "no name")")
            }
        }
        */
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() {
        // Phase 22: Uncomment after adding Firebase packages
        print("⚠️ AuthService: Firebase packages not yet added - sign-out skipped")
        user = nil
        isAuthenticated = false
        
        /*
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
            print("✅ AuthService: User signed out successfully")
        } catch {
            print("❌ AuthService: Sign-out error: \(error.localizedDescription)")
        }
        */
    }
    
    // MARK: - User Info Helpers
    
    /// Get current user ID
    var currentUserID: String? {
        // Phase 22: Uncomment after adding Firebase packages
        // return (user as? User)?.uid
        return nil
    }
    
    /// Get current user email
    var currentUserEmail: String? {
        // Phase 22: Uncomment after adding Firebase packages
        // return (user as? User)?.email
        return nil
    }
}

