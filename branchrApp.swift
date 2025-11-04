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
        // Phase 22: Initialize Firebase
        FirebaseApp.configure()
        print("☁️ Firebase initialized successfully")
        
        // Validate MusicKit access on app launch
        // This will configure MusicKit and request user authorization
        MusicKitService.validateMusicKitAccess()
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
                        // Phase 23: Set user online when app appears
                        FirebaseService.shared.setUserOnlineStatus(isOnline: true)
                    }
                    .onDisappear {
                        // Phase 23: Set user offline when app disappears
                        FirebaseService.shared.setUserOnlineStatus(isOnline: false)
                    }
                    .onChange(of: scenePhase) { phase in
                        // Phase 23: Update online status based on app state
                        FirebaseService.shared.setUserOnlineStatus(isOnline: phase == .active)
                    }
            }
        }
    }
}
