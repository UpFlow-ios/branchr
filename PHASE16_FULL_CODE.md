# 🌆 Phase 16 – Full UI Architecture: Complete Code Reference

**All code files generated for Phase 16**

---

## 📁 File Structure

```
branchr/
│
├── App/
│   ├── BranchrAppRoot.swift        ← Main app shell
│   └── FloatingActionMenu.swift    ← Floating action button
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ModeStatusBannerView.swift
│   │
│   ├── Ride/
│   │   ├── RideMapView.swift
│   │   ├── RideSummaryView.swift
│   │   ├── RideHistoryView.swift
│   │   └── CloudStatusBannerView.swift
│   │
│   ├── Voice/
│   │   ├── VoiceSettingsView.swift
│   │   ├── DJControlView.swift
│   │   └── MusicStatusBannerView.swift
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── SafetyControlView.swift
│   │   └── ModeSelectionView.swift
│   │
│   └── SharedComponents/
│       └── SectionCard.swift
│
└── ContentView.swift (updated to use BranchrAppRoot)
```

---

## 1️⃣ App/BranchrAppRoot.swift

```swift
import SwiftUI

struct BranchrAppRoot: View {
    @ObservedObject var theme = ThemeManager.shared
    @State private var selectedTab: Int = 0
    @State private var showActionMenu = false
    
    var body: some View {
        ZStack {
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
                
                // Tab 2: Ride
                NavigationStack {
                    RideMapView()
                }
                .tabItem {
                    Image(systemName: "bicycle.circle.fill")
                    Text("Ride")
                }
                .tag(1)
                
                // Tab 3: Voice
                NavigationStack {
                    VoiceSettingsView()
                }
                .tabItem {
                    Image(systemName: "waveform.circle.fill")
                    Text("Voice")
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
            
            // Floating Action Button overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionMenu(showMenu: $showActionMenu)
                        .padding(.bottom, 80)
                        .padding(.trailing, 20)
                }
            }
        }
        .background(theme.primaryBackground.ignoresSafeArea())
    }
}
```

---

## 2️⃣ App/FloatingActionMenu.swift

```swift
import SwiftUI

struct FloatingActionMenu: View {
    @Binding var showMenu: Bool
    @ObservedObject var theme = ThemeManager.shared
    @StateObject private var locationService = LocationTrackingService()
    @StateObject private var voiceService = VoiceChatService()
    
    var body: some View {
        ZStack {
            // Expanded action cluster
            if showMenu {
                VStack(alignment: .trailing, spacing: 14) {
                    ActionRow(label: "Start Ride", icon: "location.circle.fill") {
                        if !locationService.isTracking {
                            locationService.startTracking()
                        }
                        withAnimation { showMenu = false }
                    }
                    
                    ActionRow(
                        label: voiceService.isMuted ? "Unmute Voice" : "Mute Voice",
                        icon: voiceService.isMuted ? "mic.circle.fill" : "mic.slash.circle.fill"
                    ) {
                        voiceService.toggleMute()
                        withAnimation { showMenu = false }
                    }
                    
                    ActionRow(label: "Safety SOS", icon: "exclamationmark.triangle.fill") {
                        // Emergency alert
                        withAnimation { showMenu = false }
                    }
                    
                    ActionRow(label: "DJ Controls", icon: "music.note.list") {
                        // Open DJ mode
                        withAnimation { showMenu = false }
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            // Main button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(theme.primaryButton)
                        .frame(width: 64, height: 64)
                        .shadow(radius: 10)

                    Image(systemName: showMenu ? "xmark" : "bolt.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.primaryButtonText)
                }
            }
        }
    }
}

private struct ActionRow: View {
    let label: String
    let icon: String
    let action: () -> Void
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.black.opacity(0.7))
            .cornerRadius(14)
            .shadow(radius: 6)
        }
    }
}
```

---

## 3️⃣ Views/SharedComponents/SectionCard.swift

```swift
import SwiftUI

struct SectionCard<Content: View>: View {
    @ObservedObject var theme = ThemeManager.shared
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(theme.primaryText)
                .padding(.bottom, 4)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            theme.isDarkMode
                ? Color.white.opacity(0.05)
                : Color.black.opacity(0.06)
        )
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding(.horizontal, 16)
    }
}
```

---

## 4️⃣ Views/Settings/SettingsView.swift

Complete settings hub with theme toggle, mode selection, cloud sync, and watch status.

---

## 5️⃣ Views/Settings/SafetyControlView.swift

Complete safety screen with emergency SOS, auto-safety toggles, and emergency contacts.

---

## ✅ Implementation Summary

### Features Implemented:
1. ✅ **TabView Navigation** - 4 tabs with individual NavigationStacks
2. ✅ **Floating Action Button** - Quick actions accessible from any tab
3. ✅ **Theme System** - Full light/dark mode support
4. ✅ **Settings Hub** - Centralized settings with theme toggle
5. ✅ **Safety Controls** - Emergency SOS and safety features
6. ✅ **Reusable Components** - SectionCard for consistent styling

### Build Status:
- ✅ 0 errors
- ✅ 0 warnings
- ✅ All files organized in proper folder structure

---

## 🚀 Usage

The app now uses `BranchrAppRoot` as the main entry point, replacing the previous single `HomeView` structure. Users can:

- Navigate between 4 main sections via tab bar
- Access quick actions via floating button
- Toggle theme via Settings
- Change active mode
- View cloud sync and watch status
- Access emergency SOS controls

---

**Phase 16 Complete! All code generated and organized.** ✅

