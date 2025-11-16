# 🎨 Theme System & Brand Yellow Implementation

**Date:** November 15, 2025  
**Status:** ✅ Complete

---

## 📋 Overview

This document explains the Branchr theme system and how the official brand yellow (#FFD500) is implemented throughout the app.

---

## 🎯 Official Brand Color

### Brand Yellow: `#FFD500`

**Hex Code:** `#FFD500`  
**RGB:** `rgb(255, 213, 0)`  
**Usage:** All yellow colors throughout the app

**Important:** This is the ONLY yellow color used in the app. All other yellow references should be replaced with this.

---

## 📁 Key Files

### 1. `Services/ThemeManager.swift`

**Purpose:** Central theme management with brand yellow

**Key Properties:**
```swift
// Official brand yellow
let brandYellow = Color(hex: "#FFD500")

// Legacy alias (for compatibility)
let branchrYellow = Color(hex: "#FFD500")

// Accent color (uses brand yellow in dark mode)
var accentColor: Color {
    isDarkMode ? brandYellow : Color.black
}

// Accent text (uses brand yellow in dark mode)
var accentText: Color {
    isDarkMode ? brandYellow : Color.black
}
```

**Usage Throughout App:**
- Button backgrounds (dark mode)
- Button text (light mode)
- Tab bar icons (dark mode)
- Tab bar background (light mode)
- Glow effects
- All accent colors

---

### 2. `Services/BranchrColor.swift`

**Purpose:** Legacy color definitions (updated to use brand yellow)

**Updated:**
```swift
/// Signature yellow for buttons and accents
/// Official brand yellow: #FFD500
static let yellow = Color(hex: "#FFD500")
```

---

## 🔄 Dynamic Logo System

### Logo Assets Required

**In Assets.xcassets, add:**
1. `BranchrLogoLight` - Yellow background with black icon (for light mode)
2. `BranchrLogoDark` - Black background with yellow icon (for dark mode)

### Implementation in HomeView

```swift
// Phase 34D: Dynamic logo based on theme
Image(theme.isDarkMode ? "BranchrLogoDark" : "BranchrLogoLight")
    .resizable()
    .scaledToFit()
    .frame(width: 120, height: 120)
    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
```

**Behavior:**
- Light mode → Shows `BranchrLogoLight` (yellow bg, black icon)
- Dark mode → Shows `BranchrLogoDark` (black bg, yellow icon)
- Automatically switches when theme changes

---

## 🎨 Color System Architecture

### Theme-Aware Colors

**Backgrounds:**
- `primaryBackground`: Yellow (light) / Black (dark)
- `cardBackground`: White opacity (light) / Black opacity (dark)

**Buttons:**
- `primaryButtonBackground`: Black (light) / Yellow (dark)
- `primaryButtonText`: Yellow (light) / Black (dark)
- `safetyButtonBackground`: Always black
- `safetyButtonText`: Always brand yellow

**Text:**
- `primaryText`: Black (light) / White (dark)
- `accentText`: Black (light) / Brand yellow (dark)

**Glow:**
- `glowColor`: Brand yellow with opacity based on theme

---

## 🔧 How to Use Brand Yellow

### Method 1: Via ThemeManager (Recommended)

```swift
@ObservedObject private var theme = ThemeManager.shared

// Use brand yellow
theme.brandYellow
theme.accentColor  // Uses brandYellow in dark mode
```

### Method 2: Direct Hex

```swift
Color(hex: "#FFD500")
```

### Method 3: Via BranchrColor (Legacy)

```swift
BranchrColor.yellow
```

---

## 🚫 What NOT to Use

**Never use:**
- `Color.yellow` (system yellow, not brand color)
- `Color("Yellow")` (asset color, not brand color)
- Any other hex codes for yellow
- Hardcoded RGB values for yellow

**Always use:**
- `theme.brandYellow`
- `Color(hex: "#FFD500")`
- `theme.accentColor` (when appropriate)

---

## 🔄 Tab Bar Colors

### Implementation in BranchrAppRoot.swift

```swift
if theme.isDarkMode {
    // Dark Mode: Black background with yellow icons
    let yellow = UIColor(theme.brandYellow)
    appearance.backgroundColor = .black
    appearance.stackedLayoutAppearance.selected.iconColor = yellow
    // ...
} else {
    // Light Mode: Yellow background with black icons
    appearance.backgroundColor = UIColor(theme.brandYellow)
    appearance.stackedLayoutAppearance.selected.iconColor = .black
    // ...
}
```

**Result:**
- Light mode: Yellow tab bar (#FFD500) with black icons
- Dark mode: Black tab bar with yellow icons (#FFD500)

---

## 📝 Quick Reference

### To Use Brand Yellow in Any View:

```swift
@ObservedObject private var theme = ThemeManager.shared

// For backgrounds
.background(theme.brandYellow)

// For text
.foregroundColor(theme.brandYellow)

// For buttons
.background(theme.primaryButtonBackground)  // Uses brandYellow in dark mode
.foregroundColor(theme.primaryButtonText)   // Uses brandYellow in light mode

// For accents
.foregroundColor(theme.accentColor)  // Uses brandYellow in dark mode
```

### To Add Dynamic Logo:

```swift
Image(theme.isDarkMode ? "BranchrLogoDark" : "BranchrLogoLight")
    .resizable()
    .scaledToFit()
```

---

## ✅ Current Implementation Status

**Brand Yellow Applied To:**
- ✅ ThemeManager.brandYellow
- ✅ ThemeManager.accentColor (dark mode)
- ✅ ThemeManager.accentText (dark mode)
- ✅ Tab bar background (light mode)
- ✅ Tab bar icons (dark mode)
- ✅ Button backgrounds (dark mode)
- ✅ Button text (light mode)
- ✅ Safety button text
- ✅ Glow effects
- ✅ BranchrColor.yellow

**Dynamic Logo:**
- ✅ HomeView uses theme-based logo switching
- ⚠️ Assets required: `BranchrLogoLight` and `BranchrLogoDark`

---

## 🐛 Troubleshooting

### Problem: Yellow colors don't match
**Solution:** Ensure all yellow references use `theme.brandYellow` or `Color(hex: "#FFD500")`. Never use `Color.yellow`.

### Problem: Logo doesn't switch
**Solution:** Verify asset names match exactly: `BranchrLogoLight` and `BranchrLogoDark`. Check that `theme.isDarkMode` is updating correctly.

### Problem: Tab bar colors wrong
**Solution:** Ensure `updateTabBarAppearance()` is called in `onAppear` and `onChange(of: theme.isDarkMode)`. Verify it uses `UIColor(theme.brandYellow)`.

---

## 📋 Migration Checklist

If updating existing code to use brand yellow:

- [ ] Replace `Color.yellow` → `theme.brandYellow`
- [ ] Replace `Color("Yellow")` → `theme.brandYellow`
- [ ] Replace hardcoded yellow hex → `Color(hex: "#FFD500")`
- [ ] Update tab bar to use `UIColor(theme.brandYellow)`
- [ ] Update logo to use dynamic switching
- [ ] Verify all accent colors use `theme.accentColor`
- [ ] Test in both light and dark modes

---

**Last Updated:** November 15, 2025  
**Brand Yellow:** #FFD500 (Official)

