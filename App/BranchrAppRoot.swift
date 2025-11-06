//
//  BranchrAppRoot.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//  This is the visual skeleton / main shell of the entire app.
//

import SwiftUI

struct BranchrAppRoot: View {
    @ObservedObject var theme = ThemeManager.shared
    
    @StateObject private var musicSync = MusicSyncService()
    @StateObject private var songRequests = SongRequestManager()
    
    @State private var selectedTab: Int = 0
    @State private var showDJControls = false
    
    // Lazy initialization for hostDJ
    private var hostDJ: HostDJController {
        HostDJController(musicSync: musicSync, songRequests: songRequests)
    }
    
    var body: some View {
        // Main TabView with 4 tabs
        TabView(selection: $selectedTab) {
                
                // Tab 1: Home
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                
                // Phase 31: Ride tab removed - functionality moved to HomeView
                
                // Tab 2: Voice
                NavigationStack {
                    VoiceSettingsView()
                }
                .tabItem {
                    Image(systemName: "waveform.circle.fill")
                    Text("Voice")
                }
                .tag(1)
                
                // Tab 3: Profile (Phase 21)
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(2)
                
                // Tab 4: Settings
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
            }
            .tint(theme.primaryButton)
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
        .background(theme.primaryBackground.ignoresSafeArea())
        .sheet(isPresented: $showDJControls) {
            DJControlView(dj: hostDJ, musicSync: musicSync, songRequests: songRequests)
        }
    }
}

