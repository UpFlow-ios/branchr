//
//  SettingsView.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//  Production-ready Settings screen with comprehensive sections
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var modeManager = ModeManager.shared
    @ObservedObject var cloudSync = RideCloudSyncService.shared
    @ObservedObject var watchService = WatchConnectivityService.shared
    @ObservedObject var userPreferences = UserPreferenceManager.shared
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var rideDataManager = RideDataManager.shared
    
    // Navigation states
    @State private var showingModeSelection = false
    @State private var showingSafetySettings = false
    @State private var showingVoiceSettings = false
    @State private var showingCalendarSettings = false
    @State private var showingEditProfile = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingClearCacheAlert = false
    @State private var showingResetPreferencesAlert = false
    @State private var showingHelpFAQ = false
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var showingEULA = false
    @State private var showingSafetyDisclaimer = false
    
    // Settings toggles (using @AppStorage for persistence)
    @AppStorage("autoPauseWhenStopped") private var autoPauseWhenStopped = false
    @AppStorage("voiceSafetyAlerts") private var voiceSafetyAlerts = true
    @AppStorage("rideReminders") private var rideReminders = true
    @AppStorage("weeklySummary") private var weeklySummary = true
    @AppStorage("friendActivity") private var friendActivity = false
    @AppStorage("voiceAnnouncements") private var voiceAnnouncements = true
    @AppStorage("djModeEnabled") private var djModeEnabled = true
    @AppStorage("allowVoiceChatWhileRiding") private var allowVoiceChatWhileRiding = true
    @AppStorage("appearanceMode") private var appearanceMode = "system" // "light", "dark", "system"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Account & Profile Section
                    SectionCard(title: "Account & Profile") {
                        VStack(spacing: 12) {
                            Button(action: {
                                showingEditProfile = true
                            }) {
                                SettingsRow(
                                    icon: "person.circle.fill",
                                    title: "Profile",
                                    showChevron: true
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                authService.signOut()
                            }) {
                                SettingsRow(
                                    icon: "arrow.right.square.fill",
                                    title: "Sign Out",
                                    showChevron: false
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingDeleteAccountAlert = true
                            }) {
                                SettingsRow(
                                    icon: "trash.fill",
                                    title: "Delete Account",
                                    showChevron: false,
                                    isDestructive: true
                                )
                            }
                        }
                    }
                    
                    // MARK: - Ride & Safety Section
                    SectionCard(title: "Ride & Safety") {
                        VStack(spacing: 12) {
                            SettingsToggleRow(
                                icon: "pause.circle.fill",
                                title: "Auto-pause ride when stopped",
                                isOn: $autoPauseWhenStopped
                            )
                            
                            Divider()
                            
                            SettingsToggleRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Voice safety alerts",
                                isOn: $voiceSafetyAlerts
                            )
                            
                            Divider()
                            
                            Button(action: {
                                showingSafetySettings = true
                            }) {
                                SettingsRow(
                                    icon: "shield.checkered",
                                    title: "Safety & SOS Settings",
                                    showChevron: true
                                )
                            }
                        }
                    }
                    
                    // MARK: - Notifications Section
                    SectionCard(title: "Notifications") {
                        VStack(spacing: 12) {
                            // TODO: Wire rideReminders to notification scheduler
                            // Future: Schedule local notifications for ride reminders based on user's typical ride times
                            SettingsToggleRow(
                                icon: "bell.fill",
                                title: "Ride reminders",
                                isOn: $rideReminders
                            )
                            
                            Divider()
                            
                            // TODO: Wire weeklySummary to notification scheduler
                            // Future: Schedule weekly summary notifications (e.g., every Sunday)
                            SettingsToggleRow(
                                icon: "chart.bar.fill",
                                title: "Weekly summary",
                                isOn: $weeklySummary
                            )
                            
                            Divider()
                            
                            // TODO: Wire friendActivity to notification scheduler
                            // Future: Notify when friends start rides or achieve milestones
                            SettingsToggleRow(
                                icon: "person.2.fill",
                                title: "Friend activity",
                                isOn: $friendActivity
                            )
                            
                            Divider()
                            
                            Button(action: {
                                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsURL)
                                }
                            }) {
                                SettingsRow(
                                    icon: "gear",
                                    title: "Open System Notification Settings",
                                    showChevron: true
                                )
                            }
                        }
                    }
                    
                    // MARK: - Audio & Voice Section
                    SectionCard(title: "Audio & Voice") {
                        VStack(spacing: 12) {
                            // TODO: Wire voiceAnnouncements to VoiceFeedbackService or VoiceCoachService
                            // Future: Control whether periodic ride updates are spoken
                            SettingsToggleRow(
                                icon: "speaker.wave.2.fill",
                                title: "Voice announcements",
                                isOn: $voiceAnnouncements
                            )
                            
                            Divider()
                            
                            // TODO: Wire djModeEnabled to MusicSyncService or DJ controls
                            // Future: Enable/disable DJ mode features (song requests, shared playback)
                            SettingsToggleRow(
                                icon: "music.note",
                                title: "DJ mode enabled",
                                isOn: $djModeEnabled
                            )
                            
                            Divider()
                            
                            // TODO: Wire allowVoiceChatWhileRiding to VoiceChatService
                            // Future: Prevent voice chat from starting during active rides if disabled
                            SettingsToggleRow(
                                icon: "mic.fill",
                                title: "Allow voice chat while riding",
                                isOn: $allowVoiceChatWhileRiding
                            )
                            
                            Divider()
                            
                            Button(action: {
                                showingVoiceSettings = true
                            }) {
                                SettingsRow(
                                    icon: "waveform.circle.fill",
                                    title: "Voice & Audio Settings",
                                    showChevron: true
                                )
                            }
                        }
                    }
                    
                    // MARK: - Appearance Section
                    SectionCard(title: "Appearance") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Theme")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                            
                            Picker("Appearance", selection: $appearanceMode) {
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                                Text("Match System").tag("system")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: appearanceMode) { newValue in
                                updateAppearanceMode(newValue)
                            }
                        }
                    }
                    
                    // MARK: - Data & Privacy Section
                    SectionCard(title: "Data & Privacy") {
                        VStack(spacing: 12) {
                            Button(action: {
                                showingClearCacheAlert = true
                            }) {
                                SettingsRow(
                                    icon: "trash.circle.fill",
                                    title: "Clear local ride cache",
                                    showChevron: false
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingResetPreferencesAlert = true
                            }) {
                                SettingsRow(
                                    icon: "arrow.counterclockwise.circle.fill",
                                    title: "Reset app preferences",
                                    showChevron: false
                                )
                            }
                        }
                    }
                    
                    // MARK: - Support Section
                    SectionCard(title: "Support") {
                        VStack(spacing: 12) {
                            Button(action: {
                                showingHelpFAQ = true
                            }) {
                                SettingsRow(
                                    icon: "questionmark.circle.fill",
                                    title: "Help & FAQ",
                                    showChevron: true
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                openEmail(to: "support@branchr.app", subject: nil)
                            }) {
                                SettingsRow(
                                    icon: "envelope.fill",
                                    title: "Contact Support",
                                    showChevron: true
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                openEmail(to: "support@branchr.app", subject: "Branchr Bug Report")
                            }) {
                                SettingsRow(
                                    icon: "ladybug.fill",
                                    title: "Report a bug",
                                    showChevron: true
                                )
                            }
                        }
                    }
                    
                    // MARK: - About & Legal Section
                    SectionCard(title: "About & Legal") {
                        VStack(spacing: 12) {
                            Button(action: {
                                showingTerms = true
                            }) {
                                SettingsRow(
                                    icon: "doc.text.fill",
                                    title: "Terms of Use",
                                    showChevron: true
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingPrivacy = true
                            }) {
                                SettingsRow(
                                    icon: "hand.raised.fill",
                                    title: "Privacy Policy",
                                    showChevron: true
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingEULA = true
                            }) {
                                SettingsRow(
                                    icon: "doc.plaintext.fill",
                                    title: "End User License Agreement",
                                    showChevron: true
                                )
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingSafetyDisclaimer = true
                            }) {
                                SettingsRow(
                                    icon: "exclamationmark.shield.fill",
                                    title: "Safety Disclaimer",
                                    showChevron: true
                                )
                            }
                        }
                    }
                    
                    // MARK: - Legacy Sections (kept for compatibility)
                    SectionCard(title: "Active Mode") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Current Mode")
                                    .foregroundColor(theme.primaryText)
                                Spacer()
                                Text(modeManager.activeMode.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundColor(theme.accentColor)
                            }
                            
                            Button(action: {
                                showingModeSelection = true
                            }) {
                                Text("Change Mode")
                                    .font(.subheadline.bold())
                                    .foregroundColor(theme.primaryButtonText)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(theme.primaryButton)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    
                    SectionCard(title: "Ride Goals") {
                        weeklyGoalEditor
                    }
                    
                    SectionCard(title: "iCloud Sync") {
                        cloudStatus
                    }
                    
                    SectionCard(title: "Apple Watch") {
                        watchStatus
                    }
                    
                    SectionCard(title: "Calendar & Export") {
                        Button(action: {
                            showingCalendarSettings = true
                        }) {
                            SettingsRow(
                                icon: "calendar",
                                title: "Ride Calendar",
                                showChevron: true
                            )
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 20)
            }
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        // MARK: - Sheets
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(profile: FirebaseProfileService.shared.currentProfile)
        }
        .sheet(isPresented: $showingSafetySettings) {
            SafetyControlView()
        }
        .sheet(isPresented: $showingVoiceSettings) {
            VoiceSettingsView()
        }
        .sheet(isPresented: $showingCalendarSettings) {
            CalendarSettingsView()
        }
        .sheet(isPresented: $showingModeSelection) {
            ModeSelectionView()
        }
        .sheet(isPresented: $showingHelpFAQ) {
            HelpFAQView()
        }
        .sheet(isPresented: $showingTerms) {
            LegalTextView(title: "Terms of Use", content: termsOfUseContent)
        }
        .sheet(isPresented: $showingPrivacy) {
            LegalTextView(title: "Privacy Policy", content: privacyPolicyContent)
        }
        .sheet(isPresented: $showingEULA) {
            LegalTextView(title: "End User License Agreement", content: eulaContent)
        }
        .sheet(isPresented: $showingSafetyDisclaimer) {
            LegalTextView(title: "Safety Disclaimer", content: safetyDisclaimerContent)
        }
        // MARK: - Alerts
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement account deletion
                print("Account deletion coming soon")
            }
        } message: {
            Text("Account deletion is coming soon. Please contact support@branchr.app for assistance.")
        }
        .alert("Clear Local Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                rideDataManager.clearLocalCache()
            }
        } message: {
            Text("This will delete all locally stored ride data. This action cannot be undone.")
        }
        .alert("Reset Preferences", isPresented: $showingResetPreferencesAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllPreferences()
            }
        } message: {
            Text("This will reset all app preferences to their default values. This action cannot be undone.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateAppearanceMode(_ mode: String) {
        switch mode {
        case "light":
            theme.setTheme(false) // Light mode
        case "dark":
            theme.setTheme(true) // Dark mode
        case "system":
            // Match system appearance
            let systemStyle = UITraitCollection.current.userInterfaceStyle
            theme.setTheme(systemStyle == .dark)
        default:
            break
        }
        print("🎨 SettingsView: Appearance mode set to: \(mode)")
    }
    
    private func openEmail(to: String, subject: String?) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        if let subject = subject {
            components.queryItems = [URLQueryItem(name: "subject", value: subject)]
        }
        
        if let url = components.url {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetAllPreferences() {
        // Reset all @AppStorage values to defaults
        autoPauseWhenStopped = false
        voiceSafetyAlerts = true
        rideReminders = true
        weeklySummary = true
        friendActivity = false
        voiceAnnouncements = true
        djModeEnabled = true
        allowVoiceChatWhileRiding = true
        appearanceMode = "system"
        
        // Reset user preferences
        userPreferences.weeklyDistanceGoalMiles = 75.0
        
        print("Branchr: All preferences reset to defaults")
    }
    
    // MARK: - Legacy Components (kept for compatibility)
    
    private var weeklyGoalEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Distance Goal")
                    .foregroundColor(theme.primaryText)
                Spacer()
                Text("\(String(format: "%.0f", userPreferences.weeklyDistanceGoalMiles)) mi")
                    .font(.subheadline.bold())
                    .foregroundColor(theme.accentColor)
            }
            
            Stepper(
                value: Binding(
                    get: { userPreferences.weeklyDistanceGoalMiles },
                    set: { newValue in
                        userPreferences.weeklyDistanceGoalMiles = newValue
                    }
                ),
                in: 5...200,
                step: 5
            ) {
                Text("Adjust goal")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            .tint(theme.accentColor)
        }
    }
    
    private var cloudStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            if cloudSync.isSyncing {
                HStack {
                    ProgressView()
                        .tint(theme.primaryButton)
                    Text("Syncing to iCloud...")
                        .foregroundColor(theme.primaryText)
                }
            } else if let lastSync = cloudSync.lastSync {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Last synced: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundColor(theme.primaryText)
                }
            } else {
                Text("iCloud sync not configured")
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    private var watchStatus: some View {
        HStack {
            Text("Apple Watch")
                .foregroundColor(theme.primaryText)
            Spacer()
            
            if watchService.isWatchConnected {
                Image(systemName: "applewatch")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "applewatch.slash")
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    // MARK: - Legal Content
    
    private let legalLastUpdated = "Last updated: December 3, 2025"
    private let appName = "Branchr"
    private let companyName = "Branchr Labs"
    private let legalEmail = "support@branchr.app"
    
    private var termsOfUseContent: String {
        """
        TERMS OF USE
        \(legalLastUpdated)
        
        Welcome to \(appName)! These Terms of Use ("Terms") are a legal agreement between you and \(companyName)
        ("we", "us", "our"). By downloading or using \(appName), you agree to these Terms. If you do not agree,
        please do not use the app.
        
        1. ELIGIBILITY
        You must be old enough to legally use mobile apps in your region (usually 13+). By using \(appName) you
        confirm that you meet this requirement.
        
        2. SAFE RIDING
        \(appName) is a companion tool for your rides, not a safety device.
        • You are fully responsible for your own safety.
        • Always obey all traffic laws and local regulations.
        • Do not interact with the screen while moving; stop in a safe place first.
        • Use audio at a level that still lets you hear traffic and people around you.
        • Do not rely on \(appName) in an emergency. Call your local emergency number instead.
        
        3. YOUR ACCOUNT
        You are responsible for keeping your device secure and for any activity that happens in your account.
        If you suspect unauthorized use, contact us at \(legalEmail).
        
        4. LICENSE
        We grant you a personal, limited, non-exclusive, non-transferable license to use \(appName) for your own
        non-commercial purposes. You may not:
        • Copy, modify, or redistribute the app.
        • Reverse engineer or attempt to extract the source code.
        • Use the app in any illegal, unsafe, or abusive way.
        
        5. PROHIBITED USES
        You agree not to:
        • Harass, threaten, or abuse other users.
        • Interfere with or damage servers, networks, or security.
        • Upload content that is unlawful, hateful, or infringes others' rights.
        
        6. RIDE DATA & ANALYTICS
        \(appName) may process ride information (distance, duration, location segments, speed, streaks) to show
        stats and improve your experience. Details are explained in our Privacy Policy.
        
        7. THIRD-PARTY SERVICES
        \(appName) may interact with services provided by Apple or other third parties (e.g., music, maps, cloud).
        Their terms and privacy policies apply to those services. We are not responsible for their actions.
        
        8. NO MEDICAL OR PROFESSIONAL ADVICE
        Any stats or suggestions in \(appName) are for general information only, not medical or professional advice.
        Talk to a healthcare professional before changing your exercise routine.
        
        9. TERMINATION
        We may suspend or terminate your access to \(appName) if we believe you are misusing the app or violating
        these Terms. You may stop using the app at any time by uninstalling it.
        
        10. DISCLAIMER OF WARRANTIES
        \(appName) is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, express or implied.
        We do not guarantee that:
        • The app will always be available or error-free.
        • Ride data or analytics will always be accurate.
        • Using the app will prevent accidents or injuries.
        
        11. LIMITATION OF LIABILITY
        To the fullest extent allowed by law, \(companyName) will not be liable for:
        • Any accidents, injuries, property damage, or loss of life.
        • Any indirect, incidental, special, or consequential damages.
        • Any loss of data, profits, or opportunities related to your use of \(appName).
        
        Your only remedy if you are unhappy with the app is to stop using it and uninstall it.
        
        12. CHANGES TO THESE TERMS
        We may update these Terms from time to time. When we do, we will update the "Last updated" date above.
        Continued use of \(appName) after changes means you accept the updated Terms.
        
        13. CONTACT
        For questions about these Terms, email \(legalEmail).
        """
    }
    
    private var privacyPolicyContent: String {
        """
        PRIVACY POLICY
        \(legalLastUpdated)
        
        This Privacy Policy explains how \(companyName) ("we", "us", "our") collects, uses, and protects information
        when you use \(appName).
        
        By using \(appName), you agree to this Privacy Policy.
        
        1. INFORMATION WE MAY COLLECT
        • Account info – name, email, profile photo, preferences you set.
        • Ride info – distance, duration, route segments, basic speed and streak data.
        • Device info – model, OS version, app version, language, general region.
        • Usage info – features you use, screens visited, and basic analytics.
        • Diagnostics – crash logs and performance data to improve stability.
        
        If you grant permissions, we may also process:
        • Location data while a ride is active (to track distance and route).
        • Motion/fitness data from your device or connected Apple Watch.
        
        2. HOW WE USE YOUR INFORMATION
        We use information to:
        • Provide core features like ride tracking, streaks, goals, and summaries.
        • Sync data to iCloud or other backup services when enabled.
        • Send notifications such as reminders and safety alerts.
        • Monitor performance and prevent abuse or fraud.
        • Communicate with you about updates, support, and important changes.
        
        3. LEGAL BASES (WHERE APPLICABLE)
        Depending on your region, we may rely on:
        • Your consent (e.g., location, notifications).
        • Our legitimate interest in operating and improving \(appName).
        • Compliance with legal obligations.
        
        4. SHARING OF INFORMATION
        We do **not** sell your personal data.
        We may share information:
        • With trusted service providers that help us run the app (hosting, analytics, crash reports).
        • When required by law or legal process.
        • To protect the safety, rights, or property of us, our users, or others.
        
        5. DATA RETENTION
        We keep your information only as long as necessary to provide the service, comply with law, resolve disputes,
        or enforce our agreements. You can request deletion of certain data by contacting us.
        
        6. YOUR CHOICES
        You can:
        • Turn off location and motion access in system settings (some features may stop working).
        • Change notification settings in iOS.
        • Request access, correction, or deletion of certain data where local law provides that right.
        
        7. SECURITY
        We use reasonable technical and organizational measures to protect your data. No system is 100% secure,
        but we work to prevent unauthorized access, loss, or misuse.
        
        8. CHILDREN
        \(appName) is not directed to children under 13. If we learn that we collected personal data from a child
        under 13 without proper consent, we will delete it where required by law.
        
        9. INTERNATIONAL TRANSFERS
        Data may be processed in countries other than your own. We take steps to handle your information in line
        with this Privacy Policy and applicable law.
        
        10. CHANGES TO THIS POLICY
        We may update this Privacy Policy. We will adjust the "Last updated" date when we do. Continued use of
        \(appName) after an update means you accept the new version.
        
        11. CONTACT
        For privacy questions or requests, email \(legalEmail).
        """
    }
    
    private var eulaContent: String {
        """
        END USER LICENSE AGREEMENT (EULA)
        \(legalLastUpdated)
        
        This End User License Agreement ("Agreement") is between you and \(companyName) and governs your use of
        the \(appName) mobile application.
        
        1. LICENSE GRANT
        We grant you a limited, non-exclusive, non-transferable, revocable license to download and use \(appName)
        on a device you own or control, solely for personal, non-commercial use.
        
        2. OWNERSHIP
        \(appName) is licensed, not sold. All rights, title, and interest in \(appName) and its content are owned
        by \(companyName) or its licensors.
        
        3. RESTRICTIONS
        You agree that you will not:
        • Copy or distribute the app except as allowed by the App Store.
        • Modify, reverse engineer, or attempt to derive source code, except where permitted by law.
        • Circumvent security or technical protection measures.
        • Use the app to create a competing service.
        
        4. THIRD-PARTY TERMS
        Your use of \(appName) must also comply with:
        • Apple's App Store Terms and Conditions.
        • Any terms of services integrated in the app (e.g., music or map providers).
        
        5. UPDATES
        We may provide updates, bug fixes, or new versions. This Agreement applies to all updates unless a
        different agreement is provided.
        
        6. DISCLAIMER; LIMITATION OF LIABILITY
        \(appName) is provided "AS IS" without warranty of any kind. To the maximum extent allowed by law, we are
        not liable for any indirect, incidental, special, or consequential damages, or for any accidents, injuries,
        or losses arising from your use of \(appName).
        
        7. TERMINATION
        We may suspend or terminate this license at any time if you breach this Agreement or misuse the app.
        You may terminate it by uninstalling \(appName) and stopping all use.
        
        8. GOVERNING LAW
        To the extent allowed by local law, this Agreement is governed by the laws applicable where \(companyName)
        is organized, without regard to conflict-of-law rules.
        
        9. CONTACT
        For questions about this Agreement, email \(legalEmail).
        """
    }
    
    private var safetyDisclaimerContent: String {
        """
        SAFETY DISCLAIMER
        \(legalLastUpdated)
        
        \(appName) is designed to enhance your riding experience, not to guarantee your safety. By using \(appName),
        you acknowledge and agree to the following:
        
        1. NO GUARANTEE OF SAFETY
        • The app may contain bugs, delays, or inaccuracies in ride data.
        • We do not guarantee that using \(appName) will prevent accidents, injuries, or other incidents.
        • You use the app entirely at your own risk.
        
        2. STAY FOCUSED ON THE ROAD
        • Do not look at your screen while moving; interact only when you are safely stopped.
        • Always obey traffic lights, signs, and local rules.
        • Watch for vehicles, pedestrians, and obstacles at all times.
        
        3. AUDIO, MUSIC, AND VOICE CHAT
        • Use headphones or speakers at a level that lets you remain aware of your surroundings.
        • Group voice chat and shared music are optional features. Do not let them distract you.
        
        4. EMERGENCIES
        • \(appName) does not automatically contact emergency services.
        • In any emergency, call your local emergency number immediately.
        
        5. HEALTH & FITNESS
        • \(appName) does not provide medical advice. Consult a doctor before changing your exercise routine,
          especially if you have health concerns.
        
        6. YOUR RESPONSIBILITY
        By riding with \(appName), you accept that:
        • You are responsible for how and when you use the app.
        • \(companyName) is not responsible for collisions, falls, injuries, or property damage connected to
          your riding or use of the app.
        
        If you do not agree with this Safety Disclaimer, do not use \(appName) while riding.
        """
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let title: String
    let showChevron: Bool
    var isDestructive: Bool = false
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : theme.accentColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(isDestructive ? .red : theme.primaryText)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
}

// MARK: - Settings Toggle Row Component

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.accentColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(theme.primaryText)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(theme.accentColor)
        }
    }
}

// MARK: - Help & FAQ View

struct HelpFAQView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Help & FAQ")
                        .font(.title.bold())
                        .foregroundColor(theme.primaryText)
                        .padding(.horizontal)
                    
                    Text("Frequently Asked Questions")
                        .font(.headline)
                        .foregroundColor(theme.primaryText)
                        .padding(.horizontal)
                    
                    // TODO: Add actual FAQ content
                    Text("FAQ content coming soon. For immediate assistance, please contact support@branchr.app")
                        .foregroundColor(theme.secondaryText)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle("Help & FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Legal Text View

struct LegalTextView: View {
    let title: String
    let content: String
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(content)
                        .font(.body)
                        .foregroundColor(theme.primaryText)
                        .padding()
                }
            }
            .background(theme.primaryBackground.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
