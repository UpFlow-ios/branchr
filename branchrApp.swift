//
//  branchrApp.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct branchrApp: App {
    @State private var showLaunchAnimation = true
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Phase 22: Initialize Firebase with explicit configuration
        configureFirebase()
        
        // Validate MusicKit access on app launch
        // This will configure MusicKit and request user authorization
        MusicKitService.validateMusicKitAccess()
    }
    
    // MARK: - Firebase Configuration
    
    private func configureFirebase() {
        // Prevent multiple configs
        guard FirebaseApp.app() == nil else {
            print("☁️ Firebase already configured")
            return
        }
        
        // Try to find the plist file with explicit path
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
            print("☁️ Firebase initialized successfully with explicit plist path: \(filePath)")
        } else {
            // Fallback to default configuration
            FirebaseApp.configure()
            print("☁️ Firebase initialized with default configuration (plist auto-detected)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if showLaunchAnimation {
                LaunchAnimationView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showLaunchAnimation = false
                    }
                }
            } else {
                BranchrAppRoot() // ✅ Official app root with tabs, FAB, and theme
                    .onAppear {
                        // Phase 23: Set user online when app appears (only if signed in)
                        if Auth.auth().currentUser != nil {
                            FirebaseService.shared.setUserOnlineStatus(isOnline: true)
                        }
                    }
                    .onDisappear {
                        // Phase 23: Set user offline when app disappears (only if signed in)
                        if Auth.auth().currentUser != nil {
                            FirebaseService.shared.setUserOnlineStatus(isOnline: false)
                        }
                    }
                    .onChange(of: scenePhase) { phase in
                        // Phase 23: Update online status based on app state (only if signed in)
                        if Auth.auth().currentUser != nil {
                            FirebaseService.shared.setUserOnlineStatus(isOnline: phase == .active)
                        }
                    }
            }
        }
    }
}
