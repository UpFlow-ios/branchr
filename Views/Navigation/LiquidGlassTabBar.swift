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
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(Color.black.opacity(0.15))
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -2)
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
                    .foregroundColor(isSelected ? .white : .white.opacity(0.55))
                    .scaleEffect(isCenter && isSelected ? 1.08 : 1.0)
                    .overlay(
                        Group {
                            if isCenter && isSelected {
                                // Subtle neon blue highlight for center tab
                                Circle()
                                    .fill(Color.cyan.opacity(0.25))
                                    .blur(radius: 12)
                                    .scaleEffect(1.3)
                            }
                        }
                    )
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

