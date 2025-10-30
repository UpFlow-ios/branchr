//
//  RideHUDView.swift
//  branchr
//
//  Created by Joe Dormond on 10/21/25.
//

import SwiftUI

struct RideHUDView: View {
    
    // MARK: - State Objects
    @StateObject private var hudManager = HUDManager()
    
    // MARK: - State Variables
    @State private var animationOffset: CGFloat = 0
    @State private var volumeAnimationScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Main HUD Content
            VStack(spacing: 16) {
                
                // MARK: - Mode Pill
                modePill
                
                // MARK: - Volume Meters
                volumeMeters
                
                // MARK: - Status Row
                statusRow
                
                // MARK: - Toast Message
                if hudManager.showToast {
                    toastMessage
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .scaleEffect(volumeAnimationScale)
            .offset(y: animationOffset)
        }
        .onAppear {
            setupHUD()
        }
        .onChange(of: hudManager.musicVolume) { _ in
            animateVolumeChange()
        }
        .onChange(of: hudManager.voiceVolume) { _ in
            animateVolumeChange()
        }
        .onChange(of: hudManager.currentMode) { _ in
            animateModeChange()
        }
    }
    
    // MARK: - Mode Pill
    private var modePill: some View {
        HStack(spacing: 8) {
            Image(systemName: hudManager.currentMode.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(modeColor)
            
            Text(hudManager.currentMode.displayName.uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(modeColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(modeColor.opacity(0.2), in: Capsule())
        .overlay(
            Capsule()
                .stroke(modeColor.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - Volume Meters
    private var volumeMeters: some View {
        VStack(spacing: 12) {
            // Music Volume Meter
            HStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.purple)
                    .frame(width: 20)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        // Volume fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.purple)
                            .frame(width: geometry.size.width * CGFloat(hudManager.musicVolume), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: hudManager.musicVolume)
                    }
                }
                .frame(height: 8)
                
                Text("\(Int(hudManager.musicVolume * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 35, alignment: .trailing)
            }
            
            // Voice Volume Meter
            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                    .frame(width: 20)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        // Volume fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.green)
                            .frame(width: geometry.size.width * CGFloat(hudManager.voiceVolume), height: 8)
                            .animation(.easeInOut(duration: 0.3), value: hudManager.voiceVolume)
                    }
                }
                .frame(height: 8)
                
                Text("\(Int(hudManager.voiceVolume * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 35, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Status Row
    private var statusRow: some View {
        HStack(spacing: 16) {
            // Peer Count
            HStack(spacing: 6) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                
                Text("\(hudManager.peerCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Connection Status
            HStack(spacing: 6) {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 8, height: 8)
                
                Text(hudManager.connectionStatus)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Toast Message
    private var toastMessage: some View {
        Text(hudManager.lastAction)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: hudManager.showToast)
    }
    
    // MARK: - Computed Properties
    
    private var modeColor: Color {
        switch hudManager.currentMode {
        case .voiceOnly:
            return .green
        case .musicOnly:
            return .purple
        case .both:
            return .blue
        }
    }
    
    private var connectionStatusColor: Color {
        switch hudManager.connectionStatus {
        case "Connected":
            return .green
        case "Disconnected":
            return .red
        default:
            return .orange
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupHUD() {
        // Initial setup
        animationOffset = 0
        volumeAnimationScale = 1.0
    }
    
    private func animateVolumeChange() {
        withAnimation(.easeInOut(duration: 0.2)) {
            volumeAnimationScale = 1.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                volumeAnimationScale = 1.0
            }
        }
    }
    
    private func animateModeChange() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationOffset = -10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.3)) {
                animationOffset = 0
            }
        }
    }
}

// MARK: - Audio Mode Extension
extension AudioMixerService.AudioMode {
    var icon: String {
        switch self {
        case .voiceOnly: return "mic.fill"
        case .musicOnly: return "music.note"
        case .both: return "speaker.2.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        RideHUDView()
    }
    .preferredColorScheme(.dark)
}
