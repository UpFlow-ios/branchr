# Phase 60.3 – Enlarge Music Badges & Remove Glow

**Status**: ✅ Completed  
**Date**: 2025-11-30

---

## 🎯 Goals

1. Make the Apple Music and branchr badge logos inside the music source pills **larger** (from 32pt to 40pt height).
2. Remove the **yellow glow shadow** from the selected pill.
3. Move the top "branchr" wordmark lower on the Home screen (increased top spacer from 12pt to 40pt).
4. Keep the glass background + yellow border for the selected pill exactly as in Phase 60.2.

---

## 📝 Changes Made

### 1. Enlarged Badge Logos

**Modified**: `Views/Home/HomeView.swift` (MusicSourceSelectorView component)

**Changes**:
- Increased badge frame height from `32pt` to `40pt`
- Badges now fill the pill more prominently and are more dominant
- Maintains proportional width (aspect ratio preserved)
- Keeps 12pt horizontal padding for breathing room

**Updated Code**:
```swift
brandedLogo(for: source)
    .resizable()
    .scaledToFit()
    .frame(height: 40) // was 32 – make badge bigger
    .padding(.horizontal, 12)
```

**Result**: Badges are now 25% larger (40pt vs 32pt), making them more prominent, dominant, and easier to recognize.

---

### 2. Lowered Header Position

**Modified**: `Views/Home/HomeView.swift`

**Changes**:
- Increased top spacer from `12pt` to `40pt`
- "branchr" wordmark now sits lower, away from the status bar
- Creates more breathing room between status bar and header
- Improves visual hierarchy and spacing

**Updated Code**:
```swift
// Top breathing room - push all content down (Phase 60.3: increased for lower header)
Spacer()
    .frame(height: 40) // was 12 – wordmark sits lower, away from status bar
```

**Result**: Header has more space from the status bar, creating better visual separation and hierarchy.

---

### 3. Removed Yellow Glow Shadow

**Modified**: `Views/Home/HomeView.swift` (MusicSourceSelectorView component)

**Changes**:
- Removed `.shadow()` modifier from the pill container
- Selected pill now shows only glass background + yellow border (no glow)
- Unselected pill remains unchanged (solid dark background, no glow)

**Removed Code**:
```swift
.shadow(
    color: theme.brandYellow.opacity(selectedSource == source ? 0.4 : 0.0),
    radius: 16,
    x: 0,
    y: 0
)
```

**Result**: Cleaner, more subtle selected state without the glow effect.

---

## 🎨 Visual Design

### Before Phase 60.3:
- Badges were 32pt height
- Header was close to status bar (12pt spacing)
- Selected pill had yellow glow shadow (0.4 opacity, 16pt radius)
- More subtle badge presence
- Glow added extra visual weight

### After Phase 60.3:
- **Larger Badges**: 40pt height badges are more prominent and dominant
- **Lower Header**: Wordmark sits lower with 40pt spacing from status bar
- **No Glow**: Selected pill uses only glass + border (cleaner appearance)
- **Better Visibility**: Larger badges are easier to recognize at a glance
- **Subtle Selection**: Glass + border provides selection feedback without glow
- **Better Hierarchy**: More breathing room improves visual spacing

---

## 🔧 Technical Details

### Badge Sizing

**Implementation**:
- 40pt height (increased from 32pt)
- Proportional width (maintains aspect ratio)
- 12pt horizontal padding preserved
- Pill height remains 52pt (minHeight)

### Header Spacing

**Implementation**:
- Top spacer increased from 12pt to 40pt
- Creates more breathing room between status bar and header
- Improves visual hierarchy
- Header no longer hugs the status bar

### Shadow Removal

**Implementation**:
- Removed entire `.shadow()` modifier
- No conditional shadow logic needed
- Cleaner code, simpler visual state

### Visual Hierarchy

**Selected Pill**:
- Glass background (.ultraThinMaterial)
- Yellow border (2pt stroke)
- No glow shadow
- Larger badge (32pt)

**Unselected Pill**:
- Solid dark background
- No border
- No glow
- Larger badge (32pt)

---

## ✅ Acceptance Criteria

- [x] Badges enlarged from 32pt to 40pt height
- [x] Badges fill pills more prominently and are more dominant
- [x] Header moved lower (top spacer increased from 12pt to 40pt)
- [x] Yellow glow shadow removed from selected pill
- [x] Glass background + yellow border preserved for selected pill
- [x] All selection logic, haptics, and logging unchanged
- [x] No layout jumps or clipping
- [x] Build succeeds with no new errors

---

## 📁 Files Modified

1. **Views/Home/HomeView.swift**
   - Increased badge frame height from 32pt to 40pt
   - Increased top spacer from 12pt to 40pt (lowered header)
   - Removed yellow glow shadow from pill container

---

## 🚀 User Experience

### Before:
- Badges were smaller (32pt), less prominent
- Header was close to status bar (12pt spacing)
- Glow effect added visual weight
- Less immediate brand recognition

### After:
- **More Prominent Badges**: 40pt height makes badges clearly visible and dominant
- **Lower Header**: More breathing room from status bar improves hierarchy
- **Cleaner Design**: No glow creates more subtle, refined appearance
- **Better Recognition**: Larger badges improve brand logo visibility
- **Balanced Selection**: Glass + border provides clear feedback without glow

---

## 📝 Notes

### Design Rationale

1. **Larger Badges**:
   - 32pt height makes badges fill the pill better
   - More prominent brand recognition
   - Better use of available space

2. **No Glow**:
   - Glow effect was visually heavy
   - Glass + border provides sufficient selection feedback
   - Cleaner, more modern appearance

3. **Visual Balance**:
   - Larger badges + no glow = balanced design
   - Badges are the focus, not effects
   - Professional and refined

### Layout Considerations

- Badge sizing works on all iPhone sizes
- Proportional width adapts to different screen widths
- Pill height unchanged (52pt)
- No layout shifts or clipping

---

## 🧪 Manual Test Cases

### Case A: Badge Size
1. Open HomeView
2. Verify Apple Music badge is larger (40pt height)
3. Verify branchrMedia badge is larger (40pt height)
4. Check badges fill pills more prominently and are more dominant
5. Verify badges maintain aspect ratio

### Case B: Header Position
1. Open HomeView
2. Verify "branchr" wordmark is lower on screen
3. Check there's more space between status bar and header (40pt)
4. Verify header doesn't hug the status bar
5. Test on different iPhone sizes

### Case C: No Glow
1. Tap left pill to select Apple Music
2. Verify selected pill shows glass background
3. Verify yellow border appears
4. Verify NO yellow glow shadow
5. Tap right pill to select branchrMedia
6. Verify glow doesn't appear on either pill

### Case D: Selection Logic
1. Tap between pills to switch selection
2. Verify haptics fire on each tap
3. Check console logs show correct source changes
4. Verify selection state persists correctly
5. Verify onChange handler still syncs correctly

### Case E: Layout Stability
1. Test on iPhone SE (small screen)
2. Test on iPhone 15 Pro (standard screen)
3. Verify pills maintain 52pt height
4. Verify badges remain centered and readable
5. Check no clipping or layout issues

---

**Phase 60.3 Complete** ✅

