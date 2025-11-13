//
//  ThemeManager.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-25.
//

import SwiftUI

/// Custom theme manager for Branchr app
/// Dark mode: Black/grey background with yellow buttons
/// Light mode: Yellow background with black buttons
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = true
    
    private init() {
        // Detect system appearance
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }
    
    // MARK: - Global Colors (Phase 1)
    var primaryYellow: Color {
        Color(hex: "FFD500")
    }
    
    var primaryBlack: Color {
        Color.black
    }
    
    var primaryGlow: Color {
        Color(hex: "FFE55C")
    }
    
    var darkCard: Color {
        Color(hex: "111111")
    }
    
    var lightCard: Color {
        Color(hex: "FFE76D")
    }
    
    // MARK: - Background Colors
    var primaryBackground: Color {
        isDarkMode ? primaryBlack : primaryYellow
    }
    
    var secondaryBackground: Color {
        isDarkMode ? Color.gray.opacity(0.1) : Color.black.opacity(0.1)
    }
    
    var cardBackground: Color {
        isDarkMode ? darkCard : lightCard
    }
    
    // MARK: - Text Colors
    var primaryText: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var secondaryText: Color {
        isDarkMode ? Color.gray : Color.black.opacity(0.7)
    }
    
    var accentText: Color {
        isDarkMode ? Color.yellow : Color.black
    }
    
    // MARK: - Button Colors
    var primaryButton: Color {
        isDarkMode ? Color.yellow : Color.black
    }
    
    var primaryButtonText: Color {
        isDarkMode ? Color.black : Color.yellow
    }
    
    var secondaryButton: Color {
        isDarkMode ? Color.gray.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    var secondaryButtonText: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    // MARK: - Accent Colors
    var accentColor: Color {
        isDarkMode ? Color.yellow : Color.black
    }
    
    var successColor: Color {
        isDarkMode ? Color.green : Color.black
    }
    
    var warningColor: Color {
        isDarkMode ? Color.orange : Color.black
    }
    
    var errorColor: Color {
        isDarkMode ? Color.red : Color.black
    }
    
    // MARK: - Border Colors
    var borderColor: Color {
        isDarkMode ? Color.gray.opacity(0.3) : Color.black.opacity(0.2)
    }
    
    // MARK: - Methods
    
    /// Toggle between light and dark mode with animation
    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
        print("🎨 Theme toggled: \(isDarkMode ? "Dark" : "Light")")
    }
    
    /// Set theme programmatically
    func setTheme(_ isDark: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode = isDark
        }
        print("🎨 Theme set to: \(isDarkMode ? "Dark" : "Light")")
    }
    
    /// Get the current theme name as a string
    var themeName: String {
        isDarkMode ? "Dark" : "Light"
    }
    
    /// Get the current theme icon
    var themeIcon: String {
        isDarkMode ? "moon.fill" : "sun.max.fill"
    }
}

// MARK: - View Extensions
extension View {
    func branchrBackground() -> some View {
        self.background(ThemeManager.shared.primaryBackground)
    }
    
    func branchrCardBackground() -> some View {
        self.background(ThemeManager.shared.cardBackground)
            .cornerRadius(12)
    }
    
    func branchrPrimaryText() -> some View {
        self.foregroundColor(ThemeManager.shared.primaryText)
    }
    
    func branchrSecondaryText() -> some View {
        self.foregroundColor(ThemeManager.shared.secondaryText)
    }
    
    func branchrAccentText() -> some View {
        self.foregroundColor(ThemeManager.shared.accentText)
    }
    
    func branchrPrimaryButton() -> some View {
        self
            .foregroundColor(ThemeManager.shared.primaryButtonText)
            .background(ThemeManager.shared.primaryButton)
            .cornerRadius(16)
    }
    
    func branchrSecondaryButton() -> some View {
        self
            .foregroundColor(ThemeManager.shared.secondaryButtonText)
            .background(ThemeManager.shared.secondaryButton)
            .cornerRadius(16)
    }
}

// MARK: - Phase 1: Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Button background color that adapts to light/dark mode
    static var branchrButtonBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .systemYellow : .black
        })
    }
    
    /// Button text color that adapts to light/dark mode
    static var branchrButtonText: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .systemYellow
        })
    }
    
    /// Primary text color that adapts to light/dark mode
    static var branchrTextPrimary: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    /// Accent color (yellow)
    static var branchrAccent: Color { Color.yellow }
}
