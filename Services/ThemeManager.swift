//
//  ThemeManager.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-25.
//

import SwiftUI

/// Custom theme manager for Branchr app
/// Phase 2: Light mode = yellow bg, black buttons | Dark mode = black bg, yellow buttons
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = false {
        didSet {
            print("🎨 Theme toggled: \(isDarkMode ? "Dark" : "Light")")
        }
    }
    
    private init() {
        // Detect system appearance
        self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    }
    
    // MARK: - Base Brand Colors (Phase 2)
    let brandYellow = Color(hex: "#FFD500")  // Official brand yellow #FFD500
    let branchrYellow = Color(hex: "#FFD500")  // Legacy alias
    let branchrBlack = Color.black
    
    // MARK: - Background Colors
    var primaryBackground: Color {
        isDarkMode ? branchrBlack : branchrYellow
    }
    
    var secondaryBackground: Color {
        isDarkMode ? Color.gray.opacity(0.1) : Color.black.opacity(0.1)
    }
    
    var cardBackground: Color {
        isDarkMode ? Color.black.opacity(0.9) : Color.white.opacity(0.2)
    }
    
    // MARK: - Button Colors (Phase 2)
    var primaryButtonBackground: Color {
        isDarkMode ? branchrYellow : branchrBlack
    }
    
    var primaryButtonText: Color {
        isDarkMode ? branchrBlack : branchrYellow
    }
    
    // Safety button always black with yellow text
    var safetyButtonBackground: Color {
        branchrBlack
    }
    
    var safetyButtonText: Color {
        branchrYellow
    }
    
    // Soft glow color for hero CTA and tiles
    var glowColor: Color {
        branchrYellow.opacity(isDarkMode ? 0.8 : 0.6)
    }
    
    // MARK: - Legacy Support (keep for compatibility)
    var primaryYellow: Color {
        branchrYellow
    }
    
    var primaryBlack: Color {
        branchrBlack
    }
    
    var primaryGlow: Color {
        Color(hex: "#FFE55C")
    }
    
    var darkCard: Color {
        Color(hex: "#111111")
    }
    
    var lightCard: Color {
        Color(hex: "#FFE76D")
    }
    
    // MARK: - Text Colors
    var primaryText: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var secondaryText: Color {
        isDarkMode ? Color.gray : Color.black.opacity(0.7)
    }
    
    var accentText: Color {
        isDarkMode ? brandYellow : Color.black
    }
    
    // MARK: - Legacy Button Colors (keep for compatibility)
    var primaryButton: Color {
        primaryButtonBackground
    }
    
    var secondaryButton: Color {
        isDarkMode ? Color.gray.opacity(0.3) : Color.black.opacity(0.1)
    }
    
    var secondaryButtonText: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    // MARK: - Accent Colors
    var accentColor: Color {
        isDarkMode ? brandYellow : Color.black
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
    
    // MARK: - Phase 41E: Weekly Goal Gradient Colors
    /// Warm yellow gradient start (close to brand yellow)
    var goalGradientStart: Color {
        Color(hex: "#FFD500") // Brand yellow
    }
    
    /// Soft orange/pink gradient middle
    var goalGradientMid: Color {
        Color(hex: "#FF6B6B") // Soft coral/pink
    }
    
    /// Violet/purple gradient end
    var goalGradientEnd: Color {
        Color(hex: "#9B59B6") // Soft purple
    }
    
    // MARK: - Phase 67: Rainbow Progress Gradient
    /// Vivid rainbow gradient for progress bars (horizontal)
    var rideRainbowGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.32, blue: 0.42), // hot pink-ish
                .orange,
                .yellow,
                .green,
                .blue,
                .purple
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Vivid rainbow gradient for vertical bars (e.g., Daily Distance chart)
    var rideRainbowGradientVertical: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.32, blue: 0.42), // hot pink-ish
                .orange,
                .yellow,
                .green,
                .blue,
                .purple
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    // MARK: - Phase 41E: Neutral Accent Color
    /// Neutral gray accent for tertiary UI elements (tracks, borders, etc.)
    /// Light mode: cooler light grey for tracks/borders
    /// Dark mode: slightly lighter gray than primary background for layered cards
    var neutralAccent: Color {
        isDarkMode 
            ? Color(red: 0.18, green: 0.18, blue: 0.18) // Lighter than black for card separation
            : Color(red: 0.86, green: 0.86, blue: 0.90) // Cooler light grey for tracks/borders
    }
    
    // MARK: - Phase 41F: Surface Background
    /// Surface background for cards that float above the primary background
    /// Light mode: near-black to match primary action buttons
    /// Dark mode: slightly lighter than primaryBackground for card separation
    var surfaceBackground: Color {
        isDarkMode
            ? Color(red: 0.12, green: 0.12, blue: 0.12) // Slightly lighter than black for cards
            : Color(red: 0.04, green: 0.04, blue: 0.04) // Near-black for cards in light mode (Phase 41I: matches action buttons)
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
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
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
    
    /// Accent color (official brand yellow #FFD500)
    static var branchrAccent: Color { Color(hex: "#FFD500") }
}
