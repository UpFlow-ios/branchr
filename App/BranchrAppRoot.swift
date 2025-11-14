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
        // Phase 30: TabView with Home, Calendar, Profile, Settings
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
                
                // Tab 2: Calendar (Phase 30)
                NavigationStack {
                    RideCalendarView()
                }
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(1)
                
                // Tab 3: Profile (Phase 31: Shows profile photo on tab bar)
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    // Phase 31: Show profile photo on tab bar if available
                    ProfileTabIconView()
                    Text("Profile")
                }
                .tag(2)
                
                // Tab 4: Settings (Phase 30: Now includes Voice & Audio)
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
            }
            .tint(theme.branchrBlack)
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            .background(theme.primaryBackground.ignoresSafeArea())
        .sheet(isPresented: $showDJControls) {
            DJControlView(dj: hostDJ, musicSync: musicSync, songRequests: songRequests)
        }
    }
}

