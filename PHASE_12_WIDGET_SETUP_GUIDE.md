# 🎯 Phase 12 – Branchr Widgets Complete Setup Guide

## 📱 **Widget Extension Target Creation**

### Step 1: Create Target in Xcode
1. **File** → **New** → **Target**
2. Choose: **Widget Extension**
3. Name: `BranchrWidgetExtension`
4. Language: **Swift**
5. **Uncheck** "Include Configuration Intent"
6. Click **Finish**
7. When asked to "Activate Scheme," choose **Cancel**

### Step 2: Replace Default Files
Replace the default widget files with our implementations:

**BranchrWidget.swift** - Replace with our implementation
**BranchrWidgetBundle.swift** - Replace with our implementation
**SharedModels.swift** - Add this new file to the widget target

## 🔧 **App Groups Setup**

### Step 3: Configure App Groups for Main App
1. Select **Branchr** (main target) in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Choose **App Groups**
5. Add: `group.com.joedormond.branchr`
6. Click **Done**

### Step 4: Configure App Groups for Widget Extension
1. Select **BranchrWidgetExtension** target in Xcode
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Choose **App Groups**
5. Add: `group.com.joedormond.branchr`
6. Click **Done**

## 🏗️ **Build Process**

### Step 5: Build Widget Extension
1. Select **BranchrWidgetExtension** scheme in Xcode
2. Press **Cmd+B** to build (don't run, just build)
3. Verify no build errors

### Step 6: Build Main App
1. Select **Branchr** scheme in Xcode
2. Press **Cmd+B** to build
3. Verify no build errors

## 📱 **Testing Widget**

### Step 7: Add Widget to Home Screen
1. On simulator or device: **Long press** home screen
2. Tap **+** button
3. Search for **"Branchr"**
4. Select **BranchrWidget**
5. Choose size (Small or Medium)
6. Tap **Add Widget**

### Step 8: Test Mode Changes
1. Open Branchr app
2. Change mode (Ride → Camp → Study → Caravan)
3. Check if widget updates to show new mode
4. Verify colors change based on mode

## 🎨 **Widget Features**

### Visual Features
- **Mode-Aware Display**: Shows current Branchr mode
- **Dynamic Colors**: Background changes based on active mode
- **Live Stats**: Distance, duration, calories
- **Active Indicator**: Green dot when active, gray when inactive
- **Two Sizes**: Small and Medium widget support

### Technical Features
- **App Groups**: `group.com.joedormond.branchr` for data sharing
- **Timeline Updates**: Every 10 minutes
- **Mode Persistence**: Automatically syncs with main app
- **Fallback Data**: Shows placeholder data if no ride data available

## 🔍 **Troubleshooting**

### Common Issues
1. **"Cannot find type BranchrMode"**
   - Ensure `SharedModels.swift` is added to widget target
   - Check that `BranchrMode` enum is properly defined

2. **"No such module 'WidgetKit'"**
   - Add WidgetKit framework to widget target
   - Ensure widget target is properly configured

3. **"App Group not found"**
   - Verify App Groups ID matches exactly: `group.com.joedormond.branchr`
   - Check both main app and widget targets have same App Group

4. **Widget not updating**
   - Check App Groups configuration
   - Verify `ModeManager` is saving to App Groups UserDefaults
   - Force close and reopen widget

### Build Errors
- **Missing files**: Ensure all widget files are in correct target
- **Import errors**: Check that shared models are accessible
- **Capability errors**: Verify App Groups are properly configured

## ✅ **Success Criteria**

- [ ] Widget Extension target created
- [ ] App Groups configured for both targets
- [ ] Widget builds without errors
- [ ] Main app builds without errors
- [ ] Widget appears in widget gallery
- [ ] Widget shows current mode
- [ ] Widget updates when mode changes
- [ ] Colors change based on mode
- [ ] Stats display correctly

## 🚀 **Next Steps**

After successful widget implementation:
1. **Phase 13**: Fix voice recognition system
2. **Phase 14**: Add live ride data to widget
3. **Phase 15**: Add quick actions to widget
4. **Phase 16**: Add multiple widget sizes and configurations

---

**Created by**: Joe Dormond  
**Date**: 2025-10-24  
**Phase**: 12 – Branchr Widgets
