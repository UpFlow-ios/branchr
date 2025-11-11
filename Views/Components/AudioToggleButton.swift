//
//  AudioToggleButton.swift
//  branchr
//
//  Created for Phase 35.2 - Reusable Audio Toggle Component
//

import SwiftUI

/**
 * 🎵 Audio Toggle Button
 *
 * Reusable component for audio mute/unmute controls.
 * Used in host controls for music and voice toggles.
 */
struct AudioToggleButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.subheadline)
            }
            .foregroundColor(isActive ? .white : theme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.red : theme.cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}

/**
 * 🎵 Music Toggle Button
 *
 * Specialized button for music mute/unmute.
 */
struct MusicToggleButton: View {
    let isMuted: Bool
    let action: () -> Void
    
    var body: some View {
        AudioToggleButton(
            icon: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
            label: isMuted ? "Resume Music" : "Pause Music",
            isActive: isMuted,
            action: action
        )
    }
}

/**
 * 🎙 Voice Toggle Button
 *
 * Specialized button for voice mute/unmute.
 */
struct VoiceToggleButton: View {
    let isMuted: Bool
    let action: () -> Void
    
    var body: some View {
        AudioToggleButton(
            icon: isMuted ? "mic.slash.fill" : "mic.fill",
            label: isMuted ? "Unmute Voices" : "Mute Voices",
            isActive: isMuted,
            action: action
        )
    }
}

