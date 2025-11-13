//
//  branchrApp.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth // Phase 22: For Auth.auth().currentUser
import FirebaseMessaging // Phase 28: For FCM
import UserNotifications // Phase 28: For push notifications

@main
struct branchrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var showLaunchAnimation = true
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Phase 35.4: Single Firebase configuration - no helper function
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("☁️ Firebase configured safely at launch")
        }
        
        // Phase 34H: Quiet down PerfPowerTelemetryClientRegistrationService noise (debug builds only)
        #if DEBUG
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        #endif
        
        // Phase 34: Enable Firebase Auth persistence and auto-sign-in
        // Check if user is already signed in
        if let currentUser = Auth.auth().currentUser {
            print("✅ User session restored: \(currentUser.uid)")
            // Load profile from Firebase
            FirebaseProfileService.shared.fetchProfile(uid: currentUser.uid)
        } else {
            // Phase 34G: Sign in anonymously with Firebase config guard
            print("⚠️ No existing session, signing in anonymously...")
            signInAnonymouslyWithGuard()
        }
        
        // Phase 28: Configure FCM notifications
        FCMService.shared.configureNotifications()
        print("☁️ Firebase + FCM configured")
        
        // Validate MusicKit access on app launch
        // This will configure MusicKit and request user authorization
        MusicKitService.validateMusicKitAccess()
    }
    
    // MARK: - Phase 35: Session Recovery
    
    /// Check for and restore a previous ride session
    /// DISABLED in Phase 35.11 - prevents auto-starting rides on app launch
    private func checkAndRestoreRideSession() {
        // DISABLED: Auto-restore causes rides to start on launch
        // This feature can be re-enabled later with user confirmation
        /*
        Task { @MainActor in
            let recoveryService = RideSessionRecoveryService.shared
            
            guard recoveryService.hasRecoverableSession(),
                  let session = recoveryService.restoreSession() else {
                return
            }
            
            // Restore the session
            RideSessionManager.shared.restoreSession(session)
            
            // Notify user
            VoiceFeedbackService.shared.speak("Previous ride recovered")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            print("🔄 Restored ride session on app launch")
        }
        */
    }
    
    // MARK: - Phase 34G: Anonymous Sign-In with Firebase Guard
    
    /// Sign in anonymously, ensuring Firebase is configured first (Phase 34H: Hardened with retry)
    private func signInAnonymouslyWithGuard() {
        let attempt: () -> Void = {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("⚠️ Anonymous sign-in retry failed: \(error.localizedDescription)")
                } else if let user = result?.user {
                    print("✅ Firebase anonymous sign-in success: \(user.uid)")
                    FirebaseProfileService.shared.createDefaultProfile(uid: user.uid)
                }
            }
        }
        
        if FirebaseApp.app() == nil {
            print("⚠️ Firebase not configured yet, retrying sign-in in 1s…")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                attempt()
            }
        } else {
            attempt()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if showLaunchAnimation {
                LaunchAnimationView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showLaunchAnimation = false
                    }
                }
            } else {
                BranchrAppRoot() // ✅ Official app root with tabs, FAB, and theme
                    .onAppear {
                        // Phase 23: Set user online when app appears (only if signed in)
                        // Phase 34: Also update PresenceManager
                        if Auth.auth().currentUser != nil {
                            FirebaseService.shared.setUserOnlineStatus(isOnline: true)
                            PresenceManager.shared.setOnline(true)
                        }
                        
                        // Phase 35.11: DISABLED auto-restore on launch for stability
                        // checkAndRestoreRideSession() // Disabled - prevents auto-starting rides
                    }
                    .onDisappear {
                        // Phase 23: Set user offline when app disappears (only if signed in)
                        // Phase 34: Also update PresenceManager
                        if Auth.auth().currentUser != nil {
                            FirebaseService.shared.setUserOnlineStatus(isOnline: false)
                            PresenceManager.shared.setOnline(false)
                        }
                    }
                    .onChange(of: scenePhase) { phase in
                        // Phase 23: Update online status based on app state (only if signed in)
                        // Phase 34: Also update PresenceManager
                        if Auth.auth().currentUser != nil {
                            let isActive = phase == .active
                            FirebaseService.shared.setUserOnlineStatus(isOnline: isActive)
                            PresenceManager.shared.setOnline(isActive)
                        }
                    }
            }
        }
    }
}

// MARK: - Phase 33: AppDelegate for Firebase Initialization

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Phase 34H: FCM registration
        Messaging.messaging().delegate = self
        print("🔔 FCMService configured")
        return true
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📱 Phase 33: FCM token received: \(fcmToken ?? "nil")")
    }
}
