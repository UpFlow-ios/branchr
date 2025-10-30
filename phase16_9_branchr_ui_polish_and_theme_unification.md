# 🎨 Phase 16.9 – Branchr UI Polish & Theme Unification

**Objective:**  
Unify Branchr's entire visual system — backgrounds, buttons, typography, and spacing — across all screens so the app looks clean, balanced, and professionally designed.

---

## Design Standards

| Element | Rule |
|----------|------|
| **Background** | Always use `theme.backgroundColor.ignoresSafeArea()` |
| **Text Color** | `theme.textColor` |
| **Accent Color** | `theme.accentColor` |
| **Rounded Corners** | Default 16 pt |
| **Card Style** | RoundedRectangle(cornerRadius: 16).fill(theme.cardBackgroundColor) with subtle shadow |
| **Spacing** | Default padding: 20 pt; inter-element spacing: 12 pt |
| **Typography** | `.largeTitle.bold()` for headings, `.headline` for labels, `.body` for descriptions |

---

## Success Criteria

✅ All screens share the same yellow/black/gray color system  
✅ Cards, toggles, and buttons look consistent  
✅ No mismatched system blue buttons  
✅ Rounded corners and typography standardized  
✅ FAB and Tab Bar align visually  
✅ App feels cohesive and professional

