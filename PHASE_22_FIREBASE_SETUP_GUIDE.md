# 🔥 Phase 22 - Firebase Integration Setup Guide

## ✅ Phase 21C Complete
- MultipeerConnectivity network permissions added to Info.plist
- Networking entitlements added
- Retry logic implemented for peer discovery

## ⚠️ Phase 22 - Manual Setup Required

### Step 1: Add Firebase Swift Packages

1. Open Xcode
2. Go to **File → Add Package Dependencies...**
3. Add these Firebase package URLs:
   - `https://github.com/firebase/firebase-ios-sdk`
4. Select the following products:
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseStorage
   - ✅ FirebaseCore
5. Click **Add Package** and ensure they're added to the **branchr** target

### Step 2: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Add project** → Name it **Branchr**
3. Follow the setup wizard
4. Click **Add app** → Select **iOS**
5. Enter bundle ID: `com.joedormond.branchr2025`
6. Download `GoogleService-Info.plist`
7. Add `GoogleService-Info.plist` to your Xcode project:
   - Drag it into the `branchr/` folder in Xcode
   - ✅ Check "Copy items if needed"
   - ✅ Ensure it's added to the **branchr** target

### Step 3: Enable Firebase Services

In Firebase Console → Project Settings:

1. **Authentication**
   - Go to **Authentication → Sign-in method**
   - Enable **Sign in with Apple**
   - Configure if needed

2. **Cloud Firestore**
   - Go to **Firestore Database**
   - Click **Create database**
   - Start in **test mode** (for development)
   - Choose your region

3. **Storage**
   - Go to **Storage**
   - Click **Get started**
   - Start in **test mode** (for development)
   - Choose your region

### Step 4: Build & Test

1. **Build the project** - Firebase should now compile
2. **Run the app** - Check console for:
   ```
   ☁️ Firebase initialized successfully
   ☁️ FirebaseService initialized
   ✅ AuthService: No user signed in
   ```

### Step 5: Test Firebase Integration

1. **Profile Upload**: Update profile photo in Profile tab → Check Firebase Storage for upload
2. **Profile Sync**: Change name/bio → Check Firestore `users` collection
3. **Authentication**: (Future) Sign in with Apple → Check Firebase Auth users

## 📋 Code Already Implemented

✅ `Services/FirebaseService.swift` - Profile uploads and Firestore operations
✅ `Services/AuthService.swift` - Apple ID authentication
✅ `branchrApp.swift` - Firebase initialization
✅ `Views/Profile/ProfileView.swift` - Firebase sync integration

## 🚀 Next Steps After Setup

Once Firebase packages are added and `GoogleService-Info.plist` is in place:

1. Build should succeed
2. Profile photos will upload to Firebase Storage
3. Profile data will sync to Firestore
4. Ready for Apple ID sign-in implementation

## ⚠️ Important Notes

- **Test Mode**: Firestore and Storage start in test mode (anyone can read/write)
- **Production**: Before release, update security rules
- **GoogleService-Info.plist**: Never commit this file to Git (add to .gitignore)

## 🔗 Firebase Documentation

- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Firestore Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Storage Rules](https://firebase.google.com/docs/storage/security)

