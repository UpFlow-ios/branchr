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
    @Environment(\.colorScheme) var colorScheme  // Phase 3B: Use environment colorScheme
    
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
            .tint(theme.isDarkMode ? theme.branchrYellow : theme.branchrBlack)
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            .background(theme.primaryBackground.ignoresSafeArea())
            .onAppear {
                // Phase 3B: Set tab bar appearance with correct background and icon colors
                updateTabBarAppearance()
            }
            .onChange(of: theme.isDarkMode) { _ in
                // Phase 3B: Update tab bar appearance when theme changes
                updateTabBarAppearance()
            }
        .sheet(isPresented: $showDJControls) {
            DJControlView(dj: hostDJ, musicSync: musicSync, songRequests: songRequests)
        }
    }
    
    // FINAL LIQUID GLASS Tab Bar - WWDC Style
    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        // ✨ LIQUID GLASS EFFECT - Ultra-thin material with depth
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        // Subtle dark tint for depth
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        
        // Top inner shadow for depth (using shadow image)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.15)
        
        // Selected state: White 100% + soft glow
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        // Unselected state: White 55%
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.55)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.55),
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]

        // Apply to global appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Set tab bar height via frame (94pt)
        UITabBar.appearance().frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 94)
        
        // Apply directly to existing tab bars
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.rootViewController?.findTabBar()?.applyAppearance(appearance)
                }
            }
        }
    }
}

// Extension to find UITabBar in view hierarchy
extension UIViewController {
    func findTabBar() -> UITabBar? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController.tabBar
        }
        for child in children {
            if let tabBar = child.findTabBar() {
                return tabBar
            }
        }
        return view.subviews.first(where: { $0 is UITabBar }) as? UITabBar
    }
}

// Extension to apply appearance
extension UITabBar {
    func applyAppearance(_ appearance: UITabBarAppearance) {
        self.standardAppearance = appearance
        self.scrollEdgeAppearance = appearance
    }
}

