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
            }
        }
    }
}
