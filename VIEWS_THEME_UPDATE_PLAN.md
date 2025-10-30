# 🎨 Views Theme Unification - Update Plan

## Views Requiring Theme Updates

### ✅ Already Updated:
- `HomeView.swift` - Uses `.branchrBackground()`, theme colors
- `SettingsView.swift` - Already themed
- `SafetyControlView.swift` - Already themed
- `SectionCard.swift` - Already themed

### 🔧 Needs Full Theme Update:

1. **AudioControlView.swift** - Uses `Color.black.ignoresSafeArea()`
2. **GroupRideView.swift** - Uses hardcoded `.black`, `.yellow`
3. **RideMapView.swift** - Needs theme integration
4. **RideHistoryView.swift** - Needs theme colors
5. **RideSummaryView.swift** - Needs theme colors
6. **VoiceSettingsView.swift** - Needs theme update
7. **DJControlView.swift** - Uses `.ultraThinMaterial`
8. **MusicStatusBannerView.swift** - Hardcoded colors
9. **SongRequestSheet.swift** - Hardcoded colors
10. **RideCalendarView.swift** - Needs theme
11. **RideDayDetailView.swift** - Needs theme
12. **RideHUDView.swift** - Needs theme
13. **RideInsightsView.swift** - Needs theme
14. **RidePromptView.swift** - Needs theme
15. **WeightSettingsView.swift** - Needs theme
16. **ModeStatusBannerView.swift** - Needs theme
17. **CloudStatusBannerView.swift** - Hardcoded `.blue`

## Theme Standards to Apply:

### Backgrounds:
- Replace `Color.black.ignoresSafeArea()` → `theme.primaryBackground.ignoresSafeArea()`
- Replace `Color.yellow` → `theme.primaryBackground`

### Text:
- Replace `Color.white` / `.foregroundColor(.white)` → `theme.primaryText`
- Replace `Color.black` text → `theme.primaryText`
- Replace `Color.gray` → `theme.secondaryText`

### Buttons:
- Use `BranchrButton` component
- Or apply `.branchrPrimaryButton()` / `.branchrSecondaryButton()`

### Cards:
- Replace manual backgrounds → `.branchrCardBackground()`
- Or use `theme.cardBackground`

### Accents:
- Replace hardcoded yellow → `theme.accentColor`

