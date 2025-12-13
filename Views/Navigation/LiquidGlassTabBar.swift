//
//  LiquidGlassTabBar.swift
//  branchr
//
//  iOS 26-style floating Liquid Glass tab bar (Option A)
//

import SwiftUI

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Home
            TabBarButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
                HapticsService.shared.lightTap()
            }
            
            Spacer()
            
            // Capture (Center - highlighted with blue glow)
            TabBarButton(
                icon: "bolt.circle.fill",
                title: "Capture",
                isSelected: selectedTab == 1,
                isCenter: true
            ) {
                selectedTab = 1
                HapticsService.shared.mediumTap()
            }
            
            Spacer()
            
            // Profile
            TabBarButton(
                icon: "person.crop.circle.fill",
                title: "Profile",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
                HapticsService.shared.lightTap()
            }
            
            Spacer()
            
            // Settings
            TabBarButton(
                icon: "gearshape.fill",
                title: "Settings",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
                HapticsService.shared.lightTap()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(height: 82)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.black) // True black (#000)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .blur(radius: 20)
                )
                .shadow(color: Color.white.opacity(0.1), radius: 30)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    var isCenter: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(isCenter && isSelected ? 1.08 : 1.0)
                    .shadow(
                        color: isCenter && isSelected ? Color.blue.opacity(0.7) : .clear,
                        radius: 25
                    )
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

