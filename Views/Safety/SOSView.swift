//
//  SOSView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-04
//  Phase 27 - Safety & SOS System UI
//

import SwiftUI
import MessageUI

/**
 * 🚨 SOS View
 *
 * Emergency SOS interface with:
 * - Pulsing red alert button
 * - Location sharing
 * - Emergency message sending
 * - Haptic feedback
 */
struct SOSView: View {
    @ObservedObject private var sosManager = SOSManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var showMessageComposer = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.primaryBackground.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Safety & SOS")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        
                        Text("Emergency assistance when you need it")
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // SOS Button with Pulsing Animation
                    ZStack {
                        // Pulsing ring animation
                        Circle()
                            .fill(Color.red.opacity(sosManager.sosActive ? 0.6 : 0.2))
                            .frame(width: 200, height: 200)
                            .scaleEffect(sosManager.sosActive ? 1.3 : 1.0)
                            .opacity(sosManager.sosActive ? 0.8 : 0.4)
                            .animation(
                                sosManager.sosActive
                                ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                                : .default,
                                value: sosManager.sosActive
                            )
                        
                        // Main SOS Button
                        Button(action: {
                            if sosManager.sosActive {
                                sosManager.deactivateSOS()
                            } else {
                                sosManager.triggerSOS()
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: sosManager.sosActive ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                                
                                Text(sosManager.sosActive ? "SOS Active" : "Activate SOS")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            .frame(width: 180, height: 180)
                            .background(sosManager.sosActive ? Color.red : Color.red.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .red.opacity(0.7), radius: 20, x: 0, y: 10)
                        }
                        .disabled(sosManager.sosActive && sosManager.lastSOSTimestamp != nil && Date().timeIntervalSince(sosManager.lastSOSTimestamp!) < 5)
                    }
                    .padding(.vertical, 20)
                    
                    // Status Text
                    if sosManager.sosActive {
                        VStack(spacing: 8) {
                            Text("🚨 SOS ACTIVE")
                                .font(.title2.bold())
                                .foregroundColor(.red)
                            
                            if let location = sosManager.currentLocation {
                                Text("Location: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))")
                                    .font(.caption)
                                    .foregroundColor(theme.primaryText.opacity(0.7))
                            } else {
                                Text("Getting location...")
                                    .font(.caption)
                                    .foregroundColor(theme.primaryText.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(theme.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Send Text Alert Button
                        Button(action: {
                            if MFMessageComposeViewController.canSendText() {
                                showMessageComposer = true
                            } else {
                                showShareSheet = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .font(.headline)
                                Text("Send Text Alert")
                                    .font(.headline.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Emergency Contacts
                        if !sosManager.emergencyContacts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Emergency Contacts")
                                    .font(.headline)
                                    .foregroundColor(theme.primaryText)
                                    .padding(.horizontal, 20)
                                
                                ForEach(sosManager.emergencyContacts, id: \.self) { contact in
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.red)
                                        Text(contact)
                                            .foregroundColor(theme.primaryText)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(theme.cardBackground)
                                    .cornerRadius(10)
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Emergency SOS")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                sosManager.locationManager.startUpdatingLocation()
            }
            .onDisappear {
                // Keep location updates if SOS is active
                if !sosManager.sosActive {
                    sosManager.locationManager.stopUpdatingLocation()
                }
            }
            .sheet(isPresented: $showMessageComposer) {
                MessageComposeView(
                    recipients: sosManager.emergencyContacts,
                    body: generateEmergencyMessage()
                )
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [generateEmergencyMessage()])
            }
            .onReceive(NotificationCenter.default.publisher(for: .emergencyMessageReady)) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    // Show share sheet with emergency message
                    showShareSheet = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateEmergencyMessage() -> String {
        guard let location = sosManager.currentLocation else {
            return "🚨 EMERGENCY ALERT 🚨\n\nI need help! Sent from Branchr Safety System"
        }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let locationURL = "https://maps.apple.com/?q=\(latitude),\(longitude)"
        
        return """
        🚨 EMERGENCY ALERT 🚨
        
        I need help! My current location:
        \(locationURL)
        
        Sent from Branchr Safety System
        """
    }
}

// MARK: - Message Compose View

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    SOSView()
        .preferredColorScheme(.dark)
}

