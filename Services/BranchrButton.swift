//
//  BranchrButton.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-25.
//

import SwiftUI

/// Reusable custom button component for Branchr
/// Automatically adapts to light/dark theme
struct BranchrButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: ButtonStyle = .primary
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(.headline.bold())
            }
            .foregroundColor(buttonTextColor)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(buttonBackgroundColor)
            .cornerRadius(16)
            .shadow(color: buttonShadowColor, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Button Styling
    
    private var buttonBackgroundColor: Color {
        switch style {
        case .primary:
            return theme.isDarkMode ? BranchrColor.yellow : BranchrColor.black
        case .secondary:
            return theme.isDarkMode ? BranchrColor.gray.opacity(0.3) : BranchrColor.black.opacity(0.1)
        case .success:
            return BranchrColor.green.opacity(0.8)
        case .danger:
            return BranchrColor.red.opacity(0.8)
        }
    }
    
    private var buttonTextColor: Color {
        switch style {
        case .primary:
            return theme.isDarkMode ? BranchrColor.black : BranchrColor.yellow
        case .secondary:
            return theme.isDarkMode ? BranchrColor.whiteText : BranchrColor.blackText
        case .success, .danger:
            return BranchrColor.whiteText
        }
    }
    
    private var buttonShadowColor: Color {
        theme.isDarkMode ? BranchrColor.black.opacity(0.3) : BranchrColor.gray.opacity(0.3)
    }
    
    // MARK: - Button Styles
    
    enum ButtonStyle {
        case primary    // Main action button (yellow/black based on theme)
        case secondary  // Secondary action button
        case success    // Success/green button
        case danger     // Dangerous action/red button
    }
}

// MARK: - Button Variants

extension BranchrButton {
    /// Create a primary action button
    static func primary(title: String, icon: String? = nil, action: @escaping () -> Void) -> BranchrButton {
        BranchrButton(title: title, icon: icon, action: action, style: .primary)
    }
    
    /// Create a secondary action button
    static func secondary(title: String, icon: String? = nil, action: @escaping () -> Void) -> BranchrButton {
        BranchrButton(title: title, icon: icon, action: action, style: .secondary)
    }
    
    /// Create a success button
    static func success(title: String, icon: String? = nil, action: @escaping () -> Void) -> BranchrButton {
        BranchrButton(title: title, icon: icon, action: action, style: .success)
    }
    
    /// Create a danger button
    static func danger(title: String, icon: String? = nil, action: @escaping () -> Void) -> BranchrButton {
        BranchrButton(title: title, icon: icon, action: action, style: .danger)
    }
}

// MARK: - Preview

struct BranchrButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BranchrButton.primary(title: "Start Ride", icon: "location.circle") {
                print("Primary tapped")
            }
            .padding()
            
            BranchrButton.secondary(title: "Settings", icon: "gear") {
                print("Secondary tapped")
            }
            .padding()
            
            BranchrButton.success(title: "Success", icon: "checkmark.circle") {
                print("Success tapped")
            }
            .padding()
            
            BranchrButton.danger(title: "Delete", icon: "trash") {
                print("Danger tapped")
            }
            .padding()
        }
        .background(
            ThemeManager.shared.isDarkMode ? BranchrColor.black : BranchrColor.yellow
        )
        .previewLayout(.sizeThatFits)
    }
}

