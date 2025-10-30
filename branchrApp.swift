//
//  branchrApp.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import SwiftUI

@main
struct branchrApp: App {
    @State private var showLaunchAnimation = true
    
    init() {
        // Initialize MusicKit JWT token generation
        Task {
            do {
                let token = try MusicKitService.shared.generateDeveloperToken()
                print("🎵 Developer Token Generated: \(token.prefix(60))...")
            } catch {
                print("❌ MusicKit token generation failed:", error.localizedDescription)
            }
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
            }
        }
    }
}
