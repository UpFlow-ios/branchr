//
//  BranchrWidget.swift
//  BranchrWidgetExtension
//
//  Created by Joe Dormond on 2025-10-24.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct BranchrWidgetEntry: TimelineEntry {
    let date: Date
    let mode: BranchrMode
    let distance: Double
    let duration: TimeInterval
    let calories: Double
    let isActive: Bool
    let currentSong: String?
    let artist: String?
    let isMusicMuted: Bool
    let isVoiceMuted: Bool
    let isDarkMode: Bool
}

// MARK: - Timeline Provider
struct BranchrWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BranchrWidgetEntry {
        BranchrWidgetEntry(
            date: Date(),
            mode: .ride,
            distance: 2.4,
            duration: 800,
            calories: 120,
            isActive: true,
            currentSong: "Calvin Harris - Summer",
            artist: "Calvin Harris",
            isMusicMuted: false,
            isVoiceMuted: false,
            isDarkMode: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BranchrWidgetEntry) -> ()) {
        let entry = BranchrWidgetEntry(
            date: Date(),
            mode: .ride,
            distance: 2.4,
            duration: 800,
            calories: 120,
            isActive: true,
            currentSong: "Calvin Harris - Summer",
            artist: "Calvin Harris",
            isMusicMuted: false,
            isVoiceMuted: false,
            isDarkMode: true
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BranchrWidgetEntry>) -> ()) {
        // Get current data from App Groups with fallback
        let defaults = UserDefaults(suiteName: "group.com.joedormond.branchr")
        
        // Use fallback values if App Group is not available
        let modeString = defaults?.string(forKey: "branchrActiveMode") ?? "ride"
        let currentMode = BranchrMode(rawValue: modeString) ?? .ride
        
        // Get music and voice mute status
        let isMusicMuted = defaults?.bool(forKey: "isMusicMuted") ?? false
        let isVoiceMuted = defaults?.bool(forKey: "isVoiceMuted") ?? false
        
        // Get current song info (placeholder for now)
        let currentSong = defaults?.string(forKey: "currentSong") ?? "No Music Playing"
        let artist = defaults?.string(forKey: "currentArtist") ?? ""
        
        // Get theme preference
        let isDarkMode = defaults?.bool(forKey: "isDarkMode") ?? true
        
        // Create entry with current data
        let entry = BranchrWidgetEntry(
            date: Date(),
            mode: currentMode,
            distance: 2.4, // TODO: Get from ride data
            duration: 800, // TODO: Get from ride data
            calories: 120, // TODO: Get from ride data
            isActive: true,
            currentSong: currentSong,
            artist: artist,
            isMusicMuted: isMusicMuted,
            isVoiceMuted: isVoiceMuted,
            isDarkMode: isDarkMode
        )
        
        // Update every 5 minutes for more responsive widget
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct BranchrWidgetView: View {
    var entry: BranchrWidgetProvider.Entry
    
    // Theme colors based on dark/light mode
    private var backgroundColor: Color {
        entry.isDarkMode ? Color.black : Color.yellow
    }
    
    private var primaryTextColor: Color {
        entry.isDarkMode ? Color.white : Color.black
    }
    
    private var secondaryTextColor: Color {
        entry.isDarkMode ? Color.gray : Color.black.opacity(0.7)
    }
    
    private var accentColor: Color {
        entry.isDarkMode ? Color.yellow : Color.black
    }
    
    private var cardBackgroundColor: Color {
        entry.isDarkMode ? Color.gray.opacity(0.2) : Color.black.opacity(0.1)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with logo, branchr text, mode, and status
            HStack {
                // Logo and branchr text
                HStack(spacing: 8) {
                    // Bicycle warning sign logo
                    ZStack {
                        // Yellow diamond background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.yellow)
                            .frame(width: 28, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        
                        // Bicycle icon
                        Image(systemName: "bicycle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    // branchr logo text
                    Text("branchr")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(accentColor)
                        .tracking(1.0)
                }
                
                Spacer()
                
                // Mode in the middle
                Text(entry.mode.displayName.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(primaryTextColor)
                    .tracking(1.0)
                
                Spacer()
                
                // Active status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.isActive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(entry.isActive ? "ACTIVE" : "INACTIVE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(entry.isActive ? .green : .gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            
            // Music section - Compact
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                    
                    Text("NOW PLAYING")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(secondaryTextColor)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    // Music mute indicator
                    Image(systemName: entry.isMusicMuted ? "speaker.slash.fill" : "speaker.fill")
                        .font(.system(size: 12))
                        .foregroundColor(entry.isMusicMuted ? Color.red : accentColor)
                }
                
                // Song info
                HStack {
                    Text(entry.currentSong ?? "No Music Playing")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                if let artist = entry.artist, !artist.isEmpty {
                    HStack {
                        Text(artist)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(cardBackgroundColor)
            .cornerRadius(8)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            
            // Stats section - Properly sized for widget
            HStack(spacing: 12) {
                // Distance
                VStack(spacing: 3) {
                    Text(String(format: "%.1f", entry.distance))
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(accentColor)
                    
                    Text("MILES")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(secondaryTextColor)
                        .tracking(1.0)
                }
                
                Divider()
                    .frame(height: 28)
                    .background(secondaryTextColor)
                
                // Duration
                VStack(spacing: 3) {
                    Text(String(format: "%d", Int(entry.duration / 60)))
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(accentColor)
                    
                    Text("MINUTES")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(secondaryTextColor)
                        .tracking(1.0)
                }
                
                Divider()
                    .frame(height: 28)
                    .background(secondaryTextColor)
                
                // Calories
                VStack(spacing: 3) {
                    Text(String(format: "%.0f", entry.calories))
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(accentColor)
                    
                    Text("CALORIES")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(secondaryTextColor)
                        .tracking(1.0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            Spacer()
        }
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }
}

// MARK: - Widget Configuration
struct BranchrWidget: Widget {
    let kind: String = "BranchrWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BranchrWidgetProvider()) { entry in
            BranchrWidgetView(entry: entry)
        }
        .configurationDisplayName("Branchr Control")
        .description("Shows your current mode, music, stats, and mute controls.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
struct BranchrWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small widget - Dark mode
            BranchrWidgetView(
                entry: BranchrWidgetEntry(
                    date: Date(),
                    mode: .ride,
                    distance: 2.4,
                    duration: 600,
                    calories: 120,
                    isActive: true,
                    currentSong: "Calvin Harris - Summer",
                    artist: "Calvin Harris",
                    isMusicMuted: false,
                    isVoiceMuted: false,
                    isDarkMode: true
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small - Dark Mode with Logo")
            
            // Medium widget - Light mode
            BranchrWidgetView(
                entry: BranchrWidgetEntry(
                    date: Date(),
                    mode: .camp,
                    distance: 5.2,
                    duration: 1200,
                    calories: 280,
                    isActive: false,
                    currentSong: "The Weeknd - Blinding Lights",
                    artist: "The Weeknd",
                    isMusicMuted: true,
                    isVoiceMuted: true,
                    isDarkMode: false
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium - Light Mode with Logo")
            
            // Large widget - Study mode
            BranchrWidgetView(
                entry: BranchrWidgetEntry(
                    date: Date(),
                    mode: .study,
                    distance: 0.0,
                    duration: 1800,
                    calories: 45,
                    isActive: true,
                    currentSong: "Lofi Hip Hop - Chill Beats",
                    artist: "Study Music",
                    isMusicMuted: false,
                    isVoiceMuted: false,
                    isDarkMode: true
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large - Study Mode with Logo")
        }
    }
}
