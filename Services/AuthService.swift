//
//  AuthService.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-03
//  Phase 22 - Firebase Authentication (Apple ID Sign-In)
//

import Foundation
import FirebaseAuth
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
    
    @Published var user: User? = Auth.auth().currentUser
    @Published var isAuthenticated: Bool = false
    
    private override init() {
        super.init()
        
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
    }
    
    // MARK: - Apple ID Sign-In
    
    /// Sign in with Apple ID
    /// - Parameter credential: ASAuthorizationAppleIDCredential from Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard let tokenData = credential.identityToken,
              let tokenString = String(data: tokenData, encoding: .utf8) else {
            print("❌ AuthService: Failed to get identity token")
            return
        }
        
        // Create OAuth credential for Apple Sign-In using async/await
        Task {
            do {
                let provider = OAuthProvider(providerID: "apple.com")
                let firebaseCredential = try await provider.credential(withIDToken: tokenString, rawNonce: nil)
                
                let result = try await Auth.auth().signIn(with: firebaseCredential)
                
                await MainActor.run {
                    self.user = result.user
                    self.isAuthenticated = true
                    print("✅ AuthService: Signed in successfully as: \(result.user.uid)")
                    print("   Email: \(result.user.email ?? "no email")")
                    print("   Display Name: \(result.user.displayName ?? "no name")")
                }
            } catch {
                await MainActor.run {
                    print("❌ AuthService: Sign-in error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
            print("✅ AuthService: User signed out successfully")
        } catch {
            print("❌ AuthService: Sign-out error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - User Info Helpers
    
    /// Get current user ID
    var currentUserID: String? {
        return user?.uid
    }
    
    /// Get current user email
    var currentUserEmail: String? {
        return user?.email
    }
}

