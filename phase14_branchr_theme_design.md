# 🎨 Branchr Phase 14 – Global Theme System (Yellow / Black / Grey)

**Objective:**  
Define a unified, app-wide theme system for **Branchr**, built around the signature color palette and mode-based contrast themes:
- **Light Mode:** Yellow background, black UI components, grey highlights  
- **Dark Mode:** Black background, yellow UI components, grey highlights  

All buttons, banners, and icons will follow these rules dynamically.

---

## ⚙️ Core Goals

1. ✅ Create a **ThemeManager.swift** service for centralized color management (already exists)  
2. ⏳ Add **BranchrColor.swift** for consistent color definitions  
3. ⏳ Add reusable **BranchrButton.swift** for consistent styling  
4. ⏳ Update existing views to use new centralized components  
5. ✅ Apply global theming to every major screen (already done)

---

## 📂 Current Status

✅ **ThemeManager.swift** - Already exists and is working  
⏳ **BranchrColor.swift** - Needs to be created  
⏳ **BranchrButton.swift** - Needs to be created  
✅ **Theme integration** - Already implemented in HomeView  

---

## 🧱 Implementation Plan

### 1️⃣ Create BranchrColor.swift (New File)
Define all global colors here for consistency.

### 2️⃣ Create BranchrButton.swift (New File)
Reusable custom button component for consistent styling.

### 3️⃣ Update ThemeManager.swift
Add the `toggleMode()` method with animation support.

### 4️⃣ Apply to All Major Views
Ensure consistent theming across RideMapView, VoiceSettingsView, etc.

---

## 🧪 Testing Checklist

✅ Light → Dark mode toggle works  
✅ Buttons invert correctly  
✅ Logo visible in both themes  
✅ Text maintains proper contrast  
✅ No console errors  

---

## ✅ Success Criteria

• Entire app obeys yellow/black/grey theme  
• Unified design across all views  
• Logo properly integrated  
• Instant day/night switcher  
• Build = 0 errors, 0 warnings

