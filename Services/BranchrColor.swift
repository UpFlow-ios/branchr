//
//  BranchrColor.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-25.
//

import SwiftUI

/// Centralized color definitions for Branchr theme
/// Provides consistent color palette across the entire app
struct BranchrColor {
    // MARK: - Primary Colors
    
    /// Signature yellow for buttons and accents in dark mode
    /// Also used as background in light mode
    static let yellow = Color(red: 1.0, green: 204.0/255.0, blue: 0.0)
    
    /// Pure black for backgrounds in dark mode
    /// Also used for buttons in light mode
    static let black = Color.black
    
    /// Medium gray for secondary elements
    static let gray = Color(white: 0.3)
    
    /// Light gray for backgrounds and cards
    static let lightGray = Color(white: 0.8)
    
    /// Very light gray for subtle backgrounds
    static let veryLightGray = Color(white: 0.95)
    
    // MARK: - Text Colors
    
    /// White text for dark mode
    static let whiteText = Color.white
    
    /// Black text for light mode
    static let blackText = Color.black
    
    /// Gray text for secondary information
    static let grayText = Color.gray
    
    // MARK: - Status Colors
    
    /// Success/active green
    static let green = Color.green
    
    /// Warning orange
    static let orange = Color.orange
    
    /// Error red
    static let red = Color.red
    
    // MARK: - Opacity Variants
    
    /// Semi-transparent yellow
    static let yellowOpacity = yellow.opacity(0.7)
    
    /// Semi-transparent black
    static let blackOpacity = black.opacity(0.7)
    
    /// Semi-transparent white
    static let whiteOpacity = Color.white.opacity(0.7)
}

